import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/domain/cleaning_values.dart';
import '../../goals/domain/cleaning_goal.dart';
import '../../settings/domain/app_preferences.dart';
import '../../today/domain/cleaning_task.dart';
import '../application/reminder_scheduler.dart';
import '../domain/goal_reminder.dart';
import '../domain/reminder_delivery_policy.dart';

const _snoozeActionId = 'snooze_reminder';
const _reminderCategoryId = 'gentle_reminder_actions';

@pragma('vm:entry-point')
Future<void> reminderNotificationBackgroundResponse(
  NotificationResponse response,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalNotificationReminderScheduler.handleBackgroundResponse(response);
}

class LocalNotificationReminderScheduler implements ReminderScheduler {
  LocalNotificationReminderScheduler({
    FlutterLocalNotificationsPlugin? notifications,
  }) : _notifications = notifications ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _notifications;
  bool _initialized = false;
  AppPreferences _preferences = const AppPreferences();

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'gentle_cleaning_reminders_v2',
      'Gentle cleaning reminders',
      channelDescription: 'Optional reminders for cleaning goals',
      importance: Importance.high,
      priority: Priority.high,
      playSound: false,
      enableVibration: false,
      actions: [
        AndroidNotificationAction(
          _snoozeActionId,
          'Snooze',
          cancelNotification: true,
        ),
      ],
    ),
    iOS: DarwinNotificationDetails(
      presentSound: false,
      presentBadge: false,
      categoryIdentifier: _reminderCategoryId,
    ),
  );

  @override
  Future<void> configure(AppPreferences preferences) async {
    _preferences = preferences;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    await _notifications.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            DarwinNotificationCategory(
              _reminderCategoryId,
              actions: [
                DarwinNotificationAction.plain(_snoozeActionId, 'Snooze'),
              ],
            ),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: _handleResponse,
      onDidReceiveBackgroundNotificationResponse:
          reminderNotificationBackgroundResponse,
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
      scheduledDate: _afterQuietHours(
        _nextOccurrence(
          goal.cadence,
          reminder.alignedWith(goal.schedule),
        ),
      ),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: _matchingComponents(goal.cadence),
      payload: _payloadFor(goal),
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
      payload: _payloadFor(goal),
    );
  }

  @override
  Future<void> scheduleEscalation(
    CleaningGoal goal,
    CleaningTask task,
    DateTime scheduledDate,
    int occurrence,
  ) async {
    await initialize();
    final localDate = scheduledDate.toLocal();
    final candidate = tz.TZDateTime(
      tz.local,
      localDate.year,
      localDate.month,
      localDate.day,
      localDate.hour,
      localDate.minute,
    );
    await _notifications.zonedSchedule(
      id: _notificationId('${task.id}-escalation-$occurrence'),
      title: 'A gentle follow-up',
      body: '${task.title} is still here when you are ready.',
      scheduledDate: _afterQuietHours(candidate),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: _payloadFor(goal),
    );
  }

  @override
  Future<void> cancelEscalations(String taskId) async {
    await initialize();
    for (var occurrence = 1; occurrence <= 20; occurrence++) {
      await _notifications.cancel(
        id: _notificationId('$taskId-escalation-$occurrence'),
      );
    }
  }

  Future<void> _handleResponse(NotificationResponse response) async {
    if (response.actionId == _snoozeActionId) {
      await _scheduleSnooze(response.payload);
    }
  }

  static Future<void> handleBackgroundResponse(
    NotificationResponse response,
  ) async {
    if (response.actionId != _snoozeActionId) return;
    final scheduler = LocalNotificationReminderScheduler();
    await scheduler.initialize();
    await scheduler._scheduleSnooze(response.payload);
  }

  Future<void> _scheduleSnooze(String? payload) async {
    if (payload == null) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return;
    }
    if (decoded is! Map) return;
    final data = Map<String, dynamic>.from(decoded);
    final goalId = data['goalId'] as String;
    final goalTitle = data['goalTitle'] as String;
    final snoozeMinutes = data['snoozeMinutes'] as int? ?? 30;
    _preferences = _preferences.copyWith(
      quietHoursEnabled: data['quietHoursEnabled'] as bool? ?? false,
      quietStartMinute: data['quietStartMinute'] as int? ?? 21 * 60,
      quietEndMinute: data['quietEndMinute'] as int? ?? 8 * 60,
    );
    final now = tz.TZDateTime.now(tz.local);
    await _notifications.zonedSchedule(
      id: _notificationId('$goalId-snooze'),
      title: 'A small step is still available',
      body: '$goalTitle — doing one tiny thing is enough.',
      scheduledDate: _afterQuietHours(
        now.add(Duration(minutes: snoozeMinutes)),
      ),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  String _payloadFor(CleaningGoal goal) {
    return jsonEncode({
      'goalId': goal.id,
      'goalTitle': goal.title,
      'snoozeMinutes': _preferences.snoozeMinutes,
      'quietHoursEnabled': _preferences.quietHoursEnabled,
      'quietStartMinute': _preferences.quietStartMinute,
      'quietEndMinute': _preferences.quietEndMinute,
    });
  }

  tz.TZDateTime _afterQuietHours(tz.TZDateTime candidate) {
    final adjusted = ReminderDeliveryPolicy.afterQuietHours(
      candidate,
      _preferences,
    );
    return tz.TZDateTime(
      tz.local,
      adjusted.year,
      adjusted.month,
      adjusted.day,
      adjusted.hour,
      adjusted.minute,
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
