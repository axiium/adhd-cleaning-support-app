import '../../../core/domain/cleaning_values.dart';
import '../../goals/domain/goal_schedule.dart';

class GoalReminder {
  const GoalReminder({
    required this.hour,
    required this.minute,
    required this.weekday,
    required this.dayOfMonth,
    required this.month,
    this.escalationEnabled = false,
    this.escalateAfterSkips = 3,
    this.escalationDelayMinutes = 60,
    this.maxEscalationsPerPeriod = 2,
  });

  factory GoalReminder.fromLocalTime({
    required int hour,
    required int minute,
    required DateTime referenceDate,
  }) {
    final localDate = referenceDate.toLocal();
    return GoalReminder(
      hour: hour,
      minute: minute,
      weekday: localDate.weekday,
      dayOfMonth: localDate.day,
      month: localDate.month,
    );
  }

  final int hour;
  final int minute;
  final int weekday;
  final int dayOfMonth;
  final int month;
  final bool escalationEnabled;
  final int escalateAfterSkips;
  final int escalationDelayMinutes;
  final int maxEscalationsPerPeriod;

  GoalReminder copyWith({
    int? hour,
    int? minute,
    bool? escalationEnabled,
    int? escalateAfterSkips,
    int? escalationDelayMinutes,
    int? maxEscalationsPerPeriod,
  }) {
    return GoalReminder(
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      weekday: weekday,
      dayOfMonth: dayOfMonth,
      month: month,
      escalationEnabled: escalationEnabled ?? this.escalationEnabled,
      escalateAfterSkips: escalateAfterSkips ?? this.escalateAfterSkips,
      escalationDelayMinutes:
          escalationDelayMinutes ?? this.escalationDelayMinutes,
      maxEscalationsPerPeriod:
          maxEscalationsPerPeriod ?? this.maxEscalationsPerPeriod,
    );
  }

  GoalReminder alignedWith(GoalSchedule schedule) {
    return GoalReminder(
      hour: hour,
      minute: minute,
      weekday: schedule.weekday,
      dayOfMonth: schedule.dayOfMonth,
      month: schedule.month,
      escalationEnabled: escalationEnabled,
      escalateAfterSkips: escalateAfterSkips,
      escalationDelayMinutes: escalationDelayMinutes,
      maxEscalationsPerPeriod: maxEscalationsPerPeriod,
    );
  }

  String describeFor(GoalCadence cadence) {
    final time = _formatTime(hour, minute);
    return switch (cadence) {
      GoalCadence.daily => 'Every day at $time',
      GoalCadence.weekly => '${_weekdayNames[weekday - 1]}s at $time',
      GoalCadence.monthly => 'Day $dayOfMonth of each month at $time',
      GoalCadence.yearly =>
        '${_monthNames[month - 1]} $dayOfMonth each year at $time',
    };
  }

  static String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
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
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
}
