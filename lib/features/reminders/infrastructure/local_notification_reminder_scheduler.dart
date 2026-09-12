import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/domain/cleaning_values.dart';
import '../../goals/domain/cleaning_goal.dart';
import '../application/reminder_scheduler.dart';
import '../domain/goal_reminder.dart';

class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'gentle_cleaning_reminders_v2',
      'Gentle cleaning reminders',
      channelDescription: 'Optional reminders for cleaning goals',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
    ),
    iOS: DarwinNotificationDetails(
      presentSound: false,
      presentBadge: false,
    ),
  );

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _initialized = true;
  }

  @override
  Future<bool> requestPermission() async {
    await initialize();

    if (defaultTargetPlatform == TargetPlatform.android) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.requestNotificationsPermission() ??
          false;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin>()
              ?.requestPermissions(alert: true, badge: false, sound: false) ??
          false;
    }

    return true;
  }

  @override
  Future<void> schedule(CleaningGoal goal) async {
    final reminder = goal.reminder;
    if (reminder == null) return;
    await initialize();

    await _notifications.zonedSchedule(
      id: _notificationId(goal.id),
      title: 'A small step is available',
      body: '${goal.title} — doing one tiny thing is enough.',
      scheduledDate: _nextOccurrence(
        goal.cadence,
        reminder.alignedWith(goal.schedule),
      ),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: _matchingComponents(goal.cadence),
      payload: goal.id,
    );
  }

  @override
  Future<void> cancel(String goalId) async {
    await initialize();
    await _notifications.cancel(id: _notificationId(goalId));
  }

  @override
  Future<void> showTest(CleaningGoal goal) async {
    await initialize();
    await _notifications.show(
      id: _notificationId('${goal.id}-test'),
      title: 'This is your gentle reminder',
      body: '${goal.title} — doing one tiny thing is enough.',
      notificationDetails: _details,
      payload: goal.id,
    );
  }

  DateTimeComponents _matchingComponents(GoalCadence cadence) {
    return switch (cadence) {
      GoalCadence.daily => DateTimeComponents.time,
      GoalCadence.weekly => DateTimeComponents.dayOfWeekAndTime,
      GoalCadence.monthly => DateTimeComponents.dayOfMonthAndTime,
      GoalCadence.yearly => DateTimeComponents.dateAndTime,
    };
  }

  tz.TZDateTime _nextOccurrence(
    GoalCadence cadence,
    GoalReminder reminder,
  ) {
    final now = tz.TZDateTime.now(tz.local);
    return switch (cadence) {
      GoalCadence.daily => _nextDaily(now, reminder),
      GoalCadence.weekly => _nextWeekly(now, reminder),
      GoalCadence.monthly => _nextMonthly(now, reminder),
      GoalCadence.yearly => _nextYearly(now, reminder),
    };
  }

  tz.TZDateTime _nextDaily(tz.TZDateTime now, GoalReminder reminder) {
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      reminder.hour,
      reminder.minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  tz.TZDateTime _nextWeekly(tz.TZDateTime now, GoalReminder reminder) {
    final daysAhead = (reminder.weekday - now.weekday + 7) % 7;
    var candidate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysAhead,
      reminder.hour,
      reminder.minute,
    );
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 7));
    }
    return candidate;
  }

  tz.TZDateTime _nextMonthly(tz.TZDateTime now, GoalReminder reminder) {
    var year = now.year;
    var month = now.month;
    while (true) {
      if (_daysInMonth(year, month) >= reminder.dayOfMonth) {
        final candidate = tz.TZDateTime(
          tz.local,
          year,
          month,
          reminder.dayOfMonth,
          reminder.hour,
          reminder.minute,
        );
        if (candidate.isAfter(now)) return candidate;
      }
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
    }
  }

  tz.TZDateTime _nextYearly(tz.TZDateTime now, GoalReminder reminder) {
    var year = now.year;
    while (true) {
      if (_daysInMonth(year, reminder.month) >= reminder.dayOfMonth) {
        final candidate = tz.TZDateTime(
          tz.local,
          year,
          reminder.month,
          reminder.dayOfMonth,
          reminder.hour,
          reminder.minute,
        );
        if (candidate.isAfter(now)) return candidate;
      }
      year++;
    }
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;

  int _notificationId(String goalId) {
    var hash = 0x811c9dc5;
    for (final codeUnit in goalId.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
