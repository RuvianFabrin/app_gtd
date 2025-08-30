import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
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

  quill.QuillController? _quillController;
  final FocusNode _editorFocusNode = FocusNode();
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

    if (_currentStatus == GtdStatus.reference) {
      _initializeQuillController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quillController?.dispose();
    _editorFocusNode.dispose();
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

    // MODIFICADO: Captura o Navigator e o Messenger antes do 'await'
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<GtdService>();

    String? description;
    if (_currentStatus == GtdStatus.reference && _quillController != null) {
      description = jsonEncode(_quillController!.document.toDelta().toJson());
    } else {
      description = _descriptionController.text;
    }

    final updatedItem = GtdItem(
      id: widget.item.id,
      title: _titleController.text,
      description: description,
      status: _currentStatus,
      dueDate: _dueDate,
      createdAt: widget.item.createdAt,
      project: widget.item.project,
      recurrence: _recurrence,
      reminderOffsets: _reminderOffsets,
      weeklyRecurrenceDays: _weeklyRecurrenceDays,
    );
    
    try {
      await service.updateItem(updatedItem);
    } catch (e) {
      debugPrint("Erro ao guardar o item: $e");
      messenger.showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro ao guardar a nota.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
      navigator.pop();
    }
  }

  void _deleteItem() async {
    // MODIFICADO: Captura o Navigator antes do 'await'
    final navigator = Navigator.of(context);
    final service = context.read<GtdService>();

    await service.deleteItem(widget.item.id);
    if (mounted) navigator.pop();
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
      );
      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Widget _buildWeekDaySelector() {
    final days = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];
    return ToggleButtons(
      isSelected: List.generate(7, (index) => _weeklyRecurrenceDays.contains(index + 1)),
      onPressed: (int index) {
        setState(() {
          final day = index + 1;
          if (_weeklyRecurrenceDays.contains(day)) {
            _weeklyRecurrenceDays.remove(day);
          } else {
            _weeklyRecurrenceDays.add(day);
          }
        });
      },
      borderRadius: BorderRadius.circular(8.0),
      children: List.generate(7, (index) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Text(days[index]),
      )),
    );
  }

  Future<void> _addReminder() async {
    final TextEditingController valueController = TextEditingController();
    String unit = 'minutos';

    final result = await showDialog<Duration>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Novo Lembrete'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: valueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Valor'),
                  ),
                  DropdownButton<String>(
                    value: unit,
                    items: ['minutos', 'horas', 'dias'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        unit = newValue!;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    final int? value = int.tryParse(valueController.text);
                    if (value == null || value <= 0) return;

                    Duration duration;
                    if (unit == 'minutos') {
                      duration = Duration(minutes: value);
                    } else if (unit == 'horas') {
                      duration = Duration(hours: value);
                    } else {
                      duration = Duration(days: value);
                    }
                    Navigator.of(context).pop(duration);
                  },
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _reminderOffsets.add(result);
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Processar Item'),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              style: Theme.of(context).textTheme.titleLarge,
              decoration: const InputDecoration(
                labelText: 'Título',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            if (_currentStatus == GtdStatus.reference && _quillController != null)
              Expanded(
                child: Column(
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _quillController!,
                      config: const quill.QuillSimpleToolbarConfig(
                        multiRowsDisplay: false,
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: quill.QuillEditor.basic(
                        controller: _quillController!,
                        config: const quill.QuillEditorConfig(
                          padding: EdgeInsets.all(8),
                        ),
                      ),
                    )
                  ],
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Descrição / Notas',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text('Organizar', style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      DropdownButtonFormField<GtdStatus>(
                        value: _currentStatus,
                        decoration: const InputDecoration(labelText: 'Mover para'),
                        items: GtdStatus.values
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(_getStatusLabel(status)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v == GtdStatus.reference && _quillController == null) {
                            _initializeQuillController();
                          }
                          setState(() => _currentStatus = v!);
                        }),
                      
                      if (_currentStatus == GtdStatus.calendar) ...[
                        const SizedBox(height: 16),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                            _dueDate == null
                                ? 'Definir data e hora'
                                : DateFormat('dd/MM/yyyy HH:mm').format(_dueDate!),
                          ),
                          onTap: _selectDate,
                          trailing: _dueDate != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null),) : null,
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<RecurrenceType>(
                          value: _recurrence,
                          decoration: const InputDecoration(labelText: 'Repetir'),
                          items: RecurrenceType.values.map((type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(_getRecurrenceLabel(type)),
                                  )).toList(),
                          onChanged: (v) => setState(() => _recurrence = v!)),
                        if (_recurrence == RecurrenceType.weekly) ...[
                          const SizedBox(height: 16),
                          _buildWeekDaySelector(),
                        ],
                        const SizedBox(height: 24),
                        Text('Lembretes Antecipados', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _reminderOffsets.map((offset) => Chip(
                            label: Text(_formatDuration(offset)),
                            onDeleted: () => setState(() => _reminderOffsets.remove(offset)),
                          )).toList(),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.add_alert),
                          label: const Text('Adicionar Lembrete'),
                          onPressed: _addReminder,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(GtdStatus status) {
    switch (status) {
      case GtdStatus.inbox: return 'Caixa de Entrada';
      case GtdStatus.nextAction: return 'Próximas Ações';
      case GtdStatus.calendar: return 'Calendário';
      case GtdStatus.waitingFor: return 'Aguardando';
      case GtdStatus.somedayMaybe: return 'Algum dia / Talvez';
      case GtdStatus.projectTask: return 'Tarefa de Projeto';
      case GtdStatus.reference: return 'Referência';
      case GtdStatus.done: return 'Concluído';
    }
  }

  String _getRecurrenceLabel(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.none: return 'Não repetir';
      case RecurrenceType.daily: return 'Diariamente';
      case RecurrenceType.weekly: return 'Semanalmente';
      case RecurrenceType.monthly: return 'Mensal';
      case RecurrenceType.yearly: return 'Anual';
    }
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d antes';
    if (d.inHours > 0) return '${d.inHours}h antes';
    return '${d.inMinutes}m antes';
  }
}
