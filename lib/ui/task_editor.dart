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
  late TextEditingController _descriptionController;
  late GtdStatus _currentStatus;
  
  DateTime? _dueDate;
  late RecurrenceType _recurrence;
  late List<Duration> _reminderOffsets;
  late Set<int> _weeklyRecurrenceDays;

  late List<String> _tags;
  final TextEditingController _tagInputController = TextEditingController();
  List<String> _allAvailableTags = [];
  quill.QuillController? _quillController;
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description);
    _currentStatus = widget.item.status;
    
    _dueDate = widget.item.dueDate;
    _recurrence = widget.item.recurrence;
    _reminderOffsets = List.from(widget.item.reminderOffsets);
    _weeklyRecurrenceDays = Set.from(widget.item.weeklyRecurrenceDays);
    _tags = List.from(widget.item.tags);

    if (_currentStatus == GtdStatus.reference) {
      final service = context.read<GtdService>();
      _allAvailableTags = service.allTags.toList();
      _initializeQuillController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagInputController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  void _initializeQuillController() {
    try {
      if (widget.item.description != null && widget.item.description!.isNotEmpty) {
        final doc = quill.Document.fromJson(jsonDecode(widget.item.description!));
        _quillController = quill.QuillController(
          document: doc,
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _quillController = quill.QuillController.basic();
      }
    } catch (e) {
      _quillController = quill.QuillController.basic();
      _quillController!.document.insert(0, widget.item.description ?? '');
    }
  }

  void _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<GtdService>();

    String? description;
    if (_currentStatus == GtdStatus.reference && _quillController != null) {
      description = jsonEncode(_quillController!.document.toDelta().toJson());
    } else {
      description = _descriptionController.text;
    }

    final updatedItem = widget.item.copyWith(
      title: _titleController.text,
      description: description,
      status: _currentStatus,
      dueDate: _dueDate,
      lastUpdatedAt: DateTime.now(), 
      recurrence: _recurrence,
      reminderOffsets: _reminderOffsets,
      weeklyRecurrenceDays: _weeklyRecurrenceDays,
      tags: _tags,
    );
    
    try {
      await service.updateItem(updatedItem);
      navigator.pop();
    } catch (e) {
      debugPrint("Erro ao salvar o item: $e");
      messenger.showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro ao salvar a nota.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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

  Widget _buildTagEditorForAppBar() {
    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _allAvailableTags.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        // This is handled by onSubmitted or the comma key press
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
                  child: Chip(
                    label: Text(tag),
                    onDeleted: () {
                      setState(() {
                        _tags.remove(tag);
                      });
                    },
                  ),
                )),
                SizedBox(
                  width: 150,
                  child: RawKeyboardListener(
                    focusNode: FocusNode(),
                    onKey: (event) {
                      if (event is RawKeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.comma) {
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
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 4)
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
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isReference = _currentStatus == GtdStatus.reference;
    // Pega a cor padrão do texto do tema atual.
    final defaultTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(
        title: isReference ? _buildTagEditorForAppBar() : const Text('Editar Item'),
        titleSpacing: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.delete_outline), onPressed: _deleteItem),
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isReference && _quillController != null) ...[
            quill.QuillSimpleToolbar(
              controller: _quillController!,
              config: quill.QuillSimpleToolbarConfig(
                multiRowsDisplay: false,
                embedButtons: FlutterQuillEmbeds.toolbarButtons(),
                buttonOptions: const quill.QuillSimpleToolbarButtonOptions(
                  fontFamily: quill.QuillToolbarFontFamilyButtonOptions(
                    items: {
                      'Inter': 'Inter',
                      'Serif': 'Serif',
                      'Verdana': 'Verdana',
                    },
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
                      decoration: const InputDecoration(
                        hintText: 'Título',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  
                  if (isReference && _quillController != null)
                    Expanded(
                      child: quill.QuillEditor.basic(
                        controller: _quillController!,
                        config: quill.QuillEditorConfig(
                          padding: const EdgeInsets.all(8),
                          embedBuilders: FlutterQuillEmbeds.editorBuilders(),
                          // CORRIGIDO: Define a cor do texto com base no tema.
                          customStyles: quill.DefaultStyles(
                            paragraph: quill.DefaultTextBlockStyle(
                              TextStyle(
                                fontSize: 16,
                                fontFamily: 'Inter',
                                color: defaultTextColor, // Usa a cor do tema
                              ),
                              const quill.HorizontalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              const quill.VerticalSpacing(0, 0),
                              null,
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: null,
                          keyboardType: TextInputType.multiline,
                          decoration: const InputDecoration(
                            hintText: 'Descrição / Notas',
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

