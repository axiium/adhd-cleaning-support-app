import '../../today/domain/cleaning_task.dart';
import '../../../core/domain/cleaning_values.dart';

class PowerHourPlan {
  const PowerHourPlan({
    required this.tasks,
    required this.availableMinutes,
    required this.plannedMinutes,
  });

  final List<CleaningTask> tasks;
  final int availableMinutes;
  final int plannedMinutes;

  int get openMinutes => availableMinutes - plannedMinutes;
}

class PowerHourPlanner {
  const PowerHourPlanner._();

  static PowerHourPlan build({
    required List<CleaningTask> tasks,
    required int availableMinutes,
    required EnergyLevel maxEnergy,
  }) {
    final candidates = tasks
        .where(
          (task) =>
              task.energyLevel.index <= maxEnergy.index &&
              task.estimatedMinutes <= availableMinutes,
        )
        .toList();
    final comfortBudget = (availableMinutes * 0.85).floor();
    final selected = _bestFit(candidates, comfortBudget);

    if (selected.isEmpty && candidates.isNotEmpty) {
      candidates.sort(
        (a, b) => a.estimatedMinutes.compareTo(b.estimatedMinutes),
      );
      selected.add(candidates.first);
    }

    final plannedMinutes = selected.fold<int>(
      0,
      (total, task) => total + task.estimatedMinutes,
    );
    return PowerHourPlan(
      tasks: List.unmodifiable(selected),
      availableMinutes: availableMinutes,
      plannedMinutes: plannedMinutes,
    );
  }

  static List<CleaningTask> _bestFit(
    List<CleaningTask> candidates,
    int budget,
  ) {
    final plans = List<List<CleaningTask>?>.filled(budget + 1, null);
    plans[0] = <CleaningTask>[];
    for (final task in candidates) {
      for (var minute = budget; minute >= task.estimatedMinutes; minute--) {
        final previous = plans[minute - task.estimatedMinutes];
        if (previous != null && plans[minute] == null) {
          plans[minute] = [...previous, task];
        }
      }
    }
    for (var minute = budget; minute >= 0; minute--) {
      final plan = plans[minute];
      if (plan != null && plan.isNotEmpty) return plan;
    }
    return <CleaningTask>[];
  }
}
