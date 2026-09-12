import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/persistence/cleaning_repository.dart';
import 'core/persistence/shared_preferences_cleaning_repository.dart';
import 'core/state/cleaning_app_controller.dart';
import 'core/state/cleaning_app_scope.dart';
import 'features/reminders/application/reminder_scheduler.dart';
import 'features/reminders/infrastructure/local_notification_reminder_scheduler.dart';
import 'features/settings/domain/app_preferences.dart';
import 'home_shell.dart';

class CleaningSupportApp extends StatefulWidget {
  const CleaningSupportApp({
    this.repository,
    this.reminderScheduler,
    this.now,
    super.key,
  });

  final CleaningRepository? repository;
  final ReminderScheduler? reminderScheduler;
  final DateTime Function()? now;

  @override
  State<CleaningSupportApp> createState() => _CleaningSupportAppState();
}

class _CleaningSupportAppState extends State<CleaningSupportApp>
    with WidgetsBindingObserver {
  late final CleaningAppController _controller;
  late final DateTime Function() _now;
  Timer? _calendarRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _now = widget.now ?? DateTime.now;
    _controller = CleaningAppController(
      repository: widget.repository ?? SharedPreferencesCleaningRepository(),
      reminderScheduler:
          widget.reminderScheduler ?? LocalNotificationReminderScheduler(),
      now: _now,
    );
    _controller.initialize();
    _scheduleCalendarRefresh();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.refreshForCurrentPeriod();
      _scheduleCalendarRefresh();
    }
  }

  void _scheduleCalendarRefresh() {
    _calendarRefreshTimer?.cancel();

    final now = _now().toLocal();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    _calendarRefreshTimer = Timer(nextDay.difference(now), () {
      if (!mounted) return;
      _controller.refreshForCurrentPeriod();
      _scheduleCalendarRefresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _calendarRefreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CleaningAppScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final preferences = _controller.preferences;
          return MaterialApp(
            title: 'Cleaning Support',
            debugShowCheckedModeBanner: false,
            theme: _buildTheme(Brightness.light, preferences.reduceMotion),
            darkTheme: _buildTheme(Brightness.dark, preferences.reduceMotion),
            themeMode: switch (preferences.theme) {
              AppThemePreference.system => ThemeMode.system,
              AppThemePreference.light => ThemeMode.light,
              AppThemePreference.dark => ThemeMode.dark,
            },
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final systemScale = mediaQuery.textScaler.scale(1);
              final preferredScale =
                  systemScale * (preferences.largerText ? 1.15 : 1);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(preferredScale),
                  disableAnimations:
                      mediaQuery.disableAnimations || preferences.reduceMotion,
                ),
                child: child!,
              );
            },
            home: const HomeShell(),
          );
        },
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness, bool reduceMotion) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF526E5B),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F7F2)
          : colorScheme.surface,
      appBarTheme: AppBarTheme(
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      pageTransitionsTheme: reduceMotion
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: _NoPageTransitionsBuilder(),
                TargetPlatform.iOS: _NoPageTransitionsBuilder(),
                TargetPlatform.macOS: _NoPageTransitionsBuilder(),
                TargetPlatform.windows: _NoPageTransitionsBuilder(),
                TargetPlatform.linux: _NoPageTransitionsBuilder(),
                TargetPlatform.fuchsia: _NoPageTransitionsBuilder(),
              },
            )
          : const PageTransitionsTheme(),
    );
  }
}

class _NoPageTransitionsBuilder extends PageTransitionsBuilder {
  const _NoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
