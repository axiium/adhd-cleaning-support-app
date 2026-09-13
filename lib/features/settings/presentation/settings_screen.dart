import 'package:flutter/material.dart';

import '../../../core/state/cleaning_app_scope.dart';
import '../domain/app_preferences.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _save(
    BuildContext context,
    AppPreferences preferences,
  ) async {
    final saved = await CleaningAppScope.of(
      context,
    ).updatePreferences(preferences);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('That preference could not be saved. Please try again.'),
        ),
      );
    }
  }

  Future<void> _chooseQuietTime(
    BuildContext context,
    AppPreferences preferences, {
    required bool start,
  }) async {
    final minute =
        start ? preferences.quietStartMinute : preferences.quietEndMinute;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      helpText: start ? 'Quiet hours begin' : 'Quiet hours end',
    );
    if (selected == null || !context.mounted) return;
    final selectedMinute = selected.hour * 60 + selected.minute;
    await _save(
      context,
      start
          ? preferences.copyWith(quietStartMinute: selectedMinute)
          : preferences.copyWith(quietEndMinute: selectedMinute),
    );
  }

  String _timeLabel(BuildContext context, int minute) {
    return TimeOfDay(hour: minute ~/ 60, minute: minute % 60).format(context);
  }

  @override
  Widget build(BuildContext context) {
    final controller = CleaningAppScope.of(context);
    final preferences = controller.preferences;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Make the app easier to use.',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'These choices stay on this device and can be changed anytime.',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            Text('Appearance', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color theme', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    const Text(
                        'Follow your phone or choose a consistent look.'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<AppThemePreference>(
                        showSelectedIcon: false,
                        segments: const [
                          ButtonSegment(
                            value: AppThemePreference.system,
                            label: Text('System'),
                            icon: Icon(Icons.phone_android_rounded),
                          ),
                          ButtonSegment(
                            value: AppThemePreference.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: AppThemePreference.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {preferences.theme},
                        onSelectionChanged: (selection) {
                          _save(
                            context,
                            preferences.copyWith(theme: selection.single),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Comfort', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.text_increase_rounded),
                    title: const Text('Larger text'),
                    subtitle: const Text(
                      'Increase text throughout the app without changing your phone.',
                    ),
                    value: preferences.largerText,
                    onChanged: (enabled) {
                      _save(
                        context,
                        preferences.copyWith(largerText: enabled),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56),
                  SwitchListTile(
                    secondary: const Icon(Icons.motion_photos_off_outlined),
                    title: const Text('Reduce motion'),
                    subtitle: const Text(
                      'Remove page transitions and limit interface animation.',
                    ),
                    value: preferences.reduceMotion,
                    onChanged: (enabled) {
                      _save(
                        context,
                        preferences.copyWith(reduceMotion: enabled),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Text('Gentle reminders', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.bedtime_outlined),
                    title: const Text('Quiet hours'),
                    subtitle: Text(
                      preferences.quietHoursEnabled
                          ? '${_timeLabel(context, preferences.quietStartMinute)} '
                              'to ${_timeLabel(context, preferences.quietEndMinute)}'
                          : 'Off — reminders use their chosen time.',
                    ),
                    value: preferences.quietHoursEnabled,
                    onChanged: (enabled) => _save(
                      context,
                      preferences.copyWith(quietHoursEnabled: enabled),
                    ),
                  ),
                  if (preferences.quietHoursEnabled) ...[
                    const Divider(height: 1, indent: 56),
                    ListTile(
                      leading: const Icon(Icons.nightlight_outlined),
                      title: const Text('Quiet hours begin'),
                      trailing: Text(
                        _timeLabel(context, preferences.quietStartMinute),
                      ),
                      onTap: () => _chooseQuietTime(
                        context,
                        preferences,
                        start: true,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny_outlined),
                      title: const Text('Reminders resume'),
                      trailing: Text(
                        _timeLabel(context, preferences.quietEndMinute),
                      ),
                      onTap: () => _chooseQuietTime(
                        context,
                        preferences,
                        start: false,
                      ),
                    ),
                  ],
                  const Divider(height: 1, indent: 56),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active reminder limit',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Limit how many goals can send notifications.',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: [
                              for (final limit in const [1, 3, 5])
                                ButtonSegment(
                                  value: limit,
                                  label: Text('$limit'),
                                  enabled: limit >=
                                      controller.allGoals
                                          .where(
                                            (goal) => goal.reminder != null,
                                          )
                                          .length,
                                ),
                            ],
                            selected: {preferences.maxActiveReminders},
                            onSelectionChanged: (selection) => _save(
                              context,
                              preferences.copyWith(
                                maxActiveReminders: selection.single,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 56),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Snooze length',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: 4),
                        const Text(
                          'Choose how long the Snooze action waits.',
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<int>(
                            showSelectedIcon: false,
                            segments: const [
                              ButtonSegment(value: 15, label: Text('15 min')),
                              ButtonSegment(value: 30, label: Text('30 min')),
                              ButtonSegment(value: 60, label: Text('1 hour')),
                            ],
                            selected: {preferences.snoozeMinutes},
                            onSelectionChanged: (selection) => _save(
                              context,
                              preferences.copyWith(
                                snoozeMinutes: selection.single,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Quiet hours, snooze length, and the active reminder limit apply to all reminders. Repeated-skip persistence is customized inside each goal after its reminder is turned on.',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
