import 'package:flutter/material.dart';

import 'core/persistence/cleaning_repository.dart';
import 'core/persistence/shared_preferences_cleaning_repository.dart';
import 'core/state/cleaning_app_controller.dart';
import 'core/state/cleaning_app_scope.dart';
import 'home_shell.dart';

class CleaningSupportApp extends StatefulWidget {
  const CleaningSupportApp({this.repository, super.key});

  final CleaningRepository? repository;

  @override
  State<CleaningSupportApp> createState() => _CleaningSupportAppState();
}

class _CleaningSupportAppState extends State<CleaningSupportApp> {
  late final CleaningAppController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CleaningAppController(
      repository: widget.repository ?? SharedPreferencesCleaningRepository(),
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF526E5B),
      brightness: Brightness.light,
    );

    return CleaningAppScope(
      controller: _controller,
      child: MaterialApp(
        title: 'Cleaning Support',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: colorScheme,
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF7F7F2),
          cardTheme: const CardThemeData(
            elevation: 0,
            margin: EdgeInsets.zero,
          ),
        ),
        home: const HomeShell(),
      ),
    );
  }
}
