import 'package:adhd_cleaning_support/features/goals/domain/goal_deadline.dart';
import 'package:adhd_cleaning_support/features/goals/domain/goal_pacing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pacing spreads remaining tasks across buffered days', () {
    final pacing = GoalPacing.calculate(
      deadline: GoalDeadline(
        date: DateTime(2026, 9, 20),
        bufferDays: 1,
      ),
      remainingTasks: 8,
      now: DateTime(2026, 9, 14, 18),
    );

    expect(pacing.daysAvailable, 6);
    expect(pacing.suggestedToday, 2);
    expect(pacing.deadlinePassed, isFalse);
  });

  test('pacing recalculates instead of carrying an overdue backlog', () {
    final pacing = GoalPacing.calculate(
      deadline: GoalDeadline(
        date: DateTime(2026, 9, 20),
        bufferDays: 1,
      ),
      remainingTasks: 8,
      now: DateTime(2026, 9, 18),
    );

    expect(pacing.daysAvailable, 2);
    expect(pacing.suggestedToday, 4);
  });

  test('a passed deadline does not generate a catch-up target', () {
    final pacing = GoalPacing.calculate(
      deadline: GoalDeadline(date: DateTime(2026, 9, 10)),
      remainingTasks: 4,
      now: DateTime(2026, 9, 11),
    );

    expect(pacing.deadlinePassed, isTrue);
    expect(pacing.suggestedToday, 0);
  });
}
