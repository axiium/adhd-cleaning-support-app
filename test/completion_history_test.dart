import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:adhd_cleaning_support/features/history/domain/completion_history.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history is newest first and grouped by local calendar day', () {
    final seeded = CleaningSnapshot.seeded();
    final kitchenTask = seeded.tasks.first;
    final completedTask = CleaningTask(
      id: kitchenTask.id,
      title: kitchenTask.title,
      goalId: kitchenTask.goalId,
      estimatedMinutes: kitchenTask.estimatedMinutes,
      energyLevel: kitchenTask.energyLevel,
      completions: [
        DateTime(2026, 9, 6, 12),
        DateTime(2026, 9, 10, 17, 30),
        DateTime(2026, 9, 11, 9, 15),
      ],
    );

    final history = CompletionHistory.from(
      goals: seeded.goals,
      tasks: [completedTask],
      now: DateTime(2026, 9, 11, 12),
    );

    expect(history.entries, hasLength(3));
    expect(history.entries.first.completedAt.day, 11);
    expect(history.days.map((day) => day.date.day), [11, 10, 6]);
    expect(history.completedToday, 1);
    expect(history.completedThisWeek, 2);
  });
}
