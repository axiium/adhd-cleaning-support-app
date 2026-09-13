enum AppThemePreference { system, light, dark }

class AppPreferences {
  const AppPreferences({
    this.theme = AppThemePreference.system,
    double? textScale,
    bool? largerText,
    this.reduceMotion = false,
    this.highContrast = false,
    this.hapticsEnabled = true,
    this.quietHoursEnabled = false,
    this.quietStartMinute = 21 * 60,
    this.quietEndMinute = 8 * 60,
    this.maxActiveReminders = 3,
    this.snoozeMinutes = 30,
  }) : textScale = textScale ?? (largerText == true ? 1.15 : 1.0);

  final AppThemePreference theme;
  final double textScale;
  final bool reduceMotion;
  final bool highContrast;
  final bool hapticsEnabled;
  final bool quietHoursEnabled;
  final int quietStartMinute;
  final int quietEndMinute;
  final int maxActiveReminders;
  final int snoozeMinutes;

  bool get largerText => textScale > 1.0;

  AppPreferences copyWith({
    AppThemePreference? theme,
    double? textScale,
    bool? reduceMotion,
    bool? highContrast,
    bool? hapticsEnabled,
    bool? quietHoursEnabled,
    int? quietStartMinute,
    int? quietEndMinute,
    int? maxActiveReminders,
    int? snoozeMinutes,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      textScale: textScale ?? this.textScale,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      highContrast: highContrast ?? this.highContrast,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartMinute: quietStartMinute ?? this.quietStartMinute,
      quietEndMinute: quietEndMinute ?? this.quietEndMinute,
      maxActiveReminders: maxActiveReminders ?? this.maxActiveReminders,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
    );
  }
}
