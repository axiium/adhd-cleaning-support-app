import 'package:flutter/material.dart';

import '../../../core/state/cleaning_app_scope.dart';
import '../domain/completion_history.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = CleaningAppScope.of(context);
    final history = CompletionHistory.from(
      goals: controller.allGoals,
      tasks: controller.allTasks,
      now: controller.currentTime,
    );
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('History'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('What you have done counts.',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'No streaks to protect. This is simply a record of the steps you took.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            _HistorySummary(history: history),
            const SizedBox(height: 28),
            if (history.entries.isEmpty)
              const _EmptyHistory()
            else ...[
              Text('Recent activity', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              for (final day in history.days) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  child: Text(
                    _dateLabel(day.date, controller.currentTime),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < day.entries.length;
                          index++) ...[
                        _HistoryEntryTile(entry: day.entries[index]),
                        if (index < day.entries.length - 1)
                          const Divider(height: 1, indent: 56),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ],
        ),
      ),
    );
  }

  static String _dateLabel(DateTime date, DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return 'Today';
    if (date == yesterday) return 'Yesterday';
    return '${_weekdayNames[date.weekday - 1]}, '
        '${_monthNames[date.month - 1]} ${date.day}';
  }

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
}

class _HistorySummary extends StatelessWidget {
  const _HistorySummary({required this.history});

  final CompletionHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: _SummaryValue(
                value: history.completedToday,
                label: 'today',
              ),
            ),
            SizedBox(
              height: 48,
              child: VerticalDivider(color: theme.colorScheme.outlineVariant),
            ),
            Expanded(
              child: _SummaryValue(
                value: history.completedThisWeek,
                label: 'this week',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('$value', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _HistoryEntryTile extends StatelessWidget {
  const _HistoryEntryTile({required this.entry});

  final CompletionHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.check_circle_outline_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: Text(entry.taskTitle),
      subtitle: Text(
        entry.room.isEmpty
            ? entry.goalTitle
            : '${entry.goalTitle} · ${entry.room}',
      ),
      trailing: Text(_timeLabel(entry.completedAt)),
    );
  }

  static String _timeLabel(DateTime time) {
    final localTime = time.toLocal();
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
    return '$hour:${localTime.minute.toString().padLeft(2, '0')} $period';
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.spa_outlined, size: 36),
            SizedBox(height: 12),
            Text('Nothing recorded yet — and there is no catching up to do.'),
            SizedBox(height: 8),
            Text('When you finish one small step, it will appear here.'),
          ],
        ),
      ),
    );
  }
}
