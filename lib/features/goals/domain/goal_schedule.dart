import '../../../core/domain/cleaning_values.dart';

class GoalSchedule {
  const GoalSchedule({
    this.weekday = DateTime.monday,
    this.dayOfMonth = 1,
    this.month = DateTime.january,
  })  : assert(weekday >= DateTime.monday && weekday <= DateTime.sunday),
        assert(dayOfMonth >= 1 && dayOfMonth <= 31),
        assert(month >= DateTime.january && month <= DateTime.december);

  factory GoalSchedule.fromDate(DateTime date) {
    final localDate = date.toLocal();
    return GoalSchedule(
      weekday: localDate.weekday,
      dayOfMonth: localDate.day,
      month: localDate.month,
    );
  }

  final int weekday;
  final int dayOfMonth;
  final int month;

  bool isAvailableOn(GoalCadence cadence, DateTime date) {
    final localDate = date.toLocal();
    return switch (cadence) {
      GoalCadence.daily => true,
      GoalCadence.weekly => localDate.weekday >= weekday,
      GoalCadence.monthly =>
        localDate.day >= _clampedDay(localDate.year, localDate.month),
      GoalCadence.yearly => !_dateOnly(localDate).isBefore(
          DateTime(
            localDate.year,
            month,
            _clampedDay(localDate.year, month),
          ),
        ),
    };
  }

  String describe(GoalCadence cadence) {
    return switch (cadence) {
      GoalCadence.daily => 'Available every day',
      GoalCadence.weekly =>
        'Available from ${weekdayNames[weekday - 1]} each week',
      GoalCadence.monthly => 'Available from day $dayOfMonth each month',
      GoalCadence.yearly =>
        'Available from ${monthNames[month - 1]} $dayOfMonth each year',
    };
  }

  int _clampedDay(int year, int targetMonth) {
    final lastDay = DateTime(year, targetMonth + 1, 0).day;
    return dayOfMonth > lastDay ? lastDay : dayOfMonth;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static const weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const monthNames = [
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
