import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/cleaning_values.dart';
import '../../../core/presentation/task_completion_feedback.dart';
import '../../../core/state/cleaning_app_scope.dart';
import '../../timer/presentation/focus_timer_screen.dart';
import '../../today/domain/cleaning_task.dart';
import '../domain/power_hour_planner.dart';

class PowerHourScreen extends StatefulWidget {
  const PowerHourScreen({super.key});

  @override
  State<PowerHourScreen> createState() => _PowerHourScreenState();
}

class _PowerHourScreenState extends State<PowerHourScreen> {
  int _availableMinutes = 60;
  EnergyLevel _energy = EnergyLevel.low;
  List<String> _plannedTaskIds = const [];
  bool _hasBuiltPlan = false;

  void _buildPlan() {
    final controller = CleaningAppScope.of(context);
    final plan = PowerHourPlanner.build(
      tasks: controller.tasks
          .where((task) => !controller.isTaskComplete(task))
          .toList(),
      availableMinutes: _availableMinutes,
      maxEnergy: _energy,
    );
    setState(() {
      _plannedTaskIds = plan.tasks.map((task) => task.id).toList();
      _hasBuiltPlan = true;
    });
  }

  Future<void> _toggleTask(CleaningTask task) async {
    final controller = CleaningAppScope.of(context);
    final wasComplete = controller.isTaskComplete(task);
    final saved = await controller.toggleTaskCompletion(task.id);
    if (!mounted) return;
    if (saved && !wasComplete && controller.preferences.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (saved && !wasComplete) {
      showTaskCompletionFeedback(
        context: context,
        task: task,
        controller: controller,
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Marked as not done.'
              : 'That change could not be saved. Please try again.',
        ),
      ),
    );
  }

  Future<void> _skipTask(CleaningTask task) async {
    final saved = await CleaningAppScope.of(context).skipTask(task.id);
    if (!mounted) return;
    if (saved) {
      setState(() => _plannedTaskIds = [
            for (final id in _plannedTaskIds)
              if (id != task.id) id,
          ]);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Removed from this plan. It is still available later.'
              : 'That skip could not be saved. Please try again.',
        ),
      ),
    );
  }

  Future<void> _startTimer(CleaningTask task, String goalTitle) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => FocusTimerScreen(
          taskId: task.id,
          taskTitle: task.title,
          goalTitle: goalTitle,
          duration: Duration(minutes: task.estimatedMinutes),
        ),
      ),
    );
    if (!mounted) return;
    if (saved == true) {
      showTaskCompletionFeedback(
        context: context,
        task: task,
        controller: CleaningAppScope.of(context),
      );
    } else if (saved == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed for now, but it could not be saved.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CleaningAppScope.of(context);
    final tasksById = {for (final task in controller.allTasks) task.id: task};
    final plannedTasks = _plannedTaskIds
        .map((id) => tasksById[id])
        .whereType<CleaningTask>()
        .where((task) => !task.isArchived)
        .toList();
    final plannedMinutes = plannedTasks.fold<int>(
      0,
      (total, task) => total + task.estimatedMinutes,
    );
    final completedCount =
        plannedTasks.where((task) => controller.isTaskComplete(task)).length;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Power Hour')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              'Use the time you have, not every minute of it.',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose a time window and energy level. The plan leaves breathing room so finishing does not depend on perfect estimates.',
            ),
            const SizedBox(height: 24),
            Text('How much time do you have?',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in const [15, 30, 45, 60, 90, 120])
                  ChoiceChip(
                    label: Text(minutes < 60
                        ? '$minutes min'
                        : minutes == 60
                            ? '1 hour'
                            : '${minutes ~/ 60}h ${minutes % 60}m'),
                    selected: _availableMinutes == minutes,
                    onSelected: (_) =>
                        setState(() => _availableMinutes = minutes),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Energy available', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<EnergyLevel>(
              showSelectedIcon: false,
              segments: [
                for (final energy in EnergyLevel.values)
                  ButtonSegment(
                    value: energy,
                    label: Text(energy.label.replaceAll(' energy', '')),
                  ),
              ],
              selected: {_energy},
              onSelectionChanged: (selection) =>
                  setState(() => _energy = selection.single),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _buildPlan,
              icon: const Icon(Icons.playlist_add_check_rounded),
              label:
                  Text(_hasBuiltPlan ? 'Build another plan' : 'Build my plan'),
            ),
            if (_hasBuiltPlan) ...[
              const SizedBox(height: 28),
              if (plannedTasks.isEmpty)
                Card(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No unfinished steps fit this time and energy choice. Try a little more time, a different energy level, or add a smaller step.',
                    ),
                  ),
                )
              else ...[
                Text('Your gentle plan', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  '$plannedMinutes of $_availableMinutes minutes planned · $completedCount of ${plannedTasks.length} done',
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: plannedTasks.isEmpty
                      ? 0
                      : completedCount / plannedTasks.length,
                ),
                const SizedBox(height: 12),
                for (final task in plannedTasks)
                  _PowerHourTaskCard(
                    task: task,
                    goalTitle:
                        controller.goalById(task.goalId)?.title ?? 'Goal',
                    isComplete: controller.isTaskComplete(task),
                    onToggle: () => _toggleTask(task),
                    onSkip: () => _skipTask(task),
                    onStartTimer: () => _startTimer(
                      task,
                      controller.goalById(task.goalId)?.title ?? 'Goal',
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PowerHourTaskCard extends StatelessWidget {
  const _PowerHourTaskCard({
    required this.task,
    required this.goalTitle,
    required this.isComplete,
    required this.onToggle,
    required this.onSkip,
    required this.onStartTimer,
  });

  final CleaningTask task;
  final String goalTitle;
  final bool isComplete;
  final VoidCallback onToggle;
  final VoidCallback onSkip;
  final VoidCallback onStartTimer;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          children: [
            ListTile(
              leading: IconButton(
                tooltip: isComplete ? 'Mark as not done' : 'Mark complete',
                onPressed: onToggle,
                icon: Icon(
                  isComplete
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: isComplete ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                '$goalTitle · ${task.estimatedMinutes} min · ${task.energyLevel.label}',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: onSkip,
                    child: const Text('Not this one'),
                  ),
                ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onStartTimer,
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Start timer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
