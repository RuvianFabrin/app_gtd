import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';
import 'gtd_pages.dart';
import 'task_editor.dart';

enum SortOption { title, date }

class ProjectDetailPage extends StatefulWidget {
  final Project project;
  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortOption = SortOption.date;
  bool _isAscending = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addTask(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova Tarefa do Projeto'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Nome da tarefa"),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final service = context.read<GtdService>();
                final newItem = GtdItem.newItem(
                  title: controller.text,
                  status: GtdStatus.projectTask,
                ).copyWith(project: widget.project.id);
                
                service.addItem(newItem);
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GtdService>();
    final projectTasks = _getFilteredAndSortedItems(
        service.getTasksForProject(widget.project.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Pesquisar tarefas...',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SegmentedButton<SortOption>(
                      segments: const [
                        ButtonSegment(value: SortOption.date, label: Text('Data'), icon: Icon(Icons.date_range)),
                        ButtonSegment(value: SortOption.title, label: Text('Título'), icon: Icon(Icons.title)),
                      ],
                      selected: {_sortOption},
                      onSelectionChanged: (newSelection) {
                        setState(() {
                          _sortOption = newSelection.first;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(_isAscending ? Icons.arrow_upward : Icons.arrow_downward),
                      onPressed: () {
                        setState(() {
                          _isAscending = !_isAscending;
                        });
                      },
                      tooltip: 'Inverter ordem',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: GtdItemListView(
              items: projectTasks,
              emptyListMessage: 'Nenhuma tarefa neste projeto ainda.',
              subtitleBuilder: (item) => _buildSubtitle(context, item),
              trailingActionsBuilder: (item) {
                final isDone = item.status == GtdStatus.done;
                return [
                  Checkbox(
                    value: isDone,
                    onChanged: (bool? value) {
                      if (value != null) {
                        final newStatus = value ? GtdStatus.done : GtdStatus.projectTask;
                        final updatedTask = item.copyWith(status: newStatus, lastUpdatedAt: DateTime.now());
                        service.updateItem(updatedTask);
                      }
                    },
                  ),
                ];
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addTask(context),
        child: const Icon(Icons.add_task),
        tooltip: 'Nova Tarefa',
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, GtdItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContentSubtitle(item),
        const SizedBox(height: 8),
        if (item.tags.isNotEmpty)
          Wrap(
            spacing: 6.0,
            runSpacing: 4.0,
            children: item.tags
                .map((tag) => Chip(
                      label: Text(tag),
                      labelStyle: const TextStyle(fontSize: 10),
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ))
                .toList(),
          ),
        const SizedBox(height: 4),
        Text(
          'Atualizado: ${DateFormat('dd/MM/yy HH:mm').format(item.lastUpdatedAt)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  // CORRIGIDO: Lógica de exibição do resumo do Quill ajustada
  Widget _buildContentSubtitle(GtdItem item) {
    if (item.description == null || item.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    try {
      final doc = quill.Document.fromJson(jsonDecode(item.description!));
      final plainText = doc.toPlainText().replaceAll('\n', ' ').trim();
      if (plainText.isEmpty) return const SizedBox.shrink();
      return Text(
        plainText,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    } catch (e) {
      return Text(
        item.description!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
  }

  List<GtdItem> _getFilteredAndSortedItems(List<GtdItem> allItems) {
    final filteredItems = _searchQuery.isEmpty
        ? allItems
        : allItems.where((item) {
            final titleMatch = item.title.toLowerCase().contains(_searchQuery);
            final contentMatch = _getContentForSearch(item).contains(_searchQuery);
            final tagMatch =
                item.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
            return titleMatch || contentMatch || tagMatch;
          }).toList();

    filteredItems.sort((a, b) {
      if (a.status == GtdStatus.done && b.status != GtdStatus.done) return 1;
      if (a.status != GtdStatus.done && b.status == GtdStatus.done) return -1;

      int comparison;
      if (_sortOption == SortOption.title) {
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else {
        comparison = a.createdAt.compareTo(b.createdAt);
      }
      return _isAscending ? comparison : -comparison;
    });

    return filteredItems;
  }

  // CORRIGIDO: Lógica de extração de texto do Quill para busca ajustada
  String _getContentForSearch(GtdItem item) {
    if (item.description == null || item.description!.isEmpty) return '';
    try {
      final doc = quill.Document.fromJson(jsonDecode(item.description!));
      return doc.toPlainText().toLowerCase();
    } catch (e) {
      return item.description!.toLowerCase();
    }
  }
}
