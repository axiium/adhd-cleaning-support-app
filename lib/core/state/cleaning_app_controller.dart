import 'package:flutter/foundation.dart';

import '../../features/goals/domain/cleaning_goal.dart';
import '../../features/reminders/application/reminder_scheduler.dart';
import '../../features/reminders/domain/goal_reminder.dart';
import '../../features/settings/domain/app_preferences.dart';
import '../../features/today/domain/cleaning_task.dart';
import '../persistence/cleaning_repository.dart';

enum ReminderUpdateResult {
  saved,
  permissionDenied,
  schedulingFailed,
  storageFailed,
}

class CleaningAppController extends ChangeNotifier {
  CleaningAppController({
    required CleaningRepository repository,
    ReminderScheduler? reminderScheduler,
    DateTime Function()? now,
  })  : _repository = repository,
        _reminderScheduler = reminderScheduler ?? MemoryReminderScheduler(),
        _now = now ?? DateTime.now;

  final CleaningRepository _repository;
  final ReminderScheduler _reminderScheduler;
  final DateTime Function() _now;
  final List<CleaningGoal> _goals = [];
  final List<CleaningTask> _tasks = [];
  AppPreferences _preferences = const AppPreferences();

  bool _isLoading = true;
  String? _storageWarning;
  String? _reminderWarning;

  List<CleaningGoal> get goals =>
      List.unmodifiable(_goals.where((goal) => !goal.isArchived));
  List<CleaningGoal> get archivedGoals =>
      List.unmodifiable(_goals.where((goal) => goal.isArchived));
  List<CleaningGoal> get allGoals => List.unmodifiable(_goals);
  List<CleaningTask> get tasks => List.unmodifiable(
        _tasks.where((task) {
          if (task.isArchived) return false;
          final goal = goalById(task.goalId);
          return goal != null && !goal.isArchived && goal.isAvailableOn(_now());
        }),
      );
  List<CleaningTask> get activeTasks => List.unmodifiable(
        _tasks.where((task) {
          if (task.isArchived) return false;
          final goal = goalById(task.goalId);
          return goal != null && !goal.isArchived;
        }),
      );
  List<CleaningTask> get archivedTasks => List.unmodifiable(
        _tasks.where((task) {
          if (!task.isArchived) return false;
          final goal = goalById(task.goalId);
          return goal != null && !goal.isArchived;
        }),
      );
  List<CleaningTask> get allTasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get storageWarning => _storageWarning;
  String? get reminderWarning => _reminderWarning;
  DateTime get currentTime => _now().toLocal();
  AppPreferences get preferences => _preferences;

  Future<void> initialize() async {
    try {
      final storedSnapshot = await _repository.load();
      final snapshot = storedSnapshot ?? CleaningSnapshot.seeded();
      _replaceWith(snapshot);

      if (storedSnapshot == null) {
        await _repository.save(snapshot);
      }
    } on Object {
      _replaceWith(CleaningSnapshot.seeded());
      _storageWarning =
          'Saved data could not be loaded. Showing starter goals instead.';
    }

    try {
      await _reminderScheduler.initialize();
      for (final goal in _goals.where(
        (goal) => !goal.isArchived && goal.reminder != null,
      )) {
        await _reminderScheduler.schedule(goal);
      }
    } on Object {
      _reminderWarning =
          'Reminders are unavailable right now. Your goals are still safe.';
    }

    _isLoading = false;
    notifyListeners();
  }

  CleaningGoal? goalById(String id) {
    for (final goal in _goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  List<CleaningTask> tasksForGoal(
    String goalId, {
    bool includeArchived = false,
  }) {
    return _tasks
        .where(
          (task) =>
              task.goalId == goalId && (includeArchived || !task.isArchived),
        )
        .toList();
  }

  bool isTaskComplete(CleaningTask task) {
    final goal = goalById(task.goalId);
    return goal != null && task.isCompleteFor(goal.cadence, _now());
  }

  void refreshForCurrentPeriod() {
    notifyListeners();
  }

  Future<ReminderUpdateResult> setGoalReminder(
    String goalId,
    GoalReminder? reminder,
  ) async {
    final index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index == -1) {
      throw ArgumentError.value(goalId, 'goalId', 'Unknown goal');
    }

    if (reminder != null) {
      try {
        if (!await _reminderScheduler.requestPermission()) {
          return ReminderUpdateResult.permissionDenied;
        }
      } on Object {
        return ReminderUpdateResult.schedulingFailed;
      }
    }

    final previousGoal = _goals[index];
    final updatedGoal = previousGoal.withReminder(reminder);
    _goals[index] = updatedGoal;
    notifyListeners();

    if (!await _persist()) {
      _goals[index] = previousGoal;
      notifyListeners();
      return ReminderUpdateResult.storageFailed;
    }

    try {
      if (reminder == null || updatedGoal.isArchived) {
        await _reminderScheduler.cancel(goalId);
      } else {
        await _reminderScheduler.schedule(updatedGoal);
      }
      _reminderWarning = null;
      notifyListeners();
      return ReminderUpdateResult.saved;
    } on Object {
      _goals[index] = previousGoal;
      await _persist();
      _reminderWarning =
          'That reminder could not be scheduled. Please try again.';
      notifyListeners();
      return ReminderUpdateResult.schedulingFailed;
    }
  }

  Future<ReminderUpdateResult> sendTestReminder(String goalId) async {
    final goal = goalById(goalId);
    if (goal == null) {
      throw ArgumentError.value(goalId, 'goalId', 'Unknown goal');
    }

    try {
      if (!await _reminderScheduler.requestPermission()) {
        return ReminderUpdateResult.permissionDenied;
      }
      await _reminderScheduler.showTest(goal);
      _reminderWarning = null;
      notifyListeners();
      return ReminderUpdateResult.saved;
    } on Object {
      _reminderWarning =
          'That test reminder could not be shown. Please try again.';
      notifyListeners();
      return ReminderUpdateResult.schedulingFailed;
    }
  }

  Future<bool> addGoal(CleaningGoal goal) async {
    _goals.add(goal);
    notifyListeners();
    return _persist();
  }

  Future<bool> updatePreferences(AppPreferences preferences) async {
    final previousPreferences = _preferences;
    _preferences = preferences;
    notifyListeners();
    if (await _persist()) return true;

    _preferences = previousPreferences;
    notifyListeners();
    return false;
  }

  Future<bool> updateGoal(CleaningGoal goal) async {
    final index = _goals.indexWhere((existing) => existing.id == goal.id);
    if (index == -1) {
      throw ArgumentError.value(goal.id, 'goal.id', 'Unknown goal');
    }

    final previousGoal = _goals[index];
    final normalizedGoal = goal.withSchedule(goal.schedule);
    _goals[index] = normalizedGoal;
    notifyListeners();

    if (!await _persist()) {
      _goals[index] = previousGoal;
      notifyListeners();
      return false;
    }

    if (normalizedGoal.reminder != null && !normalizedGoal.isArchived) {
      try {
        await _reminderScheduler.schedule(normalizedGoal);
        _reminderWarning = null;
      } on Object {
        _reminderWarning =
            'The goal was saved, but its reminder could not be updated.';
        notifyListeners();
      }
    }
    return true;
  }

  Future<bool> deleteGoal(String goalId) async {
    final goal = goalById(goalId);
    if (goal == null) return true;

    if (goal.reminder != null) {
      try {
        await _reminderScheduler.cancel(goalId);
      } on Object {
        _reminderWarning =
            'That goal could not be removed because its reminder stayed active.';
        notifyListeners();
        return false;
      }
    }

    final previousGoals = List<CleaningGoal>.of(_goals);
    final previousTasks = List<CleaningTask>.of(_tasks);
    _goals.removeWhere((existing) => existing.id == goalId);
    _tasks.removeWhere((task) => task.goalId == goalId);
    notifyListeners();

    if (await _persist()) return true;

    _goals
      ..clear()
      ..addAll(previousGoals);
    _tasks
      ..clear()
      ..addAll(previousTasks);
    if (goal.reminder != null) {
      try {
        await _reminderScheduler.schedule(goal);
      } on Object {
        _reminderWarning =
            'The goal was restored, but its reminder needs to be enabled again.';
      }
    }
    notifyListeners();
    return false;
  }

  Future<bool> archiveGoal(String goalId) async {
    final index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index == -1 || _goals[index].isArchived) return true;
    final previousGoal = _goals[index];

    if (previousGoal.reminder != null) {
      try {
        await _reminderScheduler.cancel(goalId);
      } on Object {
        _reminderWarning =
            'That goal could not be archived because its reminder stayed active.';
        notifyListeners();
        return false;
      }
    }

    _goals[index] = previousGoal.withArchived(true);
    notifyListeners();
    if (await _persist()) return true;

    _goals[index] = previousGoal;
    if (previousGoal.reminder != null) {
      try {
        await _reminderScheduler.schedule(previousGoal);
      } on Object {
        _reminderWarning =
            'The goal was restored, but its reminder needs attention.';
      }
    }
    notifyListeners();
    return false;
  }

  Future<bool> restoreGoal(String goalId) async {
    final index = _goals.indexWhere((goal) => goal.id == goalId);
    if (index == -1 || !_goals[index].isArchived) return true;
    final previousGoal = _goals[index];
    final restoredGoal = previousGoal.withArchived(false);
    _goals[index] = restoredGoal;
    notifyListeners();
    if (!await _persist()) {
      _goals[index] = previousGoal;
      notifyListeners();
      return false;
    }

    if (restoredGoal.reminder != null) {
      try {
        await _reminderScheduler.schedule(restoredGoal);
        _reminderWarning = null;
      } on Object {
        _reminderWarning =
            'The goal was restored, but its reminder could not be resumed.';
        notifyListeners();
      }
    }
    return true;
  }

  Future<bool> reorderGoals(int oldIndex, int newIndex) async {
    final previousGoals = List<CleaningGoal>.of(_goals);
    final activeGoals = goals.toList();
    if (oldIndex < 0 || oldIndex >= activeGoals.length) return false;
    if (newIndex < 0 || newIndex >= activeGoals.length) return false;
    final moved = activeGoals.removeAt(oldIndex);
    activeGoals.insert(newIndex, moved);
    final activeIterator = activeGoals.iterator;
    for (var index = 0; index < _goals.length; index++) {
      if (!_goals[index].isArchived) {
        activeIterator.moveNext();
        _goals[index] = activeIterator.current;
      }
    }
    notifyListeners();
    if (await _persist()) return true;
    _goals
      ..clear()
      ..addAll(previousGoals);
    notifyListeners();
    return false;
  }

  Future<bool> addTask(CleaningTask task) async {
    if (goalById(task.goalId) == null) {
      throw ArgumentError.value(task.goalId, 'task.goalId', 'Unknown goal');
    }
    _tasks.add(task);
    notifyListeners();
    return _persist();
  }

  Future<bool> updateTask(CleaningTask task) async {
    final index = _tasks.indexWhere((existing) => existing.id == task.id);
    if (index == -1) {
      throw ArgumentError.value(task.id, 'task.id', 'Unknown step');
    }
    if (goalById(task.goalId) == null) {
      throw ArgumentError.value(task.goalId, 'task.goalId', 'Unknown goal');
    }

    final previousTask = _tasks[index];
    _tasks[index] = task;
    notifyListeners();
    if (await _persist()) return true;

    _tasks[index] = previousTask;
    notifyListeners();
    return false;
  }

  Future<bool> deleteTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return true;

    final previousTask = _tasks[index];
    _tasks.removeAt(index);
    notifyListeners();
    if (await _persist()) return true;

    _tasks.insert(index, previousTask);
    notifyListeners();
    return false;
  }

  Future<bool> archiveTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || _tasks[index].isArchived) return true;
    return _replaceTaskAndPersist(index, _tasks[index].withArchived(true));
  }

  Future<bool> restoreTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || !_tasks[index].isArchived) return true;
    return _replaceTaskAndPersist(index, _tasks[index].withArchived(false));
  }

  Future<bool> reorderTasksForGoal(
    String goalId,
    int oldIndex,
    int newIndex,
  ) async {
    final previousTasks = List<CleaningTask>.of(_tasks);
    final indexes = <int>[
      for (var index = 0; index < _tasks.length; index++)
        if (_tasks[index].goalId == goalId && !_tasks[index].isArchived) index,
    ];
    if (oldIndex < 0 || oldIndex >= indexes.length) return false;
    if (newIndex < 0 || newIndex >= indexes.length) return false;
    final ordered = [for (final index in indexes) _tasks[index]];
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    for (var index = 0; index < indexes.length; index++) {
      _tasks[indexes[index]] = ordered[index];
    }
    notifyListeners();
    if (await _persist()) return true;
    _tasks
      ..clear()
      ..addAll(previousTasks);
    notifyListeners();
    return false;
  }

  Future<bool> completeTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || isTaskComplete(_tasks[index])) return true;

    return _replaceTaskAndPersist(index, _tasks[index].completedAt(_now()));
  }

  Future<bool> undoTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || !isTaskComplete(_tasks[index])) return true;

    final task = _tasks[index];
    final goal = goalById(task.goalId);
    if (goal == null) return false;

    return _replaceTaskAndPersist(
      index,
      task.withoutCompletionFor(goal.cadence, _now()),
    );
  }

  Future<bool> toggleTaskCompletion(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1) return false;
    return isTaskComplete(_tasks[index])
        ? undoTaskCompletion(taskId)
        : completeTask(taskId);
  }

  Future<bool> _replaceTaskAndPersist(
    int index,
    CleaningTask replacement,
  ) async {
    final previousTask = _tasks[index];
    _tasks[index] = replacement;
    notifyListeners();
    if (await _persist()) return true;

    _tasks[index] = previousTask;
    notifyListeners();
    return false;
  }

  void _replaceWith(CleaningSnapshot snapshot) {
    _goals
      ..clear()
      ..addAll(snapshot.goals);
    _tasks
      ..clear()
      ..addAll(snapshot.tasks);
    _preferences = snapshot.preferences;
  }

  Future<bool> _persist() async {
    try {
      await _repository.save(
        CleaningSnapshot(
          goals: _goals,
          tasks: _tasks,
          preferences: _preferences,
        ),
      );
      _storageWarning = null;
      return true;
    } on Object {
      _storageWarning =
          'This change is visible now, but it could not be saved.';
      notifyListeners();
      return false;
    }
  }
}
