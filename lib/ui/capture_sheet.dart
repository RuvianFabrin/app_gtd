import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';

class CaptureSheet extends StatefulWidget {
  final GtdStatus preselectedStatus;

  const CaptureSheet({super.key, required this.preselectedStatus});

  static void show(BuildContext context, {required GtdStatus preselectedStatus}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CaptureSheet(preselectedStatus: preselectedStatus),
      ),
    );
  }

  @override
  State<CaptureSheet> createState() => _CaptureSheetState();
}

class _CaptureSheetState extends State<CaptureSheet> {
  final _titleController = TextEditingController();
  late GtdStatus _status;
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    _status = widget.preselectedStatus;
  }

  void _submit() async {
    if (_titleController.text.trim().isEmpty) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final service = context.read<GtdService>();

    if (_status == GtdStatus.calendar && _dueDate == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Por favor, defina uma data para itens do calendário.')),
      );
      return;
    }

    // ATUALIZADO: Usando o construtor correto que já define o status.
    final newItem = GtdItem.newItem(
      title: _titleController.text.trim(),
      status: _status,
    ).copyWith(
      dueDate: _dueDate
    );
    
    try {
      await service.addItem(newItem);
    } catch (e) {
      debugPrint("Erro ao adicionar item: $e");
      messenger.showSnackBar(
        const SnackBar(content: Text('Ocorreu um erro ao guardar o item.')),
      );
    } finally {
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Capturar em "${_getStatusLabel(_status)}"',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'O que está na sua mente?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            
            if (_status == GtdStatus.calendar) ...[
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
            ],

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('Guardar Item'),
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
      case GtdStatus.somedayMaybe: return 'Algum dia';
      case GtdStatus.reference: return 'Referência';
      default: return '';
    }
  }
}

