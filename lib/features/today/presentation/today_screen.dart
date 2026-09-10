import 'package:flutter/material.dart';

import '../../../core/domain/cleaning_values.dart';
import '../../../core/state/cleaning_app_scope.dart';
import '../../timer/presentation/focus_timer_screen.dart';
import '../domain/cleaning_task.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int _focusedIndex = 0;

  CleaningTask? _focusedTask(List<CleaningTask> pendingTasks) {
    if (pendingTasks.isEmpty) return null;
    return pendingTasks[_focusedIndex % pendingTasks.length];
  }

  Future<void> _completeFocusedTask(CleaningTask task) async {
    final saved = await CleaningAppScope.of(context).completeTask(task.id);
    if (!saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed for now, but it could not be saved.'),
        ),
      );
    }
  }

  void _chooseAnotherTask(int pendingCount) {
    if (pendingCount < 2) return;
    setState(() => _focusedIndex = (_focusedIndex + 1) % pendingCount);
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

    if (saved == false && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed for now, but it could not be saved.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = CleaningAppScope.of(context);
    final tasks = controller.tasks;
    final pendingTasks =
        tasks.where((task) => !controller.isTaskComplete(task)).toList();
    final focusedTask = _focusedTask(pendingTasks);
    final completedCount = tasks.where(controller.isTaskComplete).length;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Today'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              "Let's make the room a little easier to live in.",
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            _ProgressCard(
              completed: completedCount,
              total: tasks.length,
              progress: progress,
            ),
            const SizedBox(height: 16),
            if (focusedTask != null)
              _FocusCard(
                task: focusedTask,
                goalTitle: controller.goalById(focusedTask.goalId)?.title ??
                    'Cleaning goal',
                canChooseAnother: pendingTasks.length > 1,
                onComplete: () => _completeFocusedTask(focusedTask),
                onStartTimer: () => _startTimer(
                  focusedTask,
                  controller.goalById(focusedTask.goalId)?.title ??
                      'Cleaning goal',
                ),
                onChooseAnother: () => _chooseAnotherTask(pendingTasks.length),
              )
            else if (tasks.isEmpty)
              const _NoStepsCard()
            else
              const _AllDoneCard(),
            const SizedBox(height: 28),
            Text('Your small steps', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (tasks.isEmpty)
              const Text('Add a small step to one of your goals to begin.')
            else
              for (final task in tasks)
                _TaskRow(
                  task: task,
                  isComplete: controller.isTaskComplete(task),
                  goalTitle: controller.goalById(task.goalId)?.title ??
                      'Cleaning goal',
                  cadence: controller.goalById(task.goalId)?.cadence ??
                      GoalCadence.weekly,
                ),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completed,
    required this.total,
    required this.progress,
  });

  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$completed of $total small steps complete'),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.task,
    required this.goalTitle,
    required this.canChooseAnother,
    required this.onComplete,
    required this.onStartTimer,
    required this.onChooseAnother,
  });

  final CleaningTask task;
  final String goalTitle;
  final bool canChooseAnother;
  final VoidCallback onComplete;
  final VoidCallback onStartTimer;
  final VoidCallback onChooseAnother;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Do one thing', style: theme.textTheme.labelLarge),
            const SizedBox(height: 12),
            Text(task.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(goalTitle, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text('${task.estimatedMinutes} min')),
                Chip(label: Text(task.energyLevel.label)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onStartTimer,
                icon: const Icon(Icons.timer_outlined),
                label: Text('Start ${task.estimatedMinutes} min timer'),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onComplete,
                icon: const Icon(Icons.check_rounded),
                label: const Text('I did it'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: canChooseAnother ? onChooseAnother : null,
                child: const Text('Choose another'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoStepsCard extends StatelessWidget {
  const _NoStepsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.lightbulb_outline_rounded, size: 36),
            SizedBox(height: 12),
            Text('Your first small step can be tiny.'),
          ],
        ),
      ),
    );
  }
}

class _AllDoneCard extends StatelessWidget {
  const _AllDoneCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.celebration_outlined, size: 36),
            SizedBox(height: 12),
            Text('That is enough for today.'),
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.task,
    required this.isComplete,
    required this.goalTitle,
    required this.cadence,
  });

  final CleaningTask task;
  final bool isComplete;
  final String goalTitle;
  final GoalCadence cadence;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isComplete
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: isComplete
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outline,
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: isComplete ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        isComplete
            ? '${cadence.completionLabel} - $goalTitle'
            : '${task.estimatedMinutes} min - ${cadence.label} - $goalTitle',
      ),
    );
  }
}
