import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';

class TaskEditorScreen extends StatefulWidget {
  final GtdItem item;

  const TaskEditorScreen({super.key, required this.item});

  @override
  State<TaskEditorScreen> createState() => _TaskEditorScreenState();
}

class _TaskEditorScreenState extends State<TaskEditorScreen> {
  late TextEditingController _titleController;
  late GtdStatus _currentStatus;
  
  late List<String> _tags;
  final TextEditingController _tagInputController = TextEditingController();
  List<String> _allAvailableTags = [];
  quill.QuillController? _quillController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _currentStatus = widget.item.status;
    _tags = List.from(widget.item.tags);

    if (_isQuillBasedStatus(_currentStatus)) {
       _initializeQuillController();
    }
    
    final service = context.read<GtdService>();
    _allAvailableTags = service.allTags.toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _tagInputController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  bool _isQuillBasedStatus(GtdStatus status) {
    return [
      GtdStatus.reference,
      GtdStatus.waitingFor,
      GtdStatus.somedayMaybe,
      GtdStatus.nextAction,
      GtdStatus.calendar,
      GtdStatus.projectTask,
    ].contains(status);
  }

  // CORRIGIDO: Lógica de inicialização do Quill Controller ajustada
  void _initializeQuillController() {
    if (_quillController != null) return;

    try {
      // Tenta decodificar o JSON. Se for bem-sucedido, cria o editor com o conteúdo formatado.
      if (widget.item.description != null && widget.item.description!.isNotEmpty) {
        final doc = quill.Document.fromJson(jsonDecode(widget.item.description!));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        // Se a descrição estiver vazia, cria um editor em branco.
        _quillController = quill.QuillController.basic();
      }
    } catch (e) {
      // Se a decodificação falhar (ex: é um texto antigo sem formatação), 
      // cria um editor e insere o conteúdo como texto plano.
      _quillController = quill.QuillController.basic();
      if (widget.item.description != null && widget.item.description!.isNotEmpty) {
        _quillController!.document.insert(0, widget.item.description);
      }
    }
  }

  void _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final navigator = Navigator.of(context);
    final service = context.read<GtdService>();

    final description = (_quillController != null && _isQuillBasedStatus(_currentStatus))
        ? jsonEncode(_quillController!.document.toDelta().toJson())
        : widget.item.description;

    final updatedItem = widget.item.copyWith(
      title: _titleController.text,
      description: description,
      status: _currentStatus,
      lastUpdatedAt: DateTime.now(),
      tags: _tags,
    );
    
    await service.updateItem(updatedItem);
    
    if (mounted) {
       navigator.pop();
    }
  }

  void _deleteItem() async {
    final navigator = Navigator.of(context);
    final service = context.read<GtdService>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Você tem certeza que deseja excluir este item?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir')),
        ],
      )
    );

    if(confirm ?? false) {
       await service.deleteItem(widget.item.id);
       if (mounted) navigator.pop();
    }
  }

  void _addTag(String tag) {
    final trimmedTag = tag.trim().replaceAll(',', '');
    if (trimmedTag.isNotEmpty && !_tags.contains(trimmedTag)) {
      setState(() {
        _tags.add(trimmedTag);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = Theme.of(context).textTheme.bodyMedium?.color;
    final isQuillActive = _quillController != null && _isQuillBasedStatus(_currentStatus);

    return Scaffold(
      appBar: AppBar(
        title: Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
            return _allAvailableTags.where((o) => o.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (String selection) {
            _addTag(selection);
            _tagInputController.clear();
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return SizedBox(
              height: 40,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ..._tags.map((tag) => Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Chip(label: Text(tag), onDeleted: () => setState(() => _tags.remove(tag))),
                    )),
                    SizedBox(
                      width: 150,
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (event) {
                          if (event is RawKeyDownEvent && event.logicalKey == LogicalKeyboardKey.comma) {
                            _addTag(controller.text);
                            controller.clear();
                          }
                        },
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            hintText: 'Adicionar tag...',
                            border: InputBorder.none,
                            isCollapsed: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          ),
                          onSubmitted: (value) {
                            _addTag(value);
                            controller.clear();
                            onFieldSubmitted();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        titleSpacing: 0,
        actions: [
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteItem),
          _isSaving
              ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isQuillActive) ...[
            quill.QuillSimpleToolbar(
              controller: _quillController!,
              config: quill.QuillSimpleToolbarConfig(
                multiRowsDisplay: false,
                embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                buttonOptions: const quill.QuillSimpleToolbarButtonOptions(
                  fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
                    items: {'Inter': 'Inter', 'Serif': 'Serif', 'Verdana': 'Verdana'},
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: TextField(
                      controller: _titleController,
                      style: Theme.of(context).textTheme.headlineSmall,
                      decoration: const InputDecoration(hintText: 'Título', border: InputBorder.none),
                    ),
                  ),
                  
                  if (isQuillActive)
                    Expanded(
                      child: quill.QuillEditor.basic(
                        controller: _quillController!,
                        config: quill.QuillEditorConfig(
                          padding: const EdgeInsets.all(8),
                          embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                          customStyles: quill.DefaultStyles(
                            paragraph: quill.DefaultTextBlockStyle(
                              TextStyle(fontSize: 16, fontFamily: 'Inter', color: defaultTextColor),
                              const quill.HorizontalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
