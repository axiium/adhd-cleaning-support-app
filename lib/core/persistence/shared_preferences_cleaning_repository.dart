import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/goals/domain/cleaning_goal.dart';
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
  static const _schemaVersion = 2;

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
    if (version != 1 && version != _schemaVersion) {
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
    );
  }

  @override
  Future<void> save(CleaningSnapshot snapshot) {
    final encoded = jsonEncode({
      'version': _schemaVersion,
      'goals': snapshot.goals.map(_goalToJson).toList(),
      'tasks': snapshot.tasks.map(_taskToJson).toList(),
    });
    return _preferences.setString(_storageKey, encoded);
  }

  Map<String, Object?> _goalToJson(CleaningGoal goal) {
    return {
      'id': goal.id,
      'title': goal.title,
      'room': goal.room,
      'cadence': goal.cadence.name,
      'energyLevel': goal.energyLevel.name,
    };
  }

  CleaningGoal _goalFromJson(Map<String, dynamic> json) {
    return CleaningGoal(
      id: json['id'] as String,
      title: json['title'] as String,
      room: json['room'] as String,
      cadence: GoalCadence.values.byName(json['cadence'] as String),
      energyLevel: EnergyLevel.values.byName(json['energyLevel'] as String),
    );
  }

  Map<String, Object?> _taskToJson(CleaningTask task) {
    return {
      'id': task.id,
      'title': task.title,
      'goalId': task.goalId,
      'estimatedMinutes': task.estimatedMinutes,
      'energyLevel': task.energyLevel.name,
      'completions': task.completions
          .map((completion) => completion.toUtc().toIso8601String())
          .toList(),
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

    return CleaningTask(
      id: json['id'] as String,
      title: json['title'] as String,
      goalId: json['goalId'] as String,
      estimatedMinutes: json['estimatedMinutes'] as int,
      energyLevel: EnergyLevel.values.byName(json['energyLevel'] as String),
      completions: completions,
    );
  }
}
