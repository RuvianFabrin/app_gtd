import 'dart:convert';
import 'package:uuid/uuid.dart';

// MODIFICADO: Adicionado 'monthly' e 'yearly'
enum RecurrenceType { none, daily, weekly, monthly, yearly }

enum GtdStatus {
  inbox,
  nextAction,
  calendar,
  waitingFor,
  somedayMaybe,
  projectTask,
  reference,
  done
}

class GtdItem {
  final String id;
  String title;
  String? description;
  GtdStatus status;
  DateTime createdAt;
  DateTime? dueDate;
  String? project;
  RecurrenceType recurrence;
  List<Duration> reminderOffsets;
  Set<int> weeklyRecurrenceDays;

  GtdItem({
    String? id,
    required this.title,
    this.description,
    this.status = GtdStatus.inbox,
    DateTime? createdAt,
    this.dueDate,
    this.project,
    this.recurrence = RecurrenceType.none,
    List<Duration>? reminderOffsets,
    Set<int>? weeklyRecurrenceDays,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        reminderOffsets = reminderOffsets ?? [],
        weeklyRecurrenceDays = weeklyRecurrenceDays ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'project': project,
      'recurrence': recurrence.index,
      'reminderOffsets':
          jsonEncode(reminderOffsets.map((d) => d.inMinutes).toList()),
      'weeklyRecurrenceDays': jsonEncode(weeklyRecurrenceDays.toList()),
    };
  }

  factory GtdItem.fromMap(Map<String, dynamic> map) {
    return GtdItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: GtdStatus.values[map['status']],
      createdAt: DateTime.parse(map['createdAt']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      project: map['project'],
      recurrence: RecurrenceType.values[map['recurrence'] ?? 0],
      reminderOffsets: map['reminderOffsets'] != null
          ? (jsonDecode(map['reminderOffsets']) as List)
              .map((mins) => Duration(minutes: mins))
              .toList()
          : [],
      weeklyRecurrenceDays: map['weeklyRecurrenceDays'] != null
          ? (jsonDecode(map['weeklyRecurrenceDays']) as List)
              .cast<int>()
              .toSet()
          : {},
    );
  }
}

class Project {
  final String id;
  String name;
  int totalMinutesSpent;

  Project({
    String? id,
    required this.name,
    this.totalMinutesSpent = 0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'totalMinutesSpent': totalMinutesSpent,
    };
  }

  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'],
      name: map['name'],
      totalMinutesSpent: map['totalMinutesSpent'],
    );
  }
}
