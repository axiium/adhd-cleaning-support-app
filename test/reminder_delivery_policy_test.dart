import 'package:adhd_cleaning_support/features/reminders/domain/reminder_delivery_policy.dart';
import 'package:adhd_cleaning_support/features/settings/domain/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const overnightQuietHours = AppPreferences(
    quietHoursEnabled: true,
    quietStartMinute: 21 * 60,
    quietEndMinute: 8 * 60,
  );

  test('an evening reminder waits until quiet hours end', () {
    final adjusted = ReminderDeliveryPolicy.afterQuietHours(
      DateTime(2026, 9, 12, 22, 30),
      overnightQuietHours,
    );

    expect(adjusted, DateTime(2026, 9, 13, 8));
  });

  test('a morning reminder waits until quiet hours end that morning', () {
    final adjusted = ReminderDeliveryPolicy.afterQuietHours(
      DateTime(2026, 9, 12, 7, 30),
      overnightQuietHours,
    );

    expect(adjusted, DateTime(2026, 9, 12, 8));
  });

  test('a daytime reminder is unchanged', () {
    final candidate = DateTime(2026, 9, 12, 14);

    expect(
      ReminderDeliveryPolicy.afterQuietHours(
        candidate,
        overnightQuietHours,
      ),
      candidate,
    );
  });
}
