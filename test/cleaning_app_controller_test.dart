import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:adhd_cleaning_support/core/state/cleaning_app_controller.dart';
import 'package:adhd_cleaning_support/features/goals/domain/cleaning_goal.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('goals, steps, and completion survive controller recreation', () async {
    final repository = MemoryCleaningRepository.seeded();
    var now = DateTime(2026, 9, 10, 10);
    final firstController = CleaningAppController(
      repository: repository,
      now: () => now,
    );
    await firstController.initialize();

    const goal = CleaningGoal(
      id: 'entryway-clear',
      title: 'Keep the entryway clear',
      room: 'Entryway',
      cadence: GoalCadence.daily,
      energyLevel: EnergyLevel.low,
    );
    const task = CleaningTask(
      id: 'shoes-away',
      title: 'Put away two pairs of shoes',
      goalId: 'entryway-clear',
      estimatedMinutes: 2,
      energyLevel: EnergyLevel.low,
    );

    expect(await firstController.addGoal(goal), isTrue);
    expect(await firstController.addTask(task), isTrue);
    expect(await firstController.completeTask(task.id), isTrue);
    firstController.dispose();

    final restoredController = CleaningAppController(
      repository: repository,
      now: () => now,
    );
    await restoredController.initialize();

    expect(restoredController.goalById(goal.id)?.title, goal.title);
    expect(restoredController.tasksForGoal(goal.id), hasLength(1));
    final restoredTask = restoredController.tasksForGoal(goal.id).single;
    expect(restoredController.isTaskComplete(restoredTask), isTrue);

    now = DateTime(2026, 9, 11, 10);
    expect(restoredController.isTaskComplete(restoredTask), isFalse);
    restoredController.dispose();
  });
}
