import 'package:flutter/material.dart';

import '../../../core/state/cleaning_app_scope.dart';
import '../../../core/domain/cleaning_values.dart';
import '../../today/domain/cleaning_task.dart';
import '../domain/completion_history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? _roomFilter;
  _HistoryRange _range = _HistoryRange.all;
  DateTime? _calendarMonth;
  DateTime? _selectedCalendarDay;

  @override
  Widget build(BuildContext context) {
    final controller = CleaningAppScope.of(context);
    final history = CompletionHistory.from(
      goals: controller.allGoals,
      tasks: controller.allTasks,
      now: controller.currentTime,
    );
    final cutoff = _range.cutoff(controller.currentTime);
    final filteredEntries = history.entries.where((entry) {
      final matchesRoom = _roomFilter == null || entry.room == _roomFilter;
      final matchesRange =
          cutoff == null || !entry.completedAt.isBefore(cutoff);
      return matchesRoom && matchesRange;
    }).toList();
    final filteredDays = _groupByDay(filteredEntries);
    final currentDay = _startOfDay(controller.currentTime);
    final calendarMonth =
        _calendarMonth ?? DateTime(currentDay.year, currentDay.month);
    final selectedCalendarDay = _selectedCalendarDay ?? currentDay;
    final selectedDayEntries = history.entries.where((entry) {
      return _startOfDay(entry.completedAt) == selectedCalendarDay;
    }).toList();
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
            const SizedBox(height: 20),
            _MonthCompletionCalendar(
              month: calendarMonth,
              selectedDay: selectedCalendarDay,
              entries: history.entries,
              selectedDayEntries: selectedDayEntries,
              onPreviousMonth: () => setState(() {
                _calendarMonth =
                    DateTime(calendarMonth.year, calendarMonth.month - 1);
                _selectedCalendarDay = null;
              }),
              onNextMonth: () => setState(() {
                _calendarMonth =
                    DateTime(calendarMonth.year, calendarMonth.month + 1);
                _selectedCalendarDay = null;
              }),
              onDaySelected: (day) => setState(() {
                _calendarMonth = DateTime(day.year, day.month);
                _selectedCalendarDay = day;
              }),
            ),
            const SizedBox(height: 20),
            _HistoryFilters(
              rooms: {
                for (final goal in controller.allGoals)
                  if (goal.room.isNotEmpty) goal.room,
              }.toList()
                ..sort(),
              selectedRoom: _roomFilter,
              selectedRange: _range,
              onRoomChanged: (room) => setState(() => _roomFilter = room),
              onRangeChanged: (range) => setState(() => _range = range),
            ),
            const SizedBox(height: 28),
            if (history.entries.isEmpty)
              const _EmptyHistory()
            else if (filteredEntries.isEmpty)
              const _NoMatchingHistory()
            else ...[
              Row(
                children: [
                  Expanded(
                    child: Text('Recent activity',
                        style: theme.textTheme.titleLarge),
                  ),
                  Text(
                    '${filteredEntries.length} ${filteredEntries.length == 1 ? 'completion' : 'completions'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final day in filteredDays) ...[
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
                        _HistoryEntryTile(
                          entry: day.entries[index],
                          onTap: () =>
                              _showDetails(context, day.entries[index]),
                        ),
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

  static DateTime _startOfDay(DateTime time) {
    final local = time.toLocal();
    return DateTime(local.year, local.month, local.day);
  }

  List<CompletionHistoryDay> _groupByDay(
    List<CompletionHistoryEntry> entries,
  ) {
    final groups = <DateTime, List<CompletionHistoryEntry>>{};
    for (final entry in entries) {
      final local = entry.completedAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      groups.putIfAbsent(day, () => []).add(entry);
    }
    return groups.entries
        .map((group) =>
            CompletionHistoryDay(date: group.key, entries: group.value))
        .toList();
  }

  Future<void> _showDetails(
    BuildContext context,
    CompletionHistoryEntry entry,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.taskTitle,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _DetailRow(label: 'Goal', value: entry.goalTitle),
              if (entry.room.isNotEmpty)
                _DetailRow(label: 'Room', value: entry.room),
              _DetailRow(
                label: 'Cadence',
                value: entry.repeatMode == TaskRepeatMode.oneTime
                    ? entry.repeatMode.label
                    : entry.cadence.label,
              ),
              _DetailRow(label: 'Energy', value: entry.energyLevel.label),
              _DetailRow(
                  label: 'Estimated time',
                  value: '${entry.estimatedMinutes} minutes'),
              _DetailRow(
                  label: 'Completed', value: _dateTimeLabel(entry.completedAt)),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateTimeLabel(DateTime time) {
    final localTime = time.toLocal();
    final period = localTime.hour >= 12 ? 'PM' : 'AM';
    final hour = localTime.hour % 12 == 0 ? 12 : localTime.hour % 12;
    final timeLabel =
        '$hour:${localTime.minute.toString().padLeft(2, '0')} $period';
    return '${_dateLabel(localTime, localTime)}, $timeLabel';
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

class _MonthCompletionCalendar extends StatelessWidget {
  const _MonthCompletionCalendar({
    required this.month,
    required this.selectedDay,
    required this.entries,
    required this.selectedDayEntries,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onDaySelected,
  });

  final DateTime month;
  final DateTime selectedDay;
  final List<CompletionHistoryEntry> entries;
  final List<CompletionHistoryEntry> selectedDayEntries;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leadingDays = firstDay.weekday - DateTime.monday;
    final completedDays = {
      for (final entry in entries) _startOfDay(entry.completedAt),
    };
    final cells = <Widget>[];
    for (var index = 0; index < leadingDays; index++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final isSelected = date == _startOfDay(selectedDay);
      final hasCompletion = completedDays.contains(date);
      cells.add(
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => onDaySelected(date),
          child: Container(
            decoration: isSelected
                ? BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  )
                : null,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected ? theme.colorScheme.onPrimary : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
                const SizedBox(height: 3),
                Icon(
                  hasCompletion ? Icons.circle : Icons.circle_outlined,
                  size: 7,
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : hasCompletion
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_HistoryScreenState._monthNames[month.month - 1]} ${month.year}',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            Row(
              children: [
                for (final label in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                  Expanded(
                    child: Center(
                      child: Text(label, style: theme.textTheme.labelSmall),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.15,
              children: cells,
            ),
            const Divider(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_HistoryScreenState._dateLabel(selectedDay, selectedDay)} completions',
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            if (selectedDayEntries.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('No completed goals recorded on this day.'),
              )
            else
              for (final entry in selectedDayEntries)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('${entry.goalTitle} · ${entry.taskTitle}'),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  static DateTime _startOfDay(DateTime time) {
    final local = time.toLocal();
    return DateTime(local.year, local.month, local.day);
  }
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
  const _HistoryEntryTile({required this.entry, required this.onTap});

  final CompletionHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
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

class _HistoryFilters extends StatelessWidget {
  const _HistoryFilters(
      {required this.rooms,
      required this.selectedRoom,
      required this.selectedRange,
      required this.onRoomChanged,
      required this.onRangeChanged});
  final List<String> rooms;
  final String? selectedRoom;
  final _HistoryRange selectedRange;
  final ValueChanged<String?> onRoomChanged;
  final ValueChanged<_HistoryRange> onRangeChanged;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Show activity', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All rooms'),
                selected: selectedRoom == null,
                onSelected: (_) => onRoomChanged(null),
              ),
              for (final room in rooms)
                ChoiceChip(
                  label: Text(room),
                  selected: selectedRoom == room,
                  onSelected: (_) => onRoomChanged(room),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<_HistoryRange>(
            initialValue: selectedRange,
            decoration: const InputDecoration(
                labelText: 'Time window', border: OutlineInputBorder()),
            items: _HistoryRange.values
                .map((range) =>
                    DropdownMenuItem(value: range, child: Text(range.label)))
                .toList(),
            onChanged: (range) {
              if (range != null) onRangeChanged(range);
            },
          ),
          if (selectedRoom != null || selectedRange != _HistoryRange.all)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  onRoomChanged(null);
                  onRangeChanged(_HistoryRange.all);
                },
                icon: const Icon(Icons.clear),
                label: const Text('Clear filters'),
              ),
            ),
        ],
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600))
        ]),
      );
}

class _NoMatchingHistory extends StatelessWidget {
  const _NoMatchingHistory();
  @override
  Widget build(BuildContext context) => Card(
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'No completed steps match these filters. You can widen the window or choose another room.'),
        ),
      );
}

enum _HistoryRange { all, week, month }

extension on _HistoryRange {
  String get label => switch (this) {
        _HistoryRange.all => 'Any time',
        _HistoryRange.week => 'Past 7 days',
        _HistoryRange.month => 'Past 30 days'
      };
  DateTime? cutoff(DateTime now) => switch (this) {
        _HistoryRange.all => null,
        _HistoryRange.week => now.subtract(const Duration(days: 7)),
        _HistoryRange.month => now.subtract(const Duration(days: 30))
      };
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
