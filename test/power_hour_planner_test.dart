import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/features/power_hour/domain/power_hour_planner.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tasks = [
    CleaningTask(
      id: 'thirty',
      title: 'Mow the back lawn',
      goalId: 'outside',
      estimatedMinutes: 30,
      energyLevel: EnergyLevel.medium,
    ),
    CleaningTask(
      id: 'twenty',
      title: 'Sort one storage bin',
      goalId: 'storage',
      estimatedMinutes: 20,
      energyLevel: EnergyLevel.low,
    ),
    CleaningTask(
      id: 'fifteen-high',
      title: 'Move a shelf',
      goalId: 'bedroom',
      estimatedMinutes: 15,
      energyLevel: EnergyLevel.high,
    ),
    CleaningTask(
      id: 'five',
      title: 'Clear one surface',
      goalId: 'kitchen',
      estimatedMinutes: 5,
      energyLevel: EnergyLevel.low,
    ),
  ];

  test('plan leaves breathing room and respects the energy ceiling', () {
    final plan = PowerHourPlanner.build(
      tasks: tasks,
      availableMinutes: 60,
      maxEnergy: EnergyLevel.medium,
    );

    expect(plan.plannedMinutes, 50);
    expect(plan.plannedMinutes, lessThanOrEqualTo(51));
    expect(plan.tasks.map((task) => task.id), isNot(contains('fifteen-high')));
    expect(plan.openMinutes, 10);
  });

  test('one fitting task is offered when the comfort buffer is too small', () {
    final plan = PowerHourPlanner.build(
      tasks: [tasks[2]],
      availableMinutes: 15,
      maxEnergy: EnergyLevel.high,
    );

    expect(plan.tasks.single.id, 'fifteen-high');
    expect(plan.plannedMinutes, 15);
    expect(plan.openMinutes, 0);
  });
}
