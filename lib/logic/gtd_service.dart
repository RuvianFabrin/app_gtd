import 'package:flutter/foundation.dart';
import '../data/models.dart';
import '../data/repo.dart';
import 'notif_service.dart';

class GtdService extends ChangeNotifier {
  final GtdRepository _repository;
  final NotificationService _notificationService;

  GtdService(this._repository, this._notificationService);

  List<GtdItem> _items = [];
  List<Project> _projects = [];

  List<GtdItem> get items => _items;
  List<Project> get projects => _projects;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();
    _items = await _repository.getAllItems();
    _projects = await _repository.getAllProjects();
    _isLoading = false;
    notifyListeners();
  }

  // --- Lógica de Itens GTD ---
  Future<void> addItem(GtdItem item) async {
    await _repository.createItem(item);
    _items.add(item);
    await _scheduleNotifications(item);
    notifyListeners();
  }

  Future<void> updateItem(GtdItem item) async {
    await _repository.updateItem(item);
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
    }
    await _scheduleNotifications(item);
    notifyListeners();
  }

  Future<void> deleteItem(String id) async {
    final itemIndex = _items.indexWhere((i) => i.id == id);
    if (itemIndex == -1) return;

    final item = _items[itemIndex];
    await _notificationService.cancelAllNotificationsForItem(item);

    await _repository.deleteItem(id);
    _items.removeAt(itemIndex);
    notifyListeners();
  }

  // --- Lógica de Projetos ---
  Future<void> addProject(String name) async {
    final newProject = Project.newProject(name: name);
    await _repository.createProject(newProject);
    _projects.add(newProject);
    notifyListeners();
  }

   Future<void> updateProject(Project project) async {
    await _repository.updateProject(project);
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    }
    notifyListeners();
  }

  Future<void> addTimeToProject(String projectId, int minutes) async {
    final index = _projects.indexWhere((p) => p.id == projectId);
    if (index != -1) {
      final oldProject = _projects[index];
      final updatedProject = oldProject.copyWith(
        totalMinutesSpent: oldProject.totalMinutesSpent + minutes
      );
      await _repository.updateProject(updatedProject);
      _projects[index] = updatedProject;
      notifyListeners();
    }
  }

  Future<void> _scheduleNotifications(GtdItem item) async {
    try {
      await _notificationService.scheduleNotificationsForItem(item);
    } catch (e) {
      debugPrint("Ocorreu um erro ao agendar notificações: $e");
    }
  }

  // --- Listas e Dados Filtrados ---
  List<GtdItem> get inboxItems =>
      _items.where((i) => i.status == GtdStatus.inbox).toList();
  List<GtdItem> get nextActionsItems =>
      _items.where((i) => i.status == GtdStatus.nextAction).toList();
  List<GtdItem> get calendarItems {
    final items = _items
        .where((i) => i.status == GtdStatus.calendar && i.dueDate != null)
        .toList();
    items.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return items;
  }
  
  Set<String> get allTags {
    final Set<String> tags = {};
    for (final item in _items) {
      tags.addAll(item.tags);
    }
    for (final project in _projects){
      tags.addAll(project.tags);
    }
    return tags;
  }

  Map<String, List<GtdItem>> get calendarItemsGrouped {
    final sortedItems = calendarItems;
    if (sortedItems.isEmpty) return {};

    final Map<String, List<GtdItem>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfWeek = startOfToday.add(Duration(days: DateTime.daysPerWeek - now.weekday));
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    for (final item in sortedItems) {
      if (item.dueDate == null) continue;
      final itemDate = item.dueDate!;
      final itemDay = DateTime(itemDate.year, itemDate.month, itemDate.day);
      String groupKey;

      if (itemDay.isAtSameMomentAs(today)) {
        groupKey = 'Hoje';
      } else if (itemDay.isAtSameMomentAs(tomorrow)) {
        groupKey = 'Amanhã';
      } else if (itemDay.isAfter(tomorrow) && itemDay.isBefore(endOfWeek.add(const Duration(days: 1)))) {
        groupKey = 'Esta Semana';
      } else if (itemDay.isAfter(endOfWeek) && itemDay.isBefore(endOfMonth.add(const Duration(days: 1)))) {
        groupKey = 'Este Mês';
      } else if (itemDate.year == now.year && itemDate.month == now.month + 1) {
        groupKey = 'Próximo Mês';
      } else {
        groupKey = 'Futuro';
      }

      (grouped[groupKey] ??= []).add(item);
    }

    final orderedGrouped = <String, List<GtdItem>>{};
    const groupOrder = ['Hoje', 'Amanhã', 'Esta Semana', 'Este Mês', 'Próximo Mês', 'Futuro'];
    for (var key in groupOrder) {
      if (grouped.containsKey(key)) {
        orderedGrouped[key] = grouped[key]!;
      }
    }
    return orderedGrouped;
  }

  List<GtdItem> get waitingForItems =>
      _items.where((i) => i.status == GtdStatus.waitingFor).toList();
  List<GtdItem> get somedayMaybeItems =>
      _items.where((i) => i.status == GtdStatus.somedayMaybe).toList();
  List<GtdItem> get referenceItems =>
      _items.where((i) => i.status == GtdStatus.reference).toList();
      
  // NOVO: Método para buscar tarefas de um projeto específico.
  List<GtdItem> getTasksForProject(String projectId) {
    return _items.where((item) {
      return item.project == projectId &&
          (item.status == GtdStatus.projectTask || item.status == GtdStatus.done);
    }).toList();
  }
}

