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
    this.isArchived = false,
    this.skips = const [],
  });

  final String id;
  final String title;
  final String goalId;
  final int estimatedMinutes;
  final EnergyLevel energyLevel;
  final List<DateTime> completions;
  final bool isArchived;
  final List<DateTime> skips;

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
      isArchived: isArchived,
      skips: skips,
    );
  }

  CleaningTask withoutCompletionFor(GoalCadence cadence, DateTime time) {
    return CleaningTask(
      id: id,
      title: title,
      goalId: goalId,
      estimatedMinutes: estimatedMinutes,
      energyLevel: energyLevel,
      completions: List.unmodifiable(
        completions.where(
          (completion) => !isInSameRecurrencePeriod(
            completion,
            time,
            cadence,
          ),
        ),
      ),
      isArchived: isArchived,
      skips: skips,
    );
  }

  CleaningTask withArchived(bool isArchived) {
    return CleaningTask(
      id: id,
      title: title,
      goalId: goalId,
      estimatedMinutes: estimatedMinutes,
      energyLevel: energyLevel,
      completions: completions,
      isArchived: isArchived,
      skips: skips,
    );
  }

  CleaningTask skippedAt(DateTime time) {
    return CleaningTask(
      id: id,
      title: title,
      goalId: goalId,
      estimatedMinutes: estimatedMinutes,
      energyLevel: energyLevel,
      completions: completions,
      isArchived: isArchived,
      skips: List.unmodifiable([...skips, time.toUtc()]),
    );
  }

  int skipsInPeriod(GoalCadence cadence, DateTime now) {
    return skips
        .where(
          (skip) => isInSameRecurrencePeriod(skip, now, cadence),
        )
        .length;
  }
}
