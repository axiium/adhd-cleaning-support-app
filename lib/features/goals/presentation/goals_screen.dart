import 'package:flutter/material.dart';

import '../../../core/domain/cleaning_values.dart';
import '../../../core/state/cleaning_app_scope.dart';
import '../../today/domain/cleaning_task.dart';
import '../domain/cleaning_goal.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = CleaningAppScope.of(context);
    final goals = controller.goals;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Goals'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateGoal(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add goal'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
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
            const SizedBox(height: 24),
            for (final goal in goals) ...[
              _GoalCard(
                goal: goal,
                tasks: controller.tasksForGoal(goal.id),
                isComplete: controller.isTaskComplete,
                onTap: () => _openGoal(context, goal),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
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
  });

  final CleaningGoal goal;
  final List<CleaningTask> tasks;
  final bool Function(CleaningTask task) isComplete;
  final VoidCallback onTap;

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
                        Chip(label: Text(goal.energyLevel.label)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({required this.goalId, super.key});

  final String goalId;

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
      appBar: AppBar(title: Text(goal.title)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openCreateStep(context, goal),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add small step'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
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
              ],
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
              )
            else
              for (final task in tasks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    controller.isTaskComplete(task)
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                  ),
                  title: Text(task.title),
                  subtitle: Text(
                    controller.isTaskComplete(task)
                        ? goal.cadence.completionLabel
                        : '${task.estimatedMinutes} min - ${task.energyLevel.label}',
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _CreateGoalSheet extends StatefulWidget {
  const _CreateGoalSheet();

  @override
  State<_CreateGoalSheet> createState() => _CreateGoalSheetState();
}

class _CreateGoalSheetState extends State<_CreateGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _roomController = TextEditingController();

  GoalCadence _cadence = GoalCadence.weekly;
  EnergyLevel _energyLevel = EnergyLevel.low;

  @override
  void dispose() {
    _titleController.dispose();
    _roomController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      CleaningGoal(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        room: _roomController.text.trim(),
        cadence: _cadence,
        energyLevel: _energyLevel,
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
                title: 'Create a gentle goal',
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
                  if (value != null) setState(() => _cadence = value);
                },
              ),
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
                  child: const Text('Save goal'),
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
  const _CreateStepSheet({required this.goal});

  final CleaningGoal goal;

  @override
  State<_CreateStepSheet> createState() => _CreateStepSheetState();
}

class _CreateStepSheetState extends State<_CreateStepSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  int _estimatedMinutes = 5;
  late EnergyLevel _energyLevel;

  @override
  void initState() {
    super.initState();
    _energyLevel = widget.goal.energyLevel;
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
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        goalId: widget.goal.id,
        estimatedMinutes: _estimatedMinutes,
        energyLevel: _energyLevel,
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
                title: 'Add one small step',
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
                  child: const Text('Add to Today'),
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
