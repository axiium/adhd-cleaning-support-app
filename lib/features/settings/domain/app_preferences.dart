enum AppThemePreference { system, light, dark }

class AppPreferences {
  const AppPreferences({
    this.theme = AppThemePreference.system,
    this.largerText = false,
    this.reduceMotion = false,
  });

  final AppThemePreference theme;
  final bool largerText;
  final bool reduceMotion;

  AppPreferences copyWith({
    AppThemePreference? theme,
    bool? largerText,
    bool? reduceMotion,
  }) {
    return AppPreferences(
      theme: theme ?? this.theme,
      largerText: largerText ?? this.largerText,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }
}
