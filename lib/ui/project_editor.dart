import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';

class ProjectEditorScreen extends StatefulWidget {
  final Project project;

  const ProjectEditorScreen({super.key, required this.project});

  @override
  State<ProjectEditorScreen> createState() => _ProjectEditorScreenState();
}

class _ProjectEditorScreenState extends State<ProjectEditorScreen> {
  late TextEditingController _nameController;
  quill.QuillController? _quillController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _initializeQuillController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quillController?.dispose();
    super.dispose();
  }

  // CORRIGIDO: Lógica de inicialização do Quill Controller ajustada
  void _initializeQuillController() {
    try {
      if (widget.project.description != null && widget.project.description!.isNotEmpty) {
        final doc = quill.Document.fromJson(jsonDecode(widget.project.description!));
        _quillController = quill.QuillController(document: doc, selection: const TextSelection.collapsed(offset: 0));
      } else {
        _quillController = quill.QuillController.basic();
      }
    } catch (e) {
      _quillController = quill.QuillController.basic();
      _quillController!.document.insert(0, widget.project.description ?? '');
    }
  }

  void _saveChanges() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final navigator = Navigator.of(context);
    final service = context.read<GtdService>();
    final messenger = ScaffoldMessenger.of(context);

    final description = jsonEncode(_quillController!.document.toDelta().toJson());
    final updatedProject = widget.project.copyWith(
      name: _nameController.text,
      description: description,
      lastUpdatedAt: DateTime.now(), // Atualiza a data de modificação
    );
    
    try {
      await service.updateProject(updatedProject);
      navigator.pop();
    } catch (e) {
      debugPrint("Erro ao salvar o projeto: $e");
      messenger.showSnackBar(const SnackBar(content: Text('Ocorreu um erro ao salvar o projeto.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultTextColor = Theme.of(context).textTheme.bodyMedium?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Projeto'),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(12.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
              : IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: Column(
        children: [
          if (_quillController != null)
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                    child: TextField(
                      controller: _nameController,
                      style: Theme.of(context).textTheme.headlineSmall,
                      decoration: const InputDecoration(hintText: 'Nome do Projeto', border: InputBorder.none),
                    ),
                  ),
                  if (_quillController != null)
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
