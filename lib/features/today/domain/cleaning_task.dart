import '../../../core/domain/cleaning_values.dart';
import '../../../core/domain/recurrence_period.dart';

enum TaskRepeatMode { repeating, oneTime }

extension TaskRepeatModeLabel on TaskRepeatMode {
  String get label => switch (this) {
        TaskRepeatMode.repeating => 'Repeating',
        TaskRepeatMode.oneTime => 'One-time',
      };
}

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
    this.repeatMode = TaskRepeatMode.repeating,
  });

  final String id;
  final String title;
  final String goalId;
  final int estimatedMinutes;
  final EnergyLevel energyLevel;
  final List<DateTime> completions;
  final bool isArchived;
  final List<DateTime> skips;
  final TaskRepeatMode repeatMode;

  bool isCompleteFor(GoalCadence cadence, DateTime now) {
    if (repeatMode == TaskRepeatMode.oneTime) return completions.isNotEmpty;
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
      repeatMode: repeatMode,
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
        repeatMode == TaskRepeatMode.oneTime
            ? const <DateTime>[]
            : completions.where(
                (completion) => !isInSameRecurrencePeriod(
                  completion,
                  time,
                  cadence,
                ),
              ),
      ),
      isArchived: isArchived,
      skips: skips,
      repeatMode: repeatMode,
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
      repeatMode: repeatMode,
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
      repeatMode: repeatMode,
    );
  }

  int skipsInPeriod(GoalCadence cadence, DateTime now) {
    if (repeatMode == TaskRepeatMode.oneTime) return skips.length;
    return skips
        .where(
          (skip) => isInSameRecurrencePeriod(skip, now, cadence),
        )
        .length;
  }
}
