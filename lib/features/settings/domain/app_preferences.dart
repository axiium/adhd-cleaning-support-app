enum AppThemePreference { system, light, dark }

class AppPreferences {
  const AppPreferences({
    this.theme = AppThemePreference.system,
    this.largerText = false,
    this.reduceMotion = false,
    this.quietHoursEnabled = false,
    this.quietStartMinute = 21 * 60,
    this.quietEndMinute = 8 * 60,
    this.maxActiveReminders = 3,
    this.snoozeMinutes = 30,
  });

  final AppThemePreference theme;
  final bool largerText;
  final bool reduceMotion;
  final bool quietHoursEnabled;
  final int quietStartMinute;
  final int quietEndMinute;
  final int maxActiveReminders;
  final int snoozeMinutes;

  AppPreferences copyWith({
    AppThemePreference? theme,
    bool? largerText,
    bool? reduceMotion,
    bool? quietHoursEnabled,
    int? quietStartMinute,
    int? quietEndMinute,
    int? maxActiveReminders,
    int? snoozeMinutes,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      largerText: largerText ?? this.largerText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartMinute: quietStartMinute ?? this.quietStartMinute,
      quietEndMinute: quietEndMinute ?? this.quietEndMinute,
      maxActiveReminders: maxActiveReminders ?? this.maxActiveReminders,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}
