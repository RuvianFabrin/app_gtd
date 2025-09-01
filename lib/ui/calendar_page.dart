import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../data/models.dart';
import '../logic/gtd_service.dart';
import 'calendar_settings_dialog.dart';
import 'gtd_pages.dart'; // Reutiliza o GtdItemListView

// Enum para opções de ordenação
enum SortOption { title, date }

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  SortOption _sortOption = SortOption.date;
  bool _isAscending = true; // true = mais antigo para mais novo / A-Z

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

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GtdService>();
    final items = _getFilteredAndSortedItems(service.calendarItems);

    return Column(
      children: [
        // Seção de Pesquisa e Ordenação
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Pesquisar por título, texto ou tag',
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
        // Lista de itens
        Expanded(
          child: GtdItemListView(
            items: items,
            emptyListMessage: "Nenhum item agendado.",
            subtitleBuilder: (item) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.dueDate != null ? DateFormat("dd/MM/yyyy 'às' HH:mm").format(item.dueDate!) : 'Sem data',
                     style: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  if (item.tags.isNotEmpty)
                    Wrap(
                      spacing: 6.0,
                      runSpacing: 4.0,
                      children: item.tags.map((tag) => Chip(
                        label: Text(tag),
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      )).toList(),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    'Atualizado: ${DateFormat('dd/MM/yy HH:mm').format(item.lastUpdatedAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              );
            },
             trailingActionsBuilder: (item) => [
              IconButton(
                icon: const Icon(Icons.alarm),
                onPressed: () async {
                  final updatedItem = await CalendarSettingsDialog.show(context, item);
                  if (updatedItem != null && context.mounted) {
                    await service.updateItem(updatedItem);
                  }
                },
              )
            ],
          ),
        ),
      ],
    );
  }

  List<GtdItem> _getFilteredAndSortedItems(List<GtdItem> allItems) {
    final filteredItems = _searchQuery.isEmpty
        ? allItems
        : allItems.where((item) {
            final titleMatch = item.title.toLowerCase().contains(_searchQuery);
            final contentMatch = _getContentForSearch(item).contains(_searchQuery);
            final tagMatch = item.tags.any((tag) => tag.toLowerCase().contains(_searchQuery));
            return titleMatch || contentMatch || tagMatch;
          }).toList();

    filteredItems.sort((a, b) {
      int comparison;
      if (_sortOption == SortOption.title) {
        comparison = a.title.toLowerCase().compareTo(b.title.toLowerCase());
      } else {
        comparison = (a.dueDate ?? DateTime(0)).compareTo(b.dueDate ?? DateTime(0));
      }
      return _isAscending ? comparison : -comparison;
    });

    return filteredItems;
  }
  
  String _getContentForSearch(GtdItem item) {
    if (item.description == null || item.description!.isEmpty) return '';
    try {
       final doc = quill.Document.fromJson(jsonDecode(item.description!));
       return doc.toPlainText().toLowerCase();
    } catch(e) {
      return item.description!.toLowerCase();
    }
  }
}
