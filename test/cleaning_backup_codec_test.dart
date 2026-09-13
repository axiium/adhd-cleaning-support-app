import 'package:adhd_cleaning_support/core/persistence/cleaning_backup_codec.dart';
import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backup codec round-trips goals, steps, and preferences', () {
    final snapshot = CleaningSnapshot.seeded();
    final restored = CleaningBackupCodec.decode(
      CleaningBackupCodec.encode(snapshot),
    );

    expect(restored.goals, hasLength(snapshot.goals.length));
    expect(restored.tasks, hasLength(snapshot.tasks.length));
    expect(restored.goals.first.title, snapshot.goals.first.title);
    expect(restored.tasks.first.title, snapshot.tasks.first.title);
  });

  test('backup codec rejects unrelated clipboard text', () {
    expect(
      () => CleaningBackupCodec.decode('not a cleaning backup'),
      throwsFormatException,
    );
  });
}
