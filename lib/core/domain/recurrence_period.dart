import 'cleaning_values.dart';

bool isInSameRecurrencePeriod(
  DateTime first,
  DateTime second,
  GoalCadence cadence,
) {
  final firstLocal = first.toLocal();
  final secondLocal = second.toLocal();

  return _periodStart(firstLocal, cadence) ==
      _periodStart(secondLocal, cadence);
}

DateTime _periodStart(DateTime moment, GoalCadence cadence) {
  return switch (cadence) {
    GoalCadence.daily => DateTime(moment.year, moment.month, moment.day),
    GoalCadence.weekly => DateTime(
        moment.year,
        moment.month,
        moment.day - (moment.weekday - DateTime.monday),
      ),
    GoalCadence.monthly => DateTime(moment.year, moment.month),
    GoalCadence.yearly => DateTime(moment.year),
  };
}
