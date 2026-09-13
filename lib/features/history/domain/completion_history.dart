import '../../goals/domain/cleaning_goal.dart';
import '../../today/domain/cleaning_task.dart';
import '../../../core/domain/cleaning_values.dart';

class CompletionHistoryEntry {
  const CompletionHistoryEntry({
    required this.taskId,
    required this.taskTitle,
    required this.goalTitle,
    required this.room,
    required this.cadence,
    required this.energyLevel,
    required this.estimatedMinutes,
    required this.completedAt,
  });

  final String taskId;
  final String taskTitle;
  final String goalTitle;
  final String room;
  final GoalCadence cadence;
  final EnergyLevel energyLevel;
  final int estimatedMinutes;
  final DateTime completedAt;
}

class CompletionHistoryDay {
  const CompletionHistoryDay({required this.date, required this.entries});

  final DateTime date;
  final List<CompletionHistoryEntry> entries;
}

class CompletionHistory {
  CompletionHistory._({
    required this.entries,
    required this.days,
    required this.completedToday,
    required this.completedThisWeek,
  });

  factory CompletionHistory.from({
    required List<CleaningGoal> goals,
    required List<CleaningTask> tasks,
    required DateTime now,
  }) {
    final goalsById = {for (final goal in goals) goal.id: goal};
    final entries = <CompletionHistoryEntry>[];

    for (final task in tasks) {
      final goal = goalsById[task.goalId];
      for (final completion in task.completions) {
        entries.add(
          CompletionHistoryEntry(
            taskId: task.id,
            taskTitle: task.title,
            goalTitle: goal?.title ?? 'Cleaning goal',
            room: goal?.room ?? '',
            cadence: goal?.cadence ?? GoalCadence.daily,
            energyLevel: task.energyLevel,
            estimatedMinutes: task.estimatedMinutes,
            completedAt: completion.toLocal(),
          ),
        );
      }
    }

    entries.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    final groupedEntries = <DateTime, List<CompletionHistoryEntry>>{};
    for (final entry in entries) {
      final date = _startOfDay(entry.completedAt);
      groupedEntries.putIfAbsent(date, () => []).add(entry);
    }

    final localNow = now.toLocal();
    final today = _startOfDay(localNow);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));

    return CompletionHistory._(
      entries: List.unmodifiable(entries),
      days: List.unmodifiable(
        groupedEntries.entries
            .map(
              (group) => CompletionHistoryDay(
                date: group.key,
                entries: List.unmodifiable(group.value),
              ),
            )
            .toList(),
      ),
      completedToday: entries
          .where((entry) => _startOfDay(entry.completedAt) == today)
          .length,
      completedThisWeek: entries
          .where(
            (entry) => !entry.completedAt.isBefore(weekStart),
          )
          .length,
    );
  }

  final List<CompletionHistoryEntry> entries;
  final List<CompletionHistoryDay> days;
  final int completedToday;
  final int completedThisWeek;

  static DateTime _startOfDay(DateTime time) {
    final localTime = time.toLocal();
    return DateTime(localTime.year, localTime.month, localTime.day);
  }
}
