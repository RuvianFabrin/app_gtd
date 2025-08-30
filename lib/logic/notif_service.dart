import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import '../data/models.dart';

class NotificationService {
  Future<void> init() async {
    await AwesomeNotifications().initialize(
      null,
      [
        // MODIFICADO: Removido o canal silencioso, apenas o canal de alarme permanece
        NotificationChannel(
          channelKey: 'alarm_channel',
          channelName: 'Alarmes GTD+',
          channelDescription: 'Canal para notificações de alarme com som.',
          defaultColor: Colors.blue,
          ledColor: Colors.white,
          importance: NotificationImportance.Max,
          channelShowBadge: true,
          locked: true,
          soundSource: 'resource://raw/alarm',
          defaultRingtoneType: DefaultRingtoneType.Alarm,
        ),
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> scheduleNotificationsForItem(GtdItem item) async {
    await cancelAllNotificationsForItem(item);

    if (item.status != GtdStatus.calendar || item.dueDate == null) return;
    if (item.dueDate!.isBefore(DateTime.now()) && item.recurrence == RecurrenceType.none) return;

    await _scheduleRecurringNotifications(
      item: item,
      scheduleTime: item.dueDate!,
      bodyBuilder: (item) => 'O evento "${item.title}" está a começar agora.',
    );

    for (final offset in item.reminderOffsets) {
      final reminderTime = item.dueDate!.subtract(offset);
      await _scheduleRecurringNotifications(
        item: item,
        scheduleTime: reminderTime,
        bodyBuilder: (item) => 'Lembrete para "${item.title}": ${_formatDuration(offset)}.',
      );
    }
  }

  Future<void> cancelAllNotificationsForItem(GtdItem item) async {
    await AwesomeNotifications().cancelSchedulesByGroupKey(item.id);
    await AwesomeNotifications().dismissNotificationsByGroupKey(item.id);
  }

  Future<void> _scheduleRecurringNotifications({
    required GtdItem item,
    required DateTime scheduleTime,
    required String Function(GtdItem) bodyBuilder,
  }) async {
    if (scheduleTime.isBefore(DateTime.now()) && item.recurrence == RecurrenceType.none) {
      return;
    }

    final body = bodyBuilder(item);

    // MODIFICADO: Adicionado casos para recorrência mensal e anual
    switch (item.recurrence) {
      case RecurrenceType.none:
        await _createNotification(item: item, body: body, schedule: NotificationCalendar.fromDate(date: scheduleTime, allowWhileIdle: true, preciseAlarm: true));
        break;
      case RecurrenceType.daily:
        await _createNotification(item: item, body: body, schedule: NotificationCalendar(hour: scheduleTime.hour, minute: scheduleTime.minute, second: 0, repeats: true, allowWhileIdle: true, preciseAlarm: true));
        break;
      case RecurrenceType.weekly:
        List<int> weekdays = item.weeklyRecurrenceDays.isNotEmpty ? item.weeklyRecurrenceDays.toList() : [scheduleTime.weekday];
        for (int day in weekdays) {
          await _createNotification(item: item, body: body, schedule: NotificationCalendar(weekday: day, hour: scheduleTime.hour, minute: scheduleTime.minute, second: 0, repeats: true, allowWhileIdle: true, preciseAlarm: true));
        }
        break;
      case RecurrenceType.monthly:
         await _createNotification(item: item, body: body, schedule: NotificationCalendar(day: scheduleTime.day, hour: scheduleTime.hour, minute: scheduleTime.minute, second: 0, repeats: true, allowWhileIdle: true, preciseAlarm: true));
        break;
      case RecurrenceType.yearly:
         await _createNotification(item: item, body: body, schedule: NotificationCalendar(month: scheduleTime.month, day: scheduleTime.day, hour: scheduleTime.hour, minute: scheduleTime.minute, second: 0, repeats: true, allowWhileIdle: true, preciseAlarm: true));
        break;
    }
  }

  // MODIFICADO: Cria apenas uma notificação e remove o prefixo "Alarme:"
  Future<void> _createNotification({
    required GtdItem item,
    required String body,
    required NotificationSchedule schedule,
  }) async {
    await AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(2147483647),
        channelKey: 'alarm_channel',
        groupKey: item.id,
        title: item.title, // Título agora é só o nome do item
        body: body,
        wakeUpScreen: true,
        fullScreenIntent: true,
        category: NotificationCategory.Alarm,
        locked: true,
      ),
      schedule: schedule,
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return "${duration.inMinutes} minutos antes";
    } else if (duration.inHours < 24) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes == 0) return "$hours hora(s) antes";
      return "$hours h e $minutes min antes";
    } else {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours == 0) return "$days dia(s) antes";
      return "$days d e $hours h antes";
    }
  }
}

