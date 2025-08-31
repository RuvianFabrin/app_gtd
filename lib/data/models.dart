import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

// Enumerações para status e tipo de recorrência.
enum GtdStatus { inbox, nextAction, calendar, waitingFor, somedayMaybe, projectTask, reference, done }
enum RecurrenceType { none, daily, weekly, monthly, yearly }

/// Representa um item no sistema GTD.
@immutable
class GtdItem {
  final String id;
  final String title;
  final String? description;
  final GtdStatus status;
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String? project;
  final RecurrenceType recurrence;
  final List<Duration> reminderOffsets;
  final Set<int> weeklyRecurrenceDays;
  final List<String> tags;

  const GtdItem({
    required this.id,
    required this.title,
    this.description,
    this.status = GtdStatus.inbox,
    this.dueDate,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.project,
    this.recurrence = RecurrenceType.none,
    this.reminderOffsets = const [],
    this.weeklyRecurrenceDays = const {},
    this.tags = const [],
  });

  // CORRIGIDO: O construtor de fábrica agora aceita status e projeto para evitar erros.
  factory GtdItem.newItem({
    required String title,
    String? description,
    GtdStatus status = GtdStatus.inbox,
    String? project,
  }) {
    final now = DateTime.now();
    return GtdItem(
      id: const Uuid().v4(),
      title: title,
      description: description,
      status: status,
      createdAt: now,
      lastUpdatedAt: now,
      project: project,
    );
  }

  GtdItem copyWith({
    String? id,
    String? title,
    String? description,
    GtdStatus? status,
    DateTime? dueDate,
    bool setDueDateToNull = false,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? project,
    RecurrenceType? recurrence,
    List<Duration>? reminderOffsets,
    Set<int>? weeklyRecurrenceDays,
    List<String>? tags,
  }) {
    return GtdItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      dueDate: setDueDateToNull ? null : dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      project: project ?? this.project,
      recurrence: recurrence ?? this.recurrence,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      weeklyRecurrenceDays: weeklyRecurrenceDays ?? this.weeklyRecurrenceDays,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.index,
      'createdAt': createdAt.toIso8601String(),
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'project': project,
      'recurrence': recurrence.index,
      'reminderOffsets': jsonEncode(reminderOffsets.map((d) => d.inMinutes).toList()),
      'weeklyRecurrenceDays': jsonEncode(weeklyRecurrenceDays.toList()),
      'tags': jsonEncode(tags),
    };
  }

  factory GtdItem.fromMap(Map<String, dynamic> map) {
    return GtdItem(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: GtdStatus.values[map['status']],
      createdAt: DateTime.parse(map['createdAt']),
      lastUpdatedAt: DateTime.parse(map['lastUpdatedAt'] ?? map['createdAt']),
      dueDate: map['dueDate'] != null ? DateTime.parse(map['dueDate']) : null,
      project: map['project'],
      recurrence: RecurrenceType.values[map['recurrence'] ?? 0],
      reminderOffsets: map['reminderOffsets'] != null
          ? (jsonDecode(map['reminderOffsets']) as List)
              .map((mins) => Duration(minutes: mins))
              .toList()
          : [],
      weeklyRecurrenceDays: map['weeklyRecurrenceDays'] != null
          ? (jsonDecode(map['weeklyRecurrenceDays']) as List).cast<int>().toSet()
          : {},
      tags: map['tags'] != null ? (jsonDecode(map['tags']) as List).cast<String>().toList() : [],
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

