import 'package:adhd_cleaning_support/core/persistence/cleaning_backup_codec.dart';
import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/features/goals/domain/cleaning_goal.dart';
import 'package:adhd_cleaning_support/features/goals/domain/goal_deadline.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup codec round-trips goals, steps, and preferences', () {
    final seeded = CleaningSnapshot.seeded();
    final snapshot = CleaningSnapshot(
      goals: [
        ...seeded.goals,
        CleaningGoal(
          id: 'house-projects',
          title: 'Finish house projects',
          room: 'Whole home',
          cadence: GoalCadence.weekly,
          energyLevel: EnergyLevel.medium,
          deadline: GoalDeadline(
            date: DateTime(2026, 10, 1),
            bufferDays: 2,
          ),
        ),
      ],
      tasks: [
        ...seeded.tasks,
        const CleaningTask(
          id: 'hang-shelf',
          title: 'Hang a shelf',
          goalId: 'kitchen-usable',
          estimatedMinutes: 15,
          energyLevel: EnergyLevel.high,
          repeatMode: TaskRepeatMode.oneTime,
        ),
        const CleaningTask(
          id: 'fix-faucet',
          title: 'Fix the leaky faucet',
          goalId: 'house-projects',
          estimatedMinutes: 30,
          energyLevel: EnergyLevel.medium,
          repeatMode: TaskRepeatMode.oneTime,
        ),
      ],
      preferences: seeded.preferences,
    );
    final restored = CleaningBackupCodec.decode(
      CleaningBackupCodec.encode(snapshot),
    );

    expect(restored.goals, hasLength(snapshot.goals.length));
    expect(restored.tasks, hasLength(snapshot.tasks.length));
    expect(restored.goals.first.title, snapshot.goals.first.title);
    expect(restored.tasks.first.title, snapshot.tasks.first.title);
    expect(restored.tasks.last.repeatMode, TaskRepeatMode.oneTime);
    expect(restored.goals.last.deadline?.bufferDays, 2);
    expect(restored.goals.last.deadline?.date, DateTime(2026, 10, 1));
  });

  test('backup codec rejects unrelated clipboard text', () {
    expect(
      () => CleaningBackupCodec.decode('not a cleaning backup'),
      throwsFormatException,
    );
  });
}
