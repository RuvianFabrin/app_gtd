import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';

void startClarifyFlow(BuildContext context, GtdItem item) {
  _showQuestion1(context, item);
}

void _showQuestion1(BuildContext context, GtdItem item) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(item.title, style: const TextStyle(fontSize: 18)),
      content: const Text('Isto exige alguma ação?'),
      actions: [
        TextButton(
          child: const Text('Não'),
          onPressed: () {
            Navigator.pop(context);
            _showNonActionableOptions(context, item);
          },
        ),
        TextButton(
          child: const Text('Sim'),
          onPressed: () {
            Navigator.pop(context);
            _showQuestion2(context, item);
          },
        ),
      ],
    ),
  );
}

void _showNonActionableOptions(BuildContext context, GtdItem item) {
  final service = context.read<GtdService>();
  final navigator = Navigator.of(context);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('O que fazer com isto?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton(
            child: const Text('Apagar (Lixo)'),
            onPressed: () {
              service.deleteItem(item.id);
              navigator.pop();
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            child: const Text("Guardar em 'Algum dia'"),
            onPressed: () {
              // ATUALIZADO: Usando copyWith para imutabilidade
              final updatedItem = item.copyWith(status: GtdStatus.somedayMaybe);
              service.updateItem(updatedItem);
              navigator.pop();
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            child: const Text("Arquivar como 'Referência'"),
            onPressed: () {
              // ATUALIZADO: Usando copyWith para imutabilidade
              final updatedItem = item.copyWith(status: GtdStatus.reference);
              service.updateItem(updatedItem);
              navigator.pop();
            },
          ),
        ],
      ),
    ),
  );
}

void _showQuestion2(BuildContext context, GtdItem item) {
  final service = context.read<GtdService>();
  final navigator = Navigator.of(context);
  final messenger = ScaffoldMessenger.of(context);

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('É uma ação única ou um projeto?'),
      content: const Text('Um projeto requer vários passos para ser concluído.'),
      actions: [
        TextButton(
          child: const Text('Ação Única'),
          onPressed: () {
            // ATUALIZADO: Usando copyWith para imutabilidade
            final updatedItem = item.copyWith(status: GtdStatus.nextAction);
            service.updateItem(updatedItem);
            navigator.pop();
          },
        ),
        TextButton(
          child: const Text('É um Projeto'),
          onPressed: () {
            // ATUALIZADO: Usando copyWith para imutabilidade
            final updatedItem = item.copyWith(status: GtdStatus.projectTask);
            service.updateItem(updatedItem);
            navigator.pop();
            messenger.showSnackBar(
              const SnackBar(content: Text('Item movido. Crie o projeto na aba "Projetos".')),
            );
          },
        ),
      ],
    ),
  );
}
