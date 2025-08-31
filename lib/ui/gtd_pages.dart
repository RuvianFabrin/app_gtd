import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';
import 'clarify_flow.dart';
import 'task_editor.dart';

/// Um widget reutilizável para exibir uma lista de itens GTD.
class GtdItemListView extends StatelessWidget {
  final List<GtdItem> items;
  final String emptyListMessage;
  final Widget? Function(GtdItem item)? subtitleBuilder;

  const GtdItemListView({
    super.key,
    required this.items,
    this.emptyListMessage = "Nenhum item aqui.",
    this.subtitleBuilder,
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
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80), // Padding for FAB
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Text(item.title),
            subtitle: subtitleBuilder != null
                ? subtitleBuilder!(item)
                : (item.description != null && item.description!.isNotEmpty
                    ? Text(item.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
                    : null),
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

// --- Páginas Individuais ---

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

class NextActionsPage extends StatelessWidget {
  const NextActionsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = context.watch<GtdService>().nextActionsItems;
    return GtdItemListView(items: items, emptyListMessage: "Nenhuma próxima ação definida.");
  }
}

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  String _formatRecurrence(GtdItem item) {
    switch (item.recurrence) {
      case RecurrenceType.none: return '';
      case RecurrenceType.daily: return 'Repete: Diariamente';
      case RecurrenceType.weekly:
        if (item.weeklyRecurrenceDays.isEmpty) return 'Repete: Semanalmente';
        final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
        final sortedDays = item.weeklyRecurrenceDays.toList()..sort();
        final selectedDays = sortedDays.map((d) => days[d - 1]).join(', ');
        return 'Repete: $selectedDays';
      case RecurrenceType.monthly: return 'Repete: Mensalmente';
      case RecurrenceType.yearly: return 'Repete: Anualmente';
    }
  }

  String _formatReminders(GtdItem item) {
    if (item.reminderOffsets.isEmpty) return '';
    final reminders = item.reminderOffsets.map((d) {
      if (d.inDays > 0) return '${d.inDays}d';
      if (d.inHours > 0) return '${d.inHours}h';
      return '${d.inMinutes}m';
    }).join(', ');
    return 'Lembretes: $reminders antes';
  }

  Widget _buildSubtitle(BuildContext context, GtdItem item) {
    if (item.dueDate == null) return const SizedBox.shrink();

    final formattedDate = DateFormat("dd/MM/yyyy 'às' HH:mm").format(item.dueDate!);
    final recurrenceInfo = _formatRecurrence(item);
    final remindersInfo = _formatReminders(item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(formattedDate, style: const TextStyle(fontWeight: FontWeight.bold)),
        if (recurrenceInfo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(recurrenceInfo, style: Theme.of(context).textTheme.bodySmall),
          ),
        if (remindersInfo.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Text(remindersInfo, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = context.watch<GtdService>().calendarItemsGrouped;
    final groupKeys = groupedItems.keys.toList();

    if (groupedItems.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            "Nenhum item agendado.\nDefina uma data e hora para seus compromissos.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
      itemCount: groupKeys.length,
      itemBuilder: (context, groupIndex) {
        final groupTitle = groupKeys[groupIndex];
        final itemsInGroup = groupedItems[groupTitle]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                groupTitle,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemsInGroup.length,
              itemBuilder: (context, itemIndex) {
                final item = itemsInGroup[itemIndex];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  child: ListTile(
                    title: Text(item.title),
                    subtitle: _buildSubtitle(context, item),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TaskEditorScreen(item: item)),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class WaitingPage extends StatelessWidget {
  const WaitingPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = context.watch<GtdService>().waitingForItems;
    return GtdItemListView(items: items, emptyListMessage: "Você não está aguardando por nada.");
  }
}

class SomedayPage extends StatelessWidget {
  const SomedayPage({super.key});
  @override
  Widget build(BuildContext context) {
    final items = context.watch<GtdService>().somedayMaybeItems;
    return GtdItemListView(items: items, emptyListMessage: "A lista 'Algum dia/Talvez' está vazia.");
  }
}

