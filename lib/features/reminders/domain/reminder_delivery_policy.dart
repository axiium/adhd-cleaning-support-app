import '../../settings/domain/app_preferences.dart';

class ReminderDeliveryPolicy {
  const ReminderDeliveryPolicy._();

  static DateTime afterQuietHours(
    DateTime candidate,
    AppPreferences preferences,
  ) {
    if (!preferences.quietHoursEnabled ||
        preferences.quietStartMinute == preferences.quietEndMinute) {
      return candidate;
    }

    final minuteOfDay = candidate.hour * 60 + candidate.minute;
    final start = preferences.quietStartMinute;
    final end = preferences.quietEndMinute;
    final crossesMidnight = start > end;
    final isQuiet = crossesMidnight
        ? minuteOfDay >= start || minuteOfDay < end
        : minuteOfDay >= start && minuteOfDay < end;
    if (!isQuiet) return candidate;

    final endHour = end ~/ 60;
    final endMinute = end % 60;
    final addDay = crossesMidnight && minuteOfDay >= start ? 1 : 0;
    return DateTime(
      candidate.year,
      candidate.month,
      candidate.day + addDay,
      endHour,
      endMinute,
    );
  }

  static bool canEnableReminder({
    required int currentlyEnabled,
    required AppPreferences preferences,
  }) {
    return currentlyEnabled < preferences.maxActiveReminders;
  }
}
