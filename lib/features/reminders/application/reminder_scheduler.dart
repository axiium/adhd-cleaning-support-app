import '../../goals/domain/cleaning_goal.dart';
import '../../settings/domain/app_preferences.dart';
import '../../today/domain/cleaning_task.dart';

abstract interface class ReminderScheduler {
  Future<void> initialize();

  Future<void> configure(AppPreferences preferences);

  Future<bool> requestPermission();

  Future<void> schedule(CleaningGoal goal);

  Future<void> scheduleEscalation(
    CleaningGoal goal,
    CleaningTask task,
    DateTime scheduledDate,
    int occurrence,
  );

  Future<void> showTest(CleaningGoal goal);

  Future<void> cancel(String goalId);

  Future<void> cancelEscalations(String taskId);
}

class MemoryReminderScheduler implements ReminderScheduler {
  MemoryReminderScheduler({this.permissionGranted = true});

  bool permissionGranted;
  final List<String> scheduledGoalIds = [];
  final List<String> shownTestGoalIds = [];
  final List<String> cancelledGoalIds = [];
  final List<String> escalatedTaskIds = [];
  final List<String> cancelledEscalationTaskIds = [];
  AppPreferences configuredPreferences = const AppPreferences();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> configure(AppPreferences preferences) async {
    configuredPreferences = preferences;
  }

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
  Future<void> scheduleEscalation(
    CleaningGoal goal,
    CleaningTask task,
    DateTime scheduledDate,
    int occurrence,
  ) async {
    escalatedTaskIds.add(task.id);
  }

  @override
  Future<void> cancel(String goalId) async {
    cancelledGoalIds.add(goalId);
  }

  @override
  Future<void> cancelEscalations(String taskId) async {
    cancelledEscalationTaskIds.add(taskId);
  }
}
