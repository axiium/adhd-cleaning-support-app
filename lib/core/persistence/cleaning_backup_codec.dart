import 'dart:convert';

import '../../features/goals/domain/cleaning_goal.dart';
import '../../features/goals/domain/goal_schedule.dart';
import '../../features/reminders/domain/goal_reminder.dart';
import '../../features/settings/domain/app_preferences.dart';
import '../../features/today/domain/cleaning_task.dart';
import '../domain/cleaning_values.dart';
import 'cleaning_repository.dart';

class CleaningBackupCodec {
  static String encode(CleaningSnapshot snapshot) => jsonEncode({
        'format': 'cleaning-support-backup',
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'goals': snapshot.goals.map(_goalToJson).toList(),
        'tasks': snapshot.tasks.map(_taskToJson).toList(),
        'preferences': {
          'theme': snapshot.preferences.theme.name,
          'textScale': snapshot.preferences.textScale,
          'reduceMotion': snapshot.preferences.reduceMotion,
          'highContrast': snapshot.preferences.highContrast,
          'hapticsEnabled': snapshot.preferences.hapticsEnabled,
        },
      });

  static CleaningSnapshot decode(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map || decoded['format'] != 'cleaning-support-backup') {
      throw const FormatException('This is not a Cleaning Support backup.');
    }
    final goals = (decoded['goals'] as List)
        .map((item) => _goalFromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final tasks = (decoded['tasks'] as List)
        .map((item) => _taskFromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    final goalIds = goals.map((goal) => goal.id).toSet();
    if (tasks.any((task) => !goalIds.contains(task.goalId))) {
      throw const FormatException('Backup contains a step without its goal.');
    }
    final preferences = decoded['preferences'];
    return CleaningSnapshot(
      goals: goals,
      tasks: tasks,
      preferences: preferences is Map
          ? _preferencesFromJson(Map<String, dynamic>.from(preferences))
          : const AppPreferences(),
    );
  }

  static Map<String, dynamic> _goalToJson(CleaningGoal goal) => {
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
                'maxEscalationsPerPeriod':
                    goal.reminder!.maxEscalationsPerPeriod,
              },
      };

  static Map<String, dynamic> _taskToJson(CleaningTask task) => {
        'id': task.id,
        'title': task.title,
        'goalId': task.goalId,
        'estimatedMinutes': task.estimatedMinutes,
        'energyLevel': task.energyLevel.name,
        'completions':
            task.completions.map((value) => value.toIso8601String()).toList(),
        'isArchived': task.isArchived,
        'skips': task.skips.map((value) => value.toIso8601String()).toList(),
        'repeatMode': task.repeatMode.name,
      };

  static CleaningGoal _goalFromJson(Map<String, dynamic> json) {
    final schedule = Map<String, dynamic>.from(json['schedule'] as Map? ?? {});
    final reminderJson = json['reminder'];
    final reminder = reminderJson is Map
        ? _reminderFromJson(Map<String, dynamic>.from(reminderJson))
        : null;
    return CleaningGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      room: json['room'] as String,
      cadence: GoalCadence.values.byName(json['cadence'] as String),
      energyLevel: EnergyLevel.values.byName(json['energyLevel'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      schedule: GoalSchedule(
        weekday: schedule['weekday'] as int? ?? DateTime.monday,
        dayOfMonth: schedule['dayOfMonth'] as int? ?? 1,
        month: schedule['month'] as int? ?? 1,
      ),
      reminder: reminder,
    );
  }

  static CleaningTask _taskFromJson(Map<String, dynamic> json) => CleaningTask(
        id: json['id'] as String,
        title: json['title'] as String,
        goalId: json['goalId'] as String,
        estimatedMinutes: json['estimatedMinutes'] as int,
        energyLevel: EnergyLevel.values.byName(json['energyLevel'] as String),
        completions: _dates(json['completions']),
        isArchived: json['isArchived'] as bool? ?? false,
        skips: _dates(json['skips']),
        repeatMode: TaskRepeatMode.values.byName(
          json['repeatMode'] as String? ?? TaskRepeatMode.repeating.name,
        ),
      );

  static GoalReminder _reminderFromJson(Map<String, dynamic> json) =>
      GoalReminder(
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

  static AppPreferences _preferencesFromJson(Map<String, dynamic> json) =>
      AppPreferences(
        theme: AppThemePreference.values
            .byName(json['theme'] as String? ?? 'system'),
        textScale: (json['textScale'] as num?)?.toDouble() ?? 1.0,
        reduceMotion: json['reduceMotion'] as bool? ?? false,
        highContrast: json['highContrast'] as bool? ?? false,
        hapticsEnabled: json['hapticsEnabled'] as bool? ?? true,
      );

  static List<DateTime> _dates(Object? value) => (value as List? ?? [])
      .map((item) => DateTime.parse(item as String))
      .toList();
}
