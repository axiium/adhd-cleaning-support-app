import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/features/goals/domain/goal_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('weekly goals become available on their chosen day', () {
    const schedule = GoalSchedule(weekday: DateTime.friday);

    expect(
      schedule.isAvailableOn(GoalCadence.weekly, DateTime(2026, 9, 10)),
      isFalse,
    );
    expect(
      schedule.isAvailableOn(GoalCadence.weekly, DateTime(2026, 9, 11)),
      isTrue,
    );
    expect(
      schedule.isAvailableOn(GoalCadence.weekly, DateTime(2026, 9, 13)),
      isTrue,
    );
  });

  test('monthly and yearly goals remain available after their chosen date', () {
    const monthly = GoalSchedule(dayOfMonth: 15);
    const yearly = GoalSchedule(month: DateTime.september, dayOfMonth: 12);

    expect(
      monthly.isAvailableOn(GoalCadence.monthly, DateTime(2026, 9, 14)),
      isFalse,
    );
    expect(
      monthly.isAvailableOn(GoalCadence.monthly, DateTime(2026, 9, 30)),
      isTrue,
    );
    expect(
      yearly.isAvailableOn(GoalCadence.yearly, DateTime(2026, 9, 11)),
      isFalse,
    );
    expect(
      yearly.isAvailableOn(GoalCadence.yearly, DateTime(2026, 12, 1)),
      isTrue,
    );
  });

  test('daily goals are always available', () {
    const schedule = GoalSchedule(
      weekday: DateTime.sunday,
      dayOfMonth: 28,
      month: DateTime.december,
    );

    expect(
      schedule.isAvailableOn(GoalCadence.daily, DateTime(2026, 1, 1)),
      isTrue,
    );
  });
}
