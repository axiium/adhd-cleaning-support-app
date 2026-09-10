import 'package:flutter/foundation.dart';

import '../../features/goals/domain/cleaning_goal.dart';
import '../../features/today/domain/cleaning_task.dart';
import '../persistence/cleaning_repository.dart';

class CleaningAppController extends ChangeNotifier {
  CleaningAppController({
    required CleaningRepository repository,
    DateTime Function()? now,
  })  : _repository = repository,
        _now = now ?? DateTime.now;

  final CleaningRepository _repository;
  final DateTime Function() _now;
  final List<CleaningGoal> _goals = [];
  final List<CleaningTask> _tasks = [];

  bool _isLoading = true;
  String? _storageWarning;

  List<CleaningGoal> get goals => List.unmodifiable(_goals);
  List<CleaningTask> get tasks => List.unmodifiable(_tasks);
  bool get isLoading => _isLoading;
  String? get storageWarning => _storageWarning;

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
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  CleaningGoal? goalById(String id) {
    for (final goal in _goals) {
      if (goal.id == id) return goal;
    }
    return null;
  }

  List<CleaningTask> tasksForGoal(String goalId) {
    return _tasks.where((task) => task.goalId == goalId).toList();
  }

  bool isTaskComplete(CleaningTask task) {
    final goal = goalById(task.goalId);
    return goal != null && task.isCompleteFor(goal.cadence, _now());
  }

  Future<bool> addGoal(CleaningGoal goal) async {
    _goals.add(goal);
    notifyListeners();
    return _persist();
  }

  Future<bool> addTask(CleaningTask task) async {
    if (goalById(task.goalId) == null) {
      throw ArgumentError.value(task.goalId, 'task.goalId', 'Unknown goal');
    }
    _tasks.add(task);
    notifyListeners();
    return _persist();
  }

  Future<bool> completeTask(String taskId) async {
    final index = _tasks.indexWhere((task) => task.id == taskId);
    if (index == -1 || isTaskComplete(_tasks[index])) return true;

    _tasks[index] = _tasks[index].completedAt(_now());
    notifyListeners();
    return _persist();
  }

  void _replaceWith(CleaningSnapshot snapshot) {
    _goals
      ..clear()
      ..addAll(snapshot.goals);
    _tasks
      ..clear()
      ..addAll(snapshot.tasks);
  }

  Future<bool> _persist() async {
    try {
      await _repository.save(CleaningSnapshot(goals: _goals, tasks: _tasks));
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
