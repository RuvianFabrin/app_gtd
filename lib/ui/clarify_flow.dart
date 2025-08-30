import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';

// Função principal que inicia o fluxo de perguntas
void startClarifyFlow(BuildContext context, GtdItem item) {
  _showQuestion1(context, item);
}

// Pergunta 1: É acionável?
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

// Opções para itens não acionáveis
void _showNonActionableOptions(BuildContext context, GtdItem item) {
  final service = context.read<GtdService>();
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
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            child: const Text("Guardar em 'Algum dia'"),
            onPressed: () {
              item.status = GtdStatus.somedayMaybe;
              service.updateItem(item);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            child: const Text("Arquivar como 'Referência'"),
            onPressed: () {
              item.status = GtdStatus.reference;
              service.updateItem(item);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}

// Pergunta 2: É um projeto?
void _showQuestion2(BuildContext context, GtdItem item) {
  final service = context.read<GtdService>();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('É uma ação única ou um projeto?'),
      content: const Text('Um projeto requer vários passos para ser concluído.'),
      actions: [
        TextButton(
          child: const Text('Ação Única'),
          onPressed: () {
            item.status = GtdStatus.nextAction;
            service.updateItem(item);
            Navigator.pop(context);
          },
        ),
        TextButton(
          child: const Text('É um Projeto'),
          onPressed: () {
            // Aqui, idealmente, abriria um fluxo para criar o projeto
            // e associar este item como a primeira tarefa.
            // Por simplicidade, vamos apenas mover para a lista de projetos.
            item.status = GtdStatus.projectTask;
            service.updateItem(item);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Item movido. Crie o projeto na aba "Projetos".')),
            );
          },
        ),
      ],
    ),
  );
}
