import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/goals/domain/cleaning_goal.dart';
import '../../features/goals/domain/goal_schedule.dart';
import '../../features/reminders/domain/goal_reminder.dart';
import '../../features/settings/domain/app_preferences.dart';
import '../../features/today/domain/cleaning_task.dart';
import '../domain/cleaning_values.dart';
import 'cleaning_repository.dart';

class SharedPreferencesCleaningRepository implements CleaningRepository {
  SharedPreferencesCleaningRepository({
    SharedPreferencesAsync? preferences,
    DateTime Function()? now,
  })  : _preferences = preferences ?? SharedPreferencesAsync(),
        _now = now ?? DateTime.now;

  // Keep the original key so schema version 1 data can be migrated in place.
  static const _storageKey = 'cleaning_snapshot_v1';
  static const _schemaVersion = 11;

  final SharedPreferencesAsync _preferences;
  final DateTime Function() _now;

  @override
  Future<CleaningSnapshot?> load() async {
    final rawSnapshot = await _preferences.getString(_storageKey);
    if (rawSnapshot == null) return null;

    final decoded = jsonDecode(rawSnapshot);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Cleaning snapshot must be a JSON object.');
    }
    final version = decoded['version'];
    if (version != 1 &&
        version != 2 &&
        version != 3 &&
        version != 4 &&
        version != 5 &&
        version != 6 &&
        version != 7 &&
        version != 8 &&
        version != 9 &&
        version != 10 &&
        version != _schemaVersion) {
      throw const FormatException('Unsupported cleaning snapshot version.');
    }

    final rawGoals = decoded['goals'];
    final rawTasks = decoded['tasks'];
    if (rawGoals is! List<dynamic> || rawTasks is! List<dynamic>) {
      throw const FormatException('Cleaning snapshot lists are missing.');
    }

    return CleaningSnapshot(
      goals: rawGoals.map((value) {
        return _goalFromJson(Map<String, dynamic>.from(value as Map));
      }).toList(),
      tasks: rawTasks.map((value) {
        return _taskFromJson(
          Map<String, dynamic>.from(value as Map),
          version: version as int,
        );
      }).toList(),
      preferences: _preferencesFromJson(decoded['preferences']),
    );
  }

  @override
  Future<void> save(CleaningSnapshot snapshot) {
    final encoded = jsonEncode({
      'version': _schemaVersion,
      'goals': snapshot.goals.map(_goalToJson).toList(),
      'tasks': snapshot.tasks.map(_taskToJson).toList(),
      'preferences': {
        'theme': snapshot.preferences.theme.name,
        'textScale': snapshot.preferences.textScale,
        'reduceMotion': snapshot.preferences.reduceMotion,
        'highContrast': snapshot.preferences.highContrast,
        'hapticsEnabled': snapshot.preferences.hapticsEnabled,
        'quietHoursEnabled': snapshot.preferences.quietHoursEnabled,
        'quietStartMinute': snapshot.preferences.quietStartMinute,
        'quietEndMinute': snapshot.preferences.quietEndMinute,
        'maxActiveReminders': snapshot.preferences.maxActiveReminders,
        'snoozeMinutes': snapshot.preferences.snoozeMinutes,
      },
    });
    return _preferences.setString(_storageKey, encoded);
  }

  AppPreferences _preferencesFromJson(Object? value) {
    if (value is! Map) return const AppPreferences();
    final json = Map<String, dynamic>.from(value);
    return AppPreferences(
      theme: AppThemePreference.values.byName(
        json['theme'] as String? ?? AppThemePreference.system.name,
      ),
      textScale: (json['textScale'] as num?)?.toDouble() ??
          ((json['largerText'] as bool? ?? false) ? 1.15 : 1.0),
      reduceMotion: json['reduceMotion'] as bool? ?? false,
      highContrast: json['highContrast'] as bool? ?? false,
      hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietStartMinute: json['quietStartMinute'] as int? ?? 21 * 60,
      quietEndMinute: json['quietEndMinute'] as int? ?? 8 * 60,
      maxActiveReminders: json['maxActiveReminders'] as int? ?? 3,
      snoozeMinutes: json['snoozeMinutes'] as int? ?? 30,
    );
  }

  Map<String, Object?> _goalToJson(CleaningGoal goal) {
    return {
      'id': goal.id,
      'title': goal.title,
      'room': goal.room,
      'cadence': goal.cadence.name,
      'energyLevel': goal.energyLevel.name,
      'isArchived': goal.isArchived,
      'schedule': {
        'weekday': goal.schedule.weekday,
        'dayOfMonth': goal.schedule.dayOfMonth,
        'month': goal.schedule.month,
      },
      'reminder': goal.reminder == null
          ? null
          : {
              'hour': goal.reminder!.hour,
              'minute': goal.reminder!.minute,
              'weekday': goal.reminder!.weekday,
              'dayOfMonth': goal.reminder!.dayOfMonth,
              'month': goal.reminder!.month,
              'escalationEnabled': goal.reminder!.escalationEnabled,
              'escalateAfterSkips': goal.reminder!.escalateAfterSkips,
              'escalationDelayMinutes': goal.reminder!.escalationDelayMinutes,
              'maxEscalationsPerPeriod': goal.reminder!.maxEscalationsPerPeriod,
            },
    };
  }

  CleaningGoal _goalFromJson(Map<String, dynamic> json) {
    final rawReminder = json['reminder'];
    final rawSchedule = json['schedule'];
    final reminder = rawReminder is Map
        ? _reminderFromJson(Map<String, dynamic>.from(rawReminder))
        : null;
    final fallbackDate = _now().toLocal();
    return CleaningGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      room: json['room'] as String,
      cadence: GoalCadence.values.byName(json['cadence'] as String),
      energyLevel: EnergyLevel.values.byName(json['energyLevel'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      reminder: reminder,
      schedule: rawSchedule is Map
          ? _scheduleFromJson(Map<String, dynamic>.from(rawSchedule))
          : GoalSchedule(
              weekday: reminder?.weekday ?? fallbackDate.weekday,
              dayOfMonth: reminder?.dayOfMonth ?? fallbackDate.day,
              month: reminder?.month ?? fallbackDate.month,
            ),
    );
  }

  GoalSchedule _scheduleFromJson(Map<String, dynamic> json) {
    return GoalSchedule(
      weekday: json['weekday'] as int,
      dayOfMonth: json['dayOfMonth'] as int,
      month: json['month'] as int,
    );
  }

  GoalReminder _reminderFromJson(Map<String, dynamic> json) {
    return GoalReminder(
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      weekday: json['weekday'] as int,
      dayOfMonth: json['dayOfMonth'] as int,
      month: json['month'] as int,
      escalationEnabled: json['escalationEnabled'] as bool? ?? false,
      escalateAfterSkips: json['escalateAfterSkips'] as int? ?? 3,
      escalationDelayMinutes: json['escalationDelayMinutes'] as int? ?? 60,
      maxEscalationsPerPeriod: json['maxEscalationsPerPeriod'] as int? ?? 2,
    );
  }

  Map<String, Object?> _taskToJson(CleaningTask task) {
    return {
      'id': task.id,
      'title': task.title,
      'goalId': task.goalId,
      'estimatedMinutes': task.estimatedMinutes,
      'energyLevel': task.energyLevel.name,
      'isArchived': task.isArchived,
      'completions': task.completions
          .map((completion) => completion.toUtc().toIso8601String())
          .toList(),
      'skips':
          task.skips.map((skip) => skip.toUtc().toIso8601String()).toList(),
      'repeatMode': task.repeatMode.name,
    };
  }

  CleaningTask _taskFromJson(
    Map<String, dynamic> json, {
    required int version,
  }) {
    final completions = version == 1
        ? (json['isComplete'] as bool? ?? false)
            ? [_now().toUtc()]
            : <DateTime>[]
        : (json['completions'] as List<dynamic>)
            .map((value) => DateTime.parse(value as String))
            .toList();
    final skips = version >= 8
        ? (json['skips'] as List<dynamic>)
            .map((value) => DateTime.parse(value as String))
            .toList()
        : <DateTime>[];

    return CleaningTask(
      id: json['id'] as String,
      title: json['title'] as String,
      goalId: json['goalId'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      energyLevel: EnergyLevel.values.byName(json['energyLevel'] as String),
      completions: completions,
      isArchived: json['isArchived'] as bool? ?? false,
      skips: skips,
      repeatMode: version >= 11
          ? TaskRepeatMode.values.byName(json['repeatMode'] as String)
          : TaskRepeatMode.repeating,
    );
  }
}
