import '../../../core/domain/cleaning_values.dart';
import '../../../core/domain/recurrence_period.dart';

class CleaningTask {
  const CleaningTask({
    required this.id,
    required this.title,
    required this.goalId,
    required this.estimatedMinutes,
    required this.energyLevel,
    this.completions = const [],
  });

  final String id;
  final String title;
  final String goalId;
  final int estimatedMinutes;
  final EnergyLevel energyLevel;
  final List<DateTime> completions;

  bool isCompleteFor(GoalCadence cadence, DateTime now) {
    return completions.any(
      (completion) => isInSameRecurrencePeriod(completion, now, cadence),
    );
  }

  CleaningTask completedAt(DateTime time) {
    return CleaningTask(
      id: id,
      title: title,
      goalId: goalId,
      estimatedMinutes: estimatedMinutes,
      energyLevel: energyLevel,
      completions: List.unmodifiable([...completions, time.toUtc()]),
    );
  }
}
