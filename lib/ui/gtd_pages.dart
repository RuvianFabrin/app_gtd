import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';
import 'clarify_flow.dart';
import 'task_editor.dart';

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

void _showMoveItemDialog(BuildContext context, GtdItem item) {
  final service = context.read<GtdService>();
  
  final destinations = GtdStatus.values.where((s) => 
      s != item.status && 
      s != GtdStatus.inbox && 
      s != GtdStatus.projectTask && 
      s != GtdStatus.done
  ).toList();

  showModalBottomSheet(
    context: context,
    builder: (context) {
      return ListView.builder(
        shrinkWrap: true,
        itemCount: destinations.length,
        itemBuilder: (context, index) {
          final status = destinations[index];
          return ListTile(
            title: Text(_getStatusLabel(status)),
            onTap: () {
              final updatedItem = item.copyWith(status: status, lastUpdatedAt: DateTime.now());
              service.updateItem(updatedItem);
              Navigator.pop(context);
            },
          );
        },
      );
    },
  );
}

class GtdItemListView extends StatelessWidget {
  final List<GtdItem> items;
  final String emptyListMessage;
  final Widget? Function(GtdItem item)? subtitleBuilder;
  final List<Widget>? Function(GtdItem item)? trailingActionsBuilder;

  const GtdItemListView({
    super.key,
    required this.items,
    this.emptyListMessage = "Nenhum item aqui.",
    this.subtitleBuilder,
    this.trailingActionsBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            emptyListMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        
        final customActions = trailingActionsBuilder?.call(item) ?? [];
        final moveAction = item.status != GtdStatus.inbox ? [
          IconButton(
            icon: const Icon(Icons.drive_file_move_outline),
            onPressed: () => _showMoveItemDialog(context, item),
            tooltip: 'Mover para...',
          )
        ] : [];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(item.title),
            subtitle: subtitleBuilder?.call(item),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [...customActions, ...moveAction],
            ),
            onTap: () {
              if (item.status == GtdStatus.inbox) {
                startClarifyFlow(context, item);
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => TaskEditorScreen(item: item)),
                );
              }
            },
          ),
        );
      },
    );
  }
}

// CORRIGIDO: A InboxPage foi adicionada de volta.
class InboxPage extends StatelessWidget {
  const InboxPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = context.watch<GtdService>().inboxItems;
    return GtdItemListView(
        items: items,
        emptyListMessage: "Caixa de entrada vazia!\nClique em um item para processá-lo.");
  }
}

