import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const task = CleaningTask(
    id: 'test-step',
    title: 'Test step',
    goalId: 'test-goal',
    estimatedMinutes: 2,
    energyLevel: EnergyLevel.low,
  );

  test('daily completion becomes due the next day', () {
    final completed = task.completedAt(DateTime(2026, 9, 10, 12));

    expect(
      completed.isCompleteFor(
        GoalCadence.daily,
        DateTime(2026, 9, 10, 23),
      ),
      isTrue,
    );
    expect(
      completed.isCompleteFor(
        GoalCadence.daily,
        DateTime(2026, 9, 11),
      ),
      isFalse,
    );
  });

  test('weekly completion uses a Monday boundary', () {
    final completed = task.completedAt(DateTime(2026, 9, 7, 12));

    expect(
      completed.isCompleteFor(
        GoalCadence.weekly,
        DateTime(2026, 9, 13, 23),
      ),
      isTrue,
    );
    expect(
      completed.isCompleteFor(
        GoalCadence.weekly,
        DateTime(2026, 9, 14),
      ),
      isFalse,
    );
  });

  test('monthly completion becomes due next month', () {
    final completed = task.completedAt(DateTime(2026, 9, 30, 12));

    expect(
      completed.isCompleteFor(
        GoalCadence.monthly,
        DateTime(2026, 9, 30, 23),
      ),
      isTrue,
    );
    expect(
      completed.isCompleteFor(
        GoalCadence.monthly,
        DateTime(2026, 10, 1),
      ),
      isFalse,
    );
  });

  test('yearly completion becomes due next year', () {
    final completed = task.completedAt(DateTime(2026, 12, 31, 12));

    expect(
      completed.isCompleteFor(
        GoalCadence.yearly,
        DateTime(2026, 12, 31, 23),
      ),
      isTrue,
    );
    expect(
      completed.isCompleteFor(
        GoalCadence.yearly,
        DateTime(2027, 1, 1),
      ),
      isFalse,
    );
  });
}
