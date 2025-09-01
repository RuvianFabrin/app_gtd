import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';

class CalendarSettingsDialog extends StatefulWidget {
  final GtdItem item;

  const CalendarSettingsDialog({super.key, required this.item});

  static Future<GtdItem?> show(BuildContext context, GtdItem item) {
    return showDialog<GtdItem>(
      context: context,
      builder: (context) => CalendarSettingsDialog(item: item),
    );
  }

  @override
  State<CalendarSettingsDialog> createState() => _CalendarSettingsDialogState();
}

class _CalendarSettingsDialogState extends State<CalendarSettingsDialog> {
  late DateTime? _dueDate;
  late RecurrenceType _recurrence;
  late List<Duration> _reminderOffsets;
  late Set<int> _weeklyRecurrenceDays;

  @override
  void initState() {
    super.initState();
    _dueDate = widget.item.dueDate;
    _recurrence = widget.item.recurrence;
    _reminderOffsets = List.from(widget.item.reminderOffsets);
    _weeklyRecurrenceDays = Set.from(widget.item.weeklyRecurrenceDays);
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
            pickedDate.year, pickedDate.month, pickedDate.day,
            pickedTime.hour, pickedTime.minute,
          );
        });
      }
    }
  }

  // NOVO: Função para adicionar um lembrete
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
                      return DropdownMenuItem<String>(value: value, child: Text(value));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() => unit = newValue!);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
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
      setState(() => _reminderOffsets.add(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Calendário'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_dueDate == null ? 'Definir data e hora' : DateFormat('dd/MM/yyyy HH:mm').format(_dueDate!)),
              onTap: _selectDate,
              trailing: _dueDate != null ? IconButton(icon: const Icon(Icons.clear), onPressed: () => setState(() => _dueDate = null),) : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<RecurrenceType>(
              value: _recurrence,
              decoration: const InputDecoration(labelText: 'Repetir'),
              items: RecurrenceType.values.map((type) => DropdownMenuItem(value: type, child: Text(_getRecurrenceLabel(type)))).toList(),
              onChanged: (v) => setState(() => _recurrence = v!)),
            if (_recurrence == RecurrenceType.weekly) ...[
              const SizedBox(height: 16),
              _buildWeekDaySelector(),
            ],
            // NOVO: Seção de Lembretes
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
        TextButton(
          onPressed: () {
            final updatedItem = widget.item.copyWith(
              dueDate: _dueDate,
              recurrence: _recurrence,
              weeklyRecurrenceDays: _weeklyRecurrenceDays,
              reminderOffsets: _reminderOffsets,
              setDueDateToNull: _dueDate == null,
            );
            Navigator.of(context).pop(updatedItem);
          },
          child: const Text('Salvar'),
        ),
      ],
    );
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
      children: List.generate(7, (index) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12.0), child: Text(days[index]))),
    );
  }
  
  String _formatDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d antes';
    if (d.inHours > 0) return '${d.inHours}h antes';
    return '${d.inMinutes}m antes';
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
}

