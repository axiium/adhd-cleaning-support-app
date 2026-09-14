import 'package:adhd_cleaning_support/core/persistence/cleaning_backup_codec.dart';
import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup codec round-trips goals, steps, and preferences', () {
    final seeded = CleaningSnapshot.seeded();
    final snapshot = CleaningSnapshot(
      goals: seeded.goals,
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
  });

  test('backup codec rejects unrelated clipboard text', () {
    expect(
      () => CleaningBackupCodec.decode('not a cleaning backup'),
      throwsFormatException,
    );
  });
}
