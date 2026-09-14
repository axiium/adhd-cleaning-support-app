import 'package:flutter/material.dart';

import '../../../core/domain/cleaning_values.dart';
import '../../../core/state/cleaning_app_scope.dart';
import '../../goals/domain/cleaning_goal.dart';
import '../../goals/domain/goal_schedule.dart';
import '../../goals/domain/starter_templates.dart';
import '../../today/domain/cleaning_task.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.addToExisting = false, super.key});

  final bool addToExisting;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _selectedRooms = <String>{'Kitchen'};
  EnergyLevel _energy = EnergyLevel.low;
  final _selectedTemplates = <String>{starterTemplates.first.title};

  bool _alreadyAdded(StarterTemplate template) {
    if (!widget.addToExisting) return false;
    return CleaningAppScope.of(context).allGoals.any(
          (goal) => goal.title == template.title && goal.room == template.room,
        );
  }

  Future<void> _finish({bool skip = false}) async {
    if (widget.addToExisting && skip) {
      Navigator.of(context).pop(false);
      return;
    }
    final controller = CleaningAppScope.of(context);
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final chosen = skip
        ? <StarterTemplate>[]
        : starterTemplates
            .where((template) =>
                _selectedRooms.contains(template.room) &&
                _selectedTemplates.contains(template.title) &&
                (!widget.addToExisting || !_alreadyAdded(template)))
            .toList();
    final goals = <CleaningGoal>[];
    final tasks = <CleaningTask>[];
    for (var goalIndex = 0; goalIndex < chosen.length; goalIndex++) {
      final template = chosen[goalIndex];
      final goalId = 'onboarding-goal-$suffix-$goalIndex';
      goals.add(
        CleaningGoal(
          id: goalId,
          title: template.title,
          room: template.room,
          cadence: template.cadence,
          energyLevel: template.energyLevel,
          schedule: GoalSchedule.fromDate(controller.currentTime),
        ),
      );
      for (var stepIndex = 0; stepIndex < template.steps.length; stepIndex++) {
        final step = template.steps[stepIndex];
        tasks.add(
          CleaningTask(
            id: 'onboarding-step-$suffix-$goalIndex-$stepIndex',
            title: step.title,
            goalId: goalId,
            estimatedMinutes: step.estimatedMinutes,
            energyLevel: step.energyLevel,
          ),
        );
      }
    }
    final saved = widget.addToExisting
        ? await controller.addGuidedSetup(goals, tasks)
        : await controller.finishOnboarding(goals, tasks);
    if (!mounted) return;
    if (saved) {
      if (widget.addToExisting) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {});
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That setup could not be saved. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rooms = starterTemplates.map((template) => template.room).toSet();
    return Scaffold(
      appBar: widget.addToExisting
          ? AppBar(title: const Text('Guided setup'))
          : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          children: [
            Icon(Icons.spa_outlined,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
                widget.addToExisting
                    ? 'Add another gentle starting point.'
                    : 'Let’s make this easier to begin.',
                style: theme.textTheme.headlineMedium),
            const SizedBox(height: 12),
            Text(
              widget.addToExisting
                  ? 'Choose more rooms and starter goals. This adds to your current setup without replacing anything.'
                  : 'This setup creates a small, editable pool of goals and steps so the app can offer one manageable place to begin.',
            ),
            const SizedBox(height: 12),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Choose only what feels useful. Everything can be edited or removed later, and reminders stay off unless you turn them on.',
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text('Which rooms matter today?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final room in rooms)
                  FilterChip(
                    label: Text(room),
                    selected: _selectedRooms.contains(room),
                    onSelected: (selected) => setState(() {
                      selected
                          ? _selectedRooms.add(room)
                          : _selectedRooms.remove(room);
                      _selectedTemplates.removeWhere(
                        (title) => !starterTemplates.any(
                          (template) =>
                              template.title == title &&
                              _selectedRooms.contains(template.room),
                        ),
                      );
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('How much energy do you have?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<EnergyLevel>(
              showSelectedIcon: false,
              segments: [
                for (final energy in EnergyLevel.values)
                  ButtonSegment(
                      value: energy,
                      label: Text(energy.label.replaceAll(' energy', ''))),
              ],
              selected: {_energy},
              onSelectionChanged: (selection) => setState(() {
                _energy = selection.single;
                _selectedTemplates
                  ..clear()
                  ..addAll(
                    starterTemplates
                        .where(
                          (template) =>
                              _selectedRooms.contains(template.room) &&
                              template.energyLevel.index <= _energy.index,
                        )
                        .map((template) => template.title),
                  );
              }),
            ),
            const SizedBox(height: 24),
            Text('Pick a starter goal', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final template in starterTemplates
                .where((template) => _selectedRooms.contains(template.room)))
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(template.title),
                subtitle: Text(
                  _alreadyAdded(template)
                      ? '${template.room} · Already added'
                      : '${template.room} · ${template.energyLevel.label} · ${template.steps.length} small steps',
                ),
                value: !_alreadyAdded(template) &&
                    _selectedTemplates.contains(template.title),
                onChanged: _alreadyAdded(template)
                    ? null
                    : (selected) => setState(() {
                          selected == true
                              ? _selectedTemplates.add(template.title)
                              : _selectedTemplates.remove(template.title);
                        }),
              ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: starterTemplates.any(
                (template) =>
                    _selectedTemplates.contains(template.title) &&
                    !_alreadyAdded(template),
              )
                  ? _finish
                  : null,
              child: Text(
                widget.addToExisting ? 'Add selected goals' : 'Start gently',
              ),
            ),
            TextButton(
              onPressed: () => _finish(skip: true),
              child: Text(
                widget.addToExisting ? 'Not now' : 'Skip setup for now',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
