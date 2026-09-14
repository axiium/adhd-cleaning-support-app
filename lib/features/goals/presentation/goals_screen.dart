import 'package:flutter/material.dart';

import '../../../core/domain/cleaning_values.dart';
import '../../../core/state/cleaning_app_controller.dart';
import '../../../core/state/cleaning_app_scope.dart';
import '../../reminders/domain/goal_reminder.dart';
import '../../today/domain/cleaning_task.dart';
import '../domain/cleaning_goal.dart';
import '../domain/goal_schedule.dart';
import '../domain/starter_templates.dart';
import '../../search/presentation/task_search_screen.dart';

enum _GoalAction { edit, archive, delete }

enum _TaskAction { edit, archive, delete }

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key});

  Future<void> _openCreateGoal(BuildContext context) async {
    final goal = await showModalBottomSheet<CleaningGoal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _CreateGoalSheet(),
    );

    if (goal == null || !context.mounted) return;

    final saved = await CleaningAppScope.of(context).addGoal(goal);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Goal added. Add one tiny first step.'
              : 'Goal added for now, but it could not be saved.',
        ),
      ),
    );
  }

  void _openGoal(BuildContext context, CleaningGoal goal) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => GoalDetailScreen(goalId: goal.id),
      ),
    );
  }

  Future<void> _reorderGoals(
    BuildContext context,
    int oldIndex,
    int newIndex,
  ) async {
    final saved = await CleaningAppScope.of(
      context,
    ).reorderGoals(oldIndex, newIndex);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That order could not be saved.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = CleaningAppScope.of(context);
    final goals = controller.goals;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Goals'),
        actions: [
          IconButton(
            tooltip: 'Find a small step',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const TaskSearchScreen(),
              ),
            ),
            icon: const Icon(Icons.search_rounded),
          ),
          IconButton(
            tooltip: 'Archived items',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ArchivedItemsScreen(),
              ),
            ),
            icon: const Icon(Icons.archive_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGoal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add goal'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose what "good enough" looks like.',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Goals give direction. Small steps will do the work.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Use the handles to put the most helpful goals first.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: goals.isEmpty
                  ? const Center(child: Text('No active goals right now.'))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
                      buildDefaultDragHandles: false,
                      itemCount: goals.length,
                      onReorderItem: (oldIndex, newIndex) =>
                          _reorderGoals(context, oldIndex, newIndex),
                      itemBuilder: (context, index) {
                        final goal = goals[index];
                        return Padding(
                          key: ValueKey(goal.id),
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _GoalCard(
                            goal: goal,
                            tasks: controller.tasksForGoal(goal.id),
                            isComplete: controller.isTaskComplete,
                            onTap: () => _openGoal(context, goal),
                            dragHandle: ReorderableDragStartListener(
                              index: index,
                              child: const IconButton(
                                tooltip: 'Reorder goal',
                                onPressed: null,
                                icon: Icon(Icons.drag_handle_rounded),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            IconButton(
              tooltip: 'Starter templates',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const StarterTemplatesScreen(),
                ),
              ),
              icon: const Icon(Icons.auto_awesome_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class StarterTemplatesScreen extends StatelessWidget {
  const StarterTemplatesScreen({super.key});

  Future<void> _addTemplate(
      BuildContext context, StarterTemplate template) async {
    final suffix = DateTime.now().microsecondsSinceEpoch.toString();
    final controller = CleaningAppScope.of(context);
    final goal = CleaningGoal(
      id: 'template-goal-$suffix',
      title: template.title,
      room: template.room,
      cadence: template.cadence,
      energyLevel: template.energyLevel,
      schedule: GoalSchedule.fromDate(controller.currentTime),
    );
    if (!await controller.addGoal(goal)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('That starter could not be added.')),
        );
      }
      return;
    }
    for (var index = 0; index < template.steps.length; index++) {
      final step = template.steps[index];
      await controller.addTask(
        CleaningTask(
          id: 'template-step-$suffix-$index',
          title: step.title,
          goalId: goal.id,
          estimatedMinutes: step.estimatedMinutes,
          energyLevel: step.energyLevel,
        ),
      );
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${template.title} added with ${template.steps.length} small steps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Starter templates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('A softer place to start.',
              style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          const Text(
              'Choose a room and we will add a few small, editable steps. You can change or remove anything later.'),
          const SizedBox(height: 24),
          for (final template in starterTemplates)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(template.room, style: theme.textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text(template.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                        '${template.steps.length} small steps · ${template.cadence.label} · ${template.energyLevel.label}'),
                    const SizedBox(height: 8),
                    for (final step in template.steps)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                            '• ${step.title} (${step.estimatedMinutes} min)'),
                      ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => _addTemplate(context, template),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Add this starter'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({
    required this.goal,
    required this.tasks,
    required this.isComplete,
    required this.onTap,
    required this.dragHandle,
  });

  final CleaningGoal goal;
  final List<CleaningTask> tasks;
  final bool Function(CleaningTask task) isComplete;
  final VoidCallback onTap;
  final Widget dragHandle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = tasks.where(isComplete).length;

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Icon(
                  Icons.home_outlined,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(goal.room, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      tasks.isEmpty
                          ? 'Add a first small step'
                          : '$completed of ${tasks.length} steps complete',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text(goal.cadence.label)),
                        Chip(label: Text(goal.schedule.describe(goal.cadence))),
                        Chip(label: Text(goal.energyLevel.label)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  dragHandle,
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArchivedItemsScreen extends StatelessWidget {
  const ArchivedItemsScreen({super.key});

  Future<void> _restoreGoal(BuildContext context, CleaningGoal goal) async {
    final saved = await CleaningAppScope.of(context).restoreGoal(goal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(saved ? 'Goal restored.' : 'That goal could not be restored.'),
      ),
    );
  }

  Future<void> _restoreTask(BuildContext context, CleaningTask task) async {
    final saved = await CleaningAppScope.of(context).restoreTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'Small step restored.'
            : 'That step could not be restored.'),
      ),
    );
  }

  Future<bool> _confirmRemoval(
    BuildContext context, {
    required bool isGoal,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(isGoal
                ? 'Remove this goal forever?'
                : 'Remove this step forever?'),
            content: Text(
              isGoal
                  ? 'Its small steps and their completion history will be removed. This cannot be undone.'
                  : 'Its completion history will be removed. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep it'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Remove forever'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteGoal(BuildContext context, CleaningGoal goal) async {
    if (!await _confirmRemoval(context, isGoal: true) || !context.mounted) {
      return;
    }
    final saved = await CleaningAppScope.of(context).deleteGoal(goal.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                saved ? 'Goal removed.' : 'That goal could not be removed.')),
      );
    }
  }

  Future<void> _deleteTask(BuildContext context, CleaningTask task) async {
    if (!await _confirmRemoval(context, isGoal: false) || !context.mounted) {
      return;
    }
    final saved = await CleaningAppScope.of(context).deleteTask(task.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(saved
                ? 'Small step removed.'
                : 'That step could not be removed.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = CleaningAppScope.of(context);
    final goals = controller.archivedGoals;
    final tasks = controller.archivedTasks;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Archived items')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text('Out of sight, not gone.',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'Archived goals and steps stay out of Today while keeping their history. Restore them whenever you are ready.',
            ),
            const SizedBox(height: 24),
            if (goals.isEmpty && tasks.isEmpty)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('Nothing is archived.'),
                ),
              ),
            if (goals.isNotEmpty) ...[
              Text('Goals', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final goal in goals)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(goal.title),
                    subtitle: Text('${goal.room} · ${goal.cadence.label}'),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Archived goal options',
                      onSelected: (value) => value == 'restore'
                          ? _restoreGoal(context, goal)
                          : _deleteGoal(context, goal),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: 'restore', child: Text('Restore goal')),
                        PopupMenuItem(
                            value: 'delete', child: Text('Remove forever')),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
            ],
            if (tasks.isNotEmpty) ...[
              Text('Small steps', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final task in tasks)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.archive_outlined),
                    title: Text(task.title),
                    subtitle: Text(
                      controller.goalById(task.goalId)?.title ??
                          'Cleaning goal',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Archived step options',
                      onSelected: (value) => value == 'restore'
                          ? _restoreTask(context, task)
                          : _deleteTask(context, task),
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                            value: 'restore', child: Text('Restore step')),
                        PopupMenuItem(
                            value: 'delete', child: Text('Remove forever')),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final String goalId;

  Future<void> _archiveGoal(BuildContext context, CleaningGoal goal) async {
    final saved = await CleaningAppScope.of(context).archiveGoal(goal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Goal archived. Its history is still safe.'
              : 'That goal could not be archived. Please try again.',
        ),
      ),
    );
    if (saved) Navigator.of(context).pop();
  }

  Future<void> _archiveTask(
    BuildContext context,
    CleaningTask task,
  ) async {
    final saved = await CleaningAppScope.of(context).archiveTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Small step archived. Its history is still safe.'
              : 'That step could not be archived. Please try again.',
        ),
      ),
    );
  }

  Future<void> _reorderTasks(
    BuildContext context,
    int oldIndex,
    int newIndex,
  ) async {
    final saved = await CleaningAppScope.of(
      context,
    ).reorderTasksForGoal(goalId, oldIndex, newIndex);
    if (!saved && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That order could not be saved.')),
      );
    }
  }

  Future<void> _editGoal(BuildContext context, CleaningGoal goal) async {
    final updatedGoal = await showModalBottomSheet<CleaningGoal>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CreateGoalSheet(initialGoal: goal),
    );
    if (updatedGoal == null || !context.mounted) return;

    final saved = await CleaningAppScope.of(context).updateGoal(updatedGoal);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Goal updated.'
              : 'That change could not be saved. Please try again.',
        ),
      ),
    );
  }

  Future<void> _deleteGoal(BuildContext context, CleaningGoal goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this goal?'),
        content: const Text(
          'Its small steps and their completion history will also be removed. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep goal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove goal'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final saved = await CleaningAppScope.of(context).deleteGoal(goal.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Goal removed.'
              : 'That goal could not be removed. Please try again.',
        ),
      ),
    );
    if (saved) Navigator.of(context).pop();
  }

  Future<void> _editTask(
    BuildContext context,
    CleaningGoal goal,
    CleaningTask task,
  ) async {
    final updatedTask = await showModalBottomSheet<CleaningTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CreateStepSheet(goal: goal, initialTask: task),
    );
    if (updatedTask == null || !context.mounted) return;

    final saved = await CleaningAppScope.of(context).updateTask(updatedTask);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Small step updated.'
              : 'That change could not be saved. Please try again.',
        ),
      ),
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    CleaningTask task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove this small step?'),
        content: const Text(
          'Its completion history will also be removed. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep step'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove step'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final saved = await CleaningAppScope.of(context).deleteTask(task.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Small step removed.'
              : 'That step could not be removed. Please try again.',
        ),
      ),
    );
  }

  Future<void> _toggleTaskCompletion(
    BuildContext context,
    CleaningTask task,
  ) async {
    final controller = CleaningAppScope.of(context);
    final wasComplete = controller.isTaskComplete(task);
    final saved = await controller.toggleTaskCompletion(task.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          !saved
              ? 'That change could not be saved. Please try again.'
              : wasComplete
                  ? 'Marked as not done.'
                  : 'Small step completed.',
        ),
      ),
    );
  }

  Future<void> _chooseReminder(
    BuildContext context,
    CleaningGoal goal,
  ) async {
    final existing = goal.reminder;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: existing?.hour ?? 18,
        minute: existing?.minute ?? 0,
      ),
      helpText: 'Choose a gentle reminder time',
    );
    if (selectedTime == null || !context.mounted) return;

    final reminder = GoalReminder(
      hour: selectedTime.hour,
      minute: selectedTime.minute,
      weekday: goal.schedule.weekday,
      dayOfMonth: goal.schedule.dayOfMonth,
      month: goal.schedule.month,
      escalationEnabled: existing?.escalationEnabled ?? false,
      escalateAfterSkips: existing?.escalateAfterSkips ?? 3,
      escalationDelayMinutes: existing?.escalationDelayMinutes ?? 60,
      maxEscalationsPerPeriod: existing?.maxEscalationsPerPeriod ?? 2,
    );
    final result = await CleaningAppScope.of(context).setGoalReminder(
      goal.id,
      reminder,
    );
    if (!context.mounted) return;
    _showReminderResult(context, result, enabled: true);
  }

  Future<void> _updateReminderSettings(
    BuildContext context,
    CleaningGoal goal,
    GoalReminder reminder,
  ) async {
    final result = await CleaningAppScope.of(
      context,
    ).setGoalReminder(goal.id, reminder);
    if (!context.mounted) return;
    if (result != ReminderUpdateResult.saved) {
      _showReminderResult(context, result, enabled: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder settings saved.')),
      );
    }
  }

  Future<void> _disableReminder(
    BuildContext context,
    CleaningGoal goal,
  ) async {
    final result = await CleaningAppScope.of(
      context,
    ).setGoalReminder(goal.id, null);
    if (!context.mounted) return;
    _showReminderResult(context, result, enabled: false);
  }

  Future<void> _sendTestReminder(
    BuildContext context,
    CleaningGoal goal,
  ) async {
    final result = await CleaningAppScope.of(
      context,
    ).sendTestReminder(goal.id);
    if (!context.mounted) return;

    final message = switch (result) {
      ReminderUpdateResult.saved =>
        'Test reminder sent. Check your notification shade.',
      ReminderUpdateResult.permissionDenied =>
        'Notifications stayed off. You can allow them in system settings.',
      ReminderUpdateResult.schedulingFailed =>
        'That test reminder could not be shown. Please try again.',
      ReminderUpdateResult.storageFailed =>
        'That test reminder could not be shown. Please try again.',
      ReminderUpdateResult.limitReached =>
        'Your reminder limit is full. Change it in Settings first.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showReminderResult(
    BuildContext context,
    ReminderUpdateResult result, {
    required bool enabled,
  }) {
    final message = switch (result) {
      ReminderUpdateResult.saved =>
        enabled ? 'Gentle reminder scheduled.' : 'Reminder turned off.',
      ReminderUpdateResult.permissionDenied =>
        'Notifications stayed off. You can allow them in system settings.',
      ReminderUpdateResult.schedulingFailed =>
        'That reminder could not be scheduled. Please try again.',
      ReminderUpdateResult.storageFailed =>
        'That reminder could not be saved. Please try again.',
      ReminderUpdateResult.limitReached =>
        'Your reminder limit is full. Change it in Settings first.',
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCreateStep(
    BuildContext context,
    CleaningGoal goal,
  ) async {
    final task = await showModalBottomSheet<CleaningTask>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _CreateStepSheet(goal: goal),
    );

    if (task == null || !context.mounted) return;

    final saved = await CleaningAppScope.of(context).addTask(task);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? 'Small step added to Today.'
              : 'Step added for now, but it could not be saved.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = CleaningAppScope.of(context);
    final goal = controller.goalById(goalId);

    if (goal == null) {
      return const Scaffold(body: Center(child: Text('Goal not found.')));
    }

    final tasks = controller.tasksForGoal(goalId);
    final completed = tasks.where(controller.isTaskComplete).length;
    final progress = tasks.isEmpty ? 0.0 : completed / tasks.length;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(goal.title),
        actions: [
          PopupMenuButton<_GoalAction>(
            tooltip: 'Goal options',
            onSelected: (action) {
              switch (action) {
                case _GoalAction.edit:
                  _editGoal(context, goal);
                case _GoalAction.archive:
                  _archiveGoal(context, goal);
                case _GoalAction.delete:
                  _deleteGoal(context, goal);
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _GoalAction.edit,
                child: Text('Edit goal'),
              ),
              PopupMenuItem(
                value: _GoalAction.archive,
                child: Text('Archive goal'),
              ),
              PopupMenuItem(
                value: _GoalAction.delete,
                child: Text('Remove goal'),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateStep(context, goal),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add small step'),
      ),
      body: SafeArea(
        child: ReorderableListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
          buildDefaultDragHandles: false,
          itemCount: tasks.length,
          onReorderItem: (oldIndex, newIndex) =>
              _reorderTasks(context, oldIndex, newIndex),
          header: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    avatar: const Icon(Icons.place_outlined, size: 18),
                    label: Text(goal.room),
                  ),
                  Chip(label: Text(goal.cadence.label)),
                  Chip(label: Text(goal.schedule.describe(goal.cadence))),
                ],
              ),
              const SizedBox(height: 20),
              _ReminderCard(
                goal: goal,
                warning: controller.reminderWarning,
                onEnableOrChange: () => _chooseReminder(context, goal),
                onDisable: () => _disableReminder(context, goal),
                onSendTest: () => _sendTestReminder(context, goal),
                onUpdateSettings: (reminder) =>
                    _updateReminderSettings(context, goal, reminder),
              ),
              const SizedBox(height: 20),
              Text(
                tasks.isEmpty
                    ? 'What is one tiny action that would help?'
                    : '$completed of ${tasks.length} steps complete',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 24),
              if (tasks.isEmpty)
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Try something that takes two to five minutes. '
                      'You can always add more later.',
                    ),
                  ),
                ),
              if (tasks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Use the handles to choose which step appears first.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
            ],
          ),
          itemBuilder: (context, index) {
            final task = tasks[index];
            return ListTile(
              key: ValueKey(task.id),
              contentPadding: EdgeInsets.zero,
              leading: IconButton(
                onPressed: () => _toggleTaskCompletion(context, task),
                tooltip: controller.isTaskComplete(task)
                    ? 'Mark as not done'
                    : 'Mark complete',
                icon: Icon(
                  controller.isTaskComplete(task)
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                ),
              ),
              title: Text(
                task.title,
                style: TextStyle(
                  decoration: controller.isTaskComplete(task)
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              subtitle: Text(
                controller.isTaskComplete(task)
                    ? task.repeatMode == TaskRepeatMode.oneTime
                        ? 'One-time step complete'
                        : goal.cadence.completionLabel
                    : '${task.estimatedMinutes} min - ${task.energyLevel.label} - ${task.repeatMode.label}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReorderableDragStartListener(
                    index: index,
                    child: const IconButton(
                      tooltip: 'Reorder step',
                      onPressed: null,
                      icon: Icon(Icons.drag_handle_rounded),
                    ),
                  ),
                  PopupMenuButton<_TaskAction>(
                    tooltip: 'Step options',
                    onSelected: (action) {
                      switch (action) {
                        case _TaskAction.edit:
                          _editTask(context, goal, task);
                        case _TaskAction.archive:
                          _archiveTask(context, task);
                        case _TaskAction.delete:
                          _deleteTask(context, task);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _TaskAction.edit,
                        child: Text('Edit step'),
                      ),
                      PopupMenuItem(
                        value: _TaskAction.archive,
                        child: Text('Archive step'),
                      ),
                      PopupMenuItem(
                        value: _TaskAction.delete,
                        child: Text('Remove step'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.goal,
    required this.warning,
    required this.onEnableOrChange,
    required this.onDisable,
    required this.onSendTest,
    required this.onUpdateSettings,
  });

  final CleaningGoal goal;
  final String? warning;
  final VoidCallback onEnableOrChange;
  final VoidCallback onDisable;
  final VoidCallback onSendTest;
  final ValueChanged<GoalReminder> onUpdateSettings;

  @override
  Widget build(BuildContext context) {
    final reminder = goal.reminder;
    final theme = Theme.of(context);

    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_none_rounded),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gentle reminder',
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        reminder == null
                            ? 'Off — no notification unless you choose one.'
                            : reminder
                                .alignedWith(goal.schedule)
                                .describeFor(goal.cadence),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: reminder != null,
                  onChanged: (enabled) {
                    if (enabled) {
                      onEnableOrChange();
                    } else {
                      onDisable();
                    }
                  },
                ),
              ],
            ),
            if (reminder != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: onSendTest,
                    child: const Text('Send test now'),
                  ),
                  TextButton(
                    onPressed: onEnableOrChange,
                    child: const Text('Change time'),
                  ),
                ],
              ),
            if (reminder != null) ...[
              const Divider(height: 1, indent: 40),
              SwitchListTile(
                contentPadding: const EdgeInsets.only(left: 40, right: 8),
                title: const Text('Gentle persistence'),
                subtitle: const Text(
                  'Offer a quiet follow-up after repeated skips.',
                ),
                value: reminder.escalationEnabled,
                onChanged: (enabled) => onUpdateSettings(
                  reminder.copyWith(escalationEnabled: enabled),
                ),
              ),
              if (reminder.escalationEnabled) ...[
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 40, right: 8),
                  title: const Text('Start after'),
                  subtitle: const Text('skips in this recurrence period'),
                  trailing: DropdownButton<int>(
                    value: reminder.escalateAfterSkips,
                    items: const [2, 3, 5]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onUpdateSettings(
                          reminder.copyWith(escalateAfterSkips: value),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 40, right: 8),
                  title: const Text('Follow up after'),
                  subtitle: const Text('before trying again'),
                  trailing: DropdownButton<int>(
                    value: reminder.escalationDelayMinutes,
                    items: const [30, 60, 180]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(value == 60 ? '1 hour' : '$value min'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onUpdateSettings(
                          reminder.copyWith(escalationDelayMinutes: value),
                        );
                      }
                    },
                  ),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.only(left: 40, right: 8),
                  title: const Text('Maximum follow-ups'),
                  subtitle: const Text('per recurrence period'),
                  trailing: DropdownButton<int>(
                    value: reminder.maxEscalationsPerPeriod,
                    items: const [1, 2, 3]
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        onUpdateSettings(
                          reminder.copyWith(maxEscalationsPerPeriod: value),
                        );
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 16, 8),
                  child: Text(
                    'Up to ${reminder.maxEscalationsPerPeriod} follow-ups per recurrence period.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ],
            if (reminder == null)
              const Padding(
                padding: EdgeInsets.fromLTRB(40, 4, 16, 4),
                child: Text(
                  'Turn on this reminder to customize gentle persistence after repeated skips.',
                ),
              ),
            if (warning != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 4, 8, 0),
                child: Text(
                  warning!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateGoalSheet extends StatefulWidget {
  const _CreateGoalSheet({this.initialGoal});

  final CleaningGoal? initialGoal;

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _roomController;

  late GoalCadence _cadence;
  late EnergyLevel _energyLevel;
  late int _weekday;
  late int _dayOfMonth;
  late int _month;

  @override
  void initState() {
    super.initState();
    final goal = widget.initialGoal;
    _titleController = TextEditingController(text: goal?.title);
    _roomController = TextEditingController(text: goal?.room);
    _cadence = goal?.cadence ?? GoalCadence.weekly;
    _energyLevel = goal?.energyLevel ?? EnergyLevel.low;
    final schedule = goal?.schedule ?? GoalSchedule.fromDate(DateTime.now());
    _weekday = schedule.weekday;
    _dayOfMonth = _cadence == GoalCadence.monthly
        ? schedule.dayOfMonth.clamp(1, 28)
        : schedule.dayOfMonth;
    _month = schedule.month;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final schedule = GoalSchedule(
      weekday: _weekday,
      dayOfMonth: _dayOfMonth,
      month: _month,
    );
    Navigator.of(context).pop(
      CleaningGoal(
        id: widget.initialGoal?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        room: _roomController.text.trim(),
        cadence: _cadence,
        energyLevel: _energyLevel,
        reminder: widget.initialGoal?.reminder?.alignedWith(schedule),
        isArchived: widget.initialGoal?.isArchived ?? false,
        schedule: schedule,
      ),
    );
  }

  Future<void> _chooseAnnualDate() async {
    final initialDay = _dayOfMonth.clamp(1, DateTime(2026, _month + 1, 0).day);
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime(2026, _month, initialDay),
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      helpText: 'Choose a yearly date',
    );
    if (selected != null) {
      setState(() {
        _month = selected.month;
        _dayOfMonth = selected.day;
      });
    }
  }

  Widget _scheduleField() {
    return switch (_cadence) {
      GoalCadence.daily => const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.event_available_outlined),
          title: Text('Available every day'),
          subtitle: Text('No date choice needed.'),
        ),
      GoalCadence.weekly => DropdownButtonFormField<int>(
          key: const ValueKey('weekly-schedule'),
          initialValue: _weekday,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Preferred weekday',
          ),
          items: [
            for (var weekday = DateTime.monday;
                weekday <= DateTime.sunday;
                weekday++)
              DropdownMenuItem(
                value: weekday,
                child: Text(GoalSchedule.weekdayNames[weekday - 1]),
              ),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _weekday = value);
          },
        ),
      GoalCadence.monthly => DropdownButtonFormField<int>(
          key: const ValueKey('monthly-schedule'),
          initialValue: _dayOfMonth.clamp(1, 28),
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Preferred monthly date',
            helperText: 'Dates 1–28 work reliably every month.',
          ),
          items: [
            for (var day = 1; day <= 28; day++)
              DropdownMenuItem(value: day, child: Text('Day $day')),
          ],
          onChanged: (value) {
            if (value != null) setState(() => _dayOfMonth = value);
          },
        ),
      GoalCadence.yearly => OutlinedButton.icon(
          onPressed: _chooseAnnualDate,
          icon: const Icon(Icons.calendar_month_outlined),
          label: Text(
            'Preferred date: ${GoalSchedule.monthNames[_month - 1]} $_dayOfMonth',
          ),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(
                title: widget.initialGoal == null
                    ? 'Create a gentle goal'
                    : 'Edit goal',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
              const Text('You can change this later. Good enough is enough.'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'What would you like to maintain?',
                  hintText: 'Keep the bedroom floor clear',
                ),
                validator: _requiredGoalName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _roomController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Room or area',
                  hintText: 'Bedroom',
                ),
                validator: _requiredRoom,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<GoalCadence>(
                initialValue: _cadence,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'How often?',
                ),
                items: [
                  for (final cadence in GoalCadence.values)
                    DropdownMenuItem(
                      value: cadence,
                      child: Text(cadence.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _cadence = value;
                      if (value == GoalCadence.monthly) {
                        _dayOfMonth = _dayOfMonth.clamp(1, 28);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              _scheduleField(),
              const SizedBox(height: 16),
              DropdownButtonFormField<EnergyLevel>(
                initialValue: _energyLevel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Typical energy needed',
                ),
                items: [
                  for (final energyLevel in EnergyLevel.values)
                    DropdownMenuItem(
                      value: energyLevel,
                      child: Text(energyLevel.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _energyLevel = value);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    widget.initialGoal == null ? 'Save goal' : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _requiredGoalName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Give this goal a short name.';
    }
    return null;
  }

  String? _requiredRoom(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Add a room or area.';
    }
    return null;
  }
}

class _CreateStepSheet extends StatefulWidget {
  const _CreateStepSheet({required this.goal, this.initialTask});

  final CleaningGoal goal;
  final CleaningTask? initialTask;

  @override
  State<_CreateStepSheet> createState() => _CreateStepSheetState();
}

class _CreateStepSheetState extends State<_CreateStepSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;

  late int _estimatedMinutes;
  late EnergyLevel _energyLevel;
  late TaskRepeatMode _repeatMode;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title);
    _estimatedMinutes = task?.estimatedMinutes ?? 5;
    _energyLevel = task?.energyLevel ?? widget.goal.energyLevel;
    _repeatMode = task?.repeatMode ?? TaskRepeatMode.repeating;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      CleaningTask(
        id: widget.initialTask?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        goalId: widget.goal.id,
        estimatedMinutes: _estimatedMinutes,
        energyLevel: _energyLevel,
        completions: widget.initialTask?.completions ?? const [],
        isArchived: widget.initialTask?.isArchived ?? false,
        skips: widget.initialTask?.skips ?? const [],
        repeatMode: _repeatMode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(
                title: widget.initialTask == null
                    ? 'Add one small step'
                    : 'Edit small step',
                onClose: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 8),
              Text('For ${widget.goal.title}'),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Small action',
                  hintText: 'Put away five items',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name one small action.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'Will this happen again?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<TaskRepeatMode>(
                  segments: const [
                    ButtonSegment(
                      value: TaskRepeatMode.repeating,
                      label: Text('Repeating'),
                      icon: Icon(Icons.repeat_rounded),
                    ),
                    ButtonSegment(
                      value: TaskRepeatMode.oneTime,
                      label: Text('One-time'),
                      icon: Icon(Icons.looks_one_outlined),
                    ),
                  ],
                  selected: {_repeatMode},
                  onSelectionChanged: (selection) {
                    setState(() => _repeatMode = selection.first);
                  },
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _repeatMode == TaskRepeatMode.oneTime
                    ? 'Once completed, this stays done and will not reset.'
                    : 'This resets with the goal schedule so you can do it again.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _estimatedMinutes,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Estimated time',
                ),
                items: const [
                  DropdownMenuItem(value: 2, child: Text('2 minutes')),
                  DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  DropdownMenuItem(value: 10, child: Text('10 minutes')),
                  DropdownMenuItem(value: 15, child: Text('15 minutes')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _estimatedMinutes = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EnergyLevel>(
                initialValue: _energyLevel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Energy needed',
                ),
                items: [
                  for (final energyLevel in EnergyLevel.values)
                    DropdownMenuItem(
                      value: energyLevel,
                      child: Text(energyLevel.label),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _energyLevel = value);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(
                    widget.initialTask == null
                        ? 'Add to Today'
                        : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
        ),
        IconButton(
          onPressed: onClose,
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}
