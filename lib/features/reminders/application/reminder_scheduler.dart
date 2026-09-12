import '../../goals/domain/cleaning_goal.dart';

abstract interface class ReminderScheduler {
  Future<void> initialize();

  Future<bool> requestPermission();

  Future<void> schedule(CleaningGoal goal);

  Future<void> showTest(CleaningGoal goal);

  Future<void> cancel(String goalId);
}

class MemoryReminderScheduler implements ReminderScheduler {
  MemoryReminderScheduler({this.permissionGranted = true});

  bool permissionGranted;
  final List<String> scheduledGoalIds = [];
  final List<String> shownTestGoalIds = [];
  final List<String> cancelledGoalIds = [];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<void> schedule(CleaningGoal goal) async {
    scheduledGoalIds.add(goal.id);
  }

  @override
  Future<void> showTest(CleaningGoal goal) async {
    shownTestGoalIds.add(goal.id);
  }

  @override
  Future<void> cancel(String goalId) async {
    cancelledGoalIds.add(goalId);
  }
}
