import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/domain/cleaning_values.dart';
import '../../../core/presentation/task_completion_feedback.dart';
import '../../../core/state/cleaning_app_scope.dart';
import '../../goals/domain/cleaning_goal.dart';
import '../../goals/domain/goal_pacing.dart';
import '../../power_hour/presentation/power_hour_screen.dart';
import '../../timer/presentation/focus_timer_screen.dart';
import '../domain/cleaning_task.dart';
import '../domain/energy_task_recommender.dart';

class TodayScreen extends StatefulWidget {
  const TodayScreen({super.key});

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  int _focusedIndex = 0;
  EnergyLevel? _selectedEnergy;

  CleaningTask? _focusedTask(List<CleaningTask> pendingTasks) {
    if (pendingTasks.isEmpty) return null;
    return pendingTasks[_focusedIndex % pendingTasks.length];
  }

  Future<void> _completeFocusedTask(CleaningTask task) async {
    final controller = CleaningAppScope.of(context);
    final saved = await controller.completeTask(task.id);
    if (!mounted) return;

    if (saved && controller.preferences.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }

    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completed for now, but it could not be saved.'),
        ),
      );
      return;
    }

    showTaskCompletionFeedback(
      context: context,
      task: task,
      controller: controller,
    );
  }

  Future<void> _toggleTaskCompletion(CleaningTask task) async {
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

  Future<void> _skipFocusedTask(CleaningTask task) async {
    final saved = await CleaningAppScope.of(context).skipTask(task.id);
    if (!mounted) return;
    if (saved) {
      setState(() => _focusedIndex++);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Skipped for now. You can come back when you are ready.'
              : 'That skip could not be saved. Please try again.',
        ),
      ),
    );
  }

  void _chooseAnotherTask(int pendingCount) {
    if (pendingCount < 2) return;
    setState(() => _focusedIndex = (_focusedIndex + 1) % pendingCount);
  }

  void _openPowerHour() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const PowerHourScreen(),
      ),
    );
  }

  Future<void> _chooseEnergy(List<CleaningTask> pendingTasks) async {
    final selected = await showModalBottomSheet<EnergyLevel>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => _EnergyPickerSheet(selected: _selectedEnergy),
    );
    if (selected == null || !mounted) return;

    final matches = EnergyTaskRecommender.recommendations(
      tasks: pendingTasks,
      availableEnergy: selected,
    );
    if (matches.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No ${selected.label.toLowerCase()} steps are available right now. '
            'Choosing any small step is still okay.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedEnergy = selected;
      _focusedIndex = 0;
    });
  }

  void _clearEnergyMatch() {
    setState(() {
      _selectedEnergy = null;
      _focusedIndex = 0;
    });
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
    final theme = Theme.of(context);
    final controller = CleaningAppScope.of(context);
    final tasks = controller.tasks;
    final hasStepsScheduledLater =
        tasks.isEmpty && controller.activeTasks.isNotEmpty;
    final pendingTasks =
        tasks.where((task) => !controller.isTaskComplete(task)).toList();
    final recommendedTasks = _selectedEnergy == null
        ? pendingTasks
        : EnergyTaskRecommender.recommendations(
            tasks: pendingTasks,
            availableEnergy: _selectedEnergy!,
          );
    final focusedTask = _focusedTask(recommendedTasks);
    final completedCount = tasks.where(controller.isTaskComplete).length;
    final progress = tasks.isEmpty ? 0.0 : completedCount / tasks.length;
    final deadlinePaces = <_DeadlinePaceItem>[];
    for (final goal in controller.goals) {
      final deadline = goal.deadline;
      if (deadline == null) continue;
      final goalTasks = controller.tasksForGoal(goal.id);
      final remaining =
          goalTasks.where((task) => !controller.isTaskComplete(task)).length;
      if (remaining == 0) continue;
      deadlinePaces.add(
        _DeadlinePaceItem(
          goal: goal,
          pacing: GoalPacing.calculate(
            deadline: deadline,
            remainingTasks: remaining,
            now: controller.currentTime,
          ),
        ),
      );
    }

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
            _PowerHourCard(onOpen: _openPowerHour),
            const SizedBox(height: 16),
            if (deadlinePaces.isNotEmpty) ...[
              _DeadlineOverviewCard(items: deadlinePaces),
              const SizedBox(height: 16),
            ],
            if (pendingTasks.isNotEmpty) ...[
              _EnergyMatchCard(
                selectedEnergy: _selectedEnergy,
                onChoose: () => _chooseEnergy(pendingTasks),
                onClear: _clearEnergyMatch,
              ),
              const SizedBox(height: 16),
            ],
            if (focusedTask != null)
              _FocusCard(
                task: focusedTask,
                selectedEnergy: _selectedEnergy,
                goalTitle: controller.goalById(focusedTask.goalId)?.title ??
                    'Cleaning goal',
                canChooseAnother: recommendedTasks.length > 1,
                onComplete: () => _completeFocusedTask(focusedTask),
                onSkip: () => _skipFocusedTask(focusedTask),
                onStartTimer: () => _startTimer(
                  focusedTask,
                  controller.goalById(focusedTask.goalId)?.title ??
                      'Cleaning goal',
                ),
                onChooseAnother: () =>
                    _chooseAnotherTask(recommendedTasks.length),
              )
            else if (_selectedEnergy != null && pendingTasks.isNotEmpty)
              _NoEnergyMatchesCard(onClear: _clearEnergyMatch)
            else if (hasStepsScheduledLater)
              const _ScheduledLaterCard()
            else if (tasks.isEmpty)
              const _NoStepsCard()
            else
              const _AllDoneCard(),
            const SizedBox(height: 28),
            Text('Your small steps', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            if (hasStepsScheduledLater)
              const Text(
                'Your other steps will appear here on their preferred days.',
              )
            else if (tasks.isEmpty)
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
                  onToggle: () => _toggleTaskCompletion(task),
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

class _PowerHourCard extends StatelessWidget {
  const _PowerHourCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.schedule_rounded),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Power Hour'),
                  SizedBox(height: 2),
                  Text('Build a gentle plan for the time you have.'),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: onOpen,
              child: const Text('Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlinePaceItem {
  const _DeadlinePaceItem({required this.goal, required this.pacing});

  final CleaningGoal goal;
  final GoalPacing pacing;
}

class _DeadlineOverviewCard extends StatelessWidget {
  const _DeadlineOverviewCard({required this.items});

  final List<_DeadlinePaceItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gentle deadline pace', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('A suggestion for today, never an overdue backlog.'),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.event_outlined, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.pacing.deadlinePassed
                            ? '${item.goal.title}: the date passed, so choose any one step when ready.'
                            : '${item.goal.title}: aim for ${item.pacing.suggestedToday} ${item.pacing.suggestedToday == 1 ? 'step' : 'steps'} today.',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EnergyMatchCard extends StatelessWidget {
  const _EnergyMatchCard({
    required this.selectedEnergy,
    required this.onChoose,
    required this.onClear,
  });

  final EnergyLevel? selectedEnergy;
  final VoidCallback onChoose;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final selected = selectedEnergy;
    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            const Icon(Icons.battery_charging_full_rounded),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected == null
                        ? 'Match a task to your energy'
                        : 'Matching ${selected.label.toLowerCase()} tasks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected == null
                        ? 'Tell us what you have available right now.'
                        : 'Exact matches come first, then gentler options.',
                  ),
                ],
              ),
            ),
            if (selected != null)
              IconButton(
                tooltip: 'Show any energy level',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              ),
            TextButton(
              onPressed: onChoose,
              child: Text(selected == null ? 'Choose' : 'Change'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyPickerSheet extends StatelessWidget {
  const _EnergyPickerSheet({required this.selected});

  final EnergyLevel? selected;

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What energy do you have?',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text('This is only for right now. There is no wrong answer.'),
            const SizedBox(height: 16),
            _EnergyChoice(
              energy: EnergyLevel.low,
              description: 'Keep it tiny and easy to begin.',
              selected: selected == EnergyLevel.low,
            ),
            _EnergyChoice(
              energy: EnergyLevel.medium,
              description: 'A little momentum, with gentler backups.',
              selected: selected == EnergyLevel.medium,
            ),
            _EnergyChoice(
              energy: EnergyLevel.high,
              description: 'Ready for more, but smaller tasks still count.',
              selected: selected == EnergyLevel.high,
            ),
          ],
        ),
      ],
    );
  }
}

class _EnergyChoice extends StatelessWidget {
  const _EnergyChoice({
    required this.energy,
    required this.description,
    required this.selected,
  });

  final EnergyLevel energy;
  final String description;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: selected ? Theme.of(context).colorScheme.secondaryContainer : null,
      child: ListTile(
        onTap: () => Navigator.of(context).pop(energy),
        leading: Icon(_energyIcon(energy)),
        title: Text(energy.label),
        subtitle: Text(description),
        trailing: selected ? const Icon(Icons.check_rounded) : null,
      ),
    );
  }

  IconData _energyIcon(EnergyLevel energy) => switch (energy) {
        EnergyLevel.low => Icons.battery_1_bar_rounded,
        EnergyLevel.medium => Icons.battery_4_bar_rounded,
        EnergyLevel.high => Icons.battery_full_rounded,
      };
}

class _FocusCard extends StatelessWidget {
  const _FocusCard({
    required this.task,
    required this.selectedEnergy,
    required this.goalTitle,
    required this.canChooseAnother,
    required this.onComplete,
    required this.onSkip,
    required this.onStartTimer,
    required this.onChooseAnother,
  });

  final CleaningTask task;
  final EnergyLevel? selectedEnergy;
  final String goalTitle;
  final bool canChooseAnother;
  final VoidCallback onComplete;
  final VoidCallback onSkip;
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
            Text(
              selectedEnergy == null
                  ? 'Do one thing'
                  : '${selectedEnergy!.label} match',
              style: theme.textTheme.labelLarge,
            ),
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
                if (task.repeatMode == TaskRepeatMode.oneTime)
                  const Chip(label: Text('One-time')),
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
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: onSkip,
                child: const Text('Skip for now'),
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

class _ScheduledLaterCard extends StatelessWidget {
  const _ScheduledLaterCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.event_available_outlined, size: 36),
            SizedBox(height: 12),
            Text('Nothing is asking for attention today.'),
            SizedBox(height: 8),
            Text('Your scheduled steps will be here when their day arrives.'),
          ],
        ),
      ),
    );
  }
}

class _NoEnergyMatchesCard extends StatelessWidget {
  const _NoEnergyMatchesCard({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.spa_outlined, size: 36),
            const SizedBox(height: 12),
            const Text('You finished the matching options.'),
            const SizedBox(height: 8),
            const Text('That can be enough, or you can look at every task.'),
            const SizedBox(height: 12),
            TextButton(onPressed: onClear, child: const Text('Show any task')),
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
    required this.onToggle,
  });

  final CleaningTask task;
  final bool isComplete;
  final String goalTitle;
  final GoalCadence cadence;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: IconButton(
        onPressed: onToggle,
        tooltip: isComplete ? 'Mark as not done' : 'Mark complete',
        icon: Icon(
          isComplete
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: isComplete
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: isComplete ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        isComplete
            ? task.repeatMode == TaskRepeatMode.oneTime
                ? 'One-time step complete - $goalTitle'
                : '${cadence.completionLabel} - $goalTitle'
            : '${task.estimatedMinutes} min - ${task.repeatMode == TaskRepeatMode.oneTime ? 'One-time' : cadence.label} - $goalTitle',
      ),
    );
  }
}
