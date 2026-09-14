import 'goal_deadline.dart';

class GoalPacing {
  const GoalPacing({
    required this.remainingTasks,
    required this.suggestedToday,
    required this.daysAvailable,
    required this.deadlinePassed,
  });

  factory GoalPacing.calculate({
    required GoalDeadline deadline,
    required int remainingTasks,
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final deadlinePassed = today.isAfter(deadline.date);
    if (remainingTasks == 0 || deadlinePassed) {
      return GoalPacing(
        remainingTasks: remainingTasks,
        suggestedToday: 0,
        daysAvailable: 0,
        deadlinePassed: deadlinePassed,
      );
    }

    final target =
        deadline.targetDate.isBefore(today) ? today : deadline.targetDate;
    final daysAvailable = target.difference(today).inDays + 1;
    return GoalPacing(
      remainingTasks: remainingTasks,
      suggestedToday: (remainingTasks / daysAvailable).ceil(),
      daysAvailable: daysAvailable,
      deadlinePassed: false,
    );
  }

  final int remainingTasks;
  final int suggestedToday;
  final int daysAvailable;
  final bool deadlinePassed;
}
