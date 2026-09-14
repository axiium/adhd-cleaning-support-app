import 'package:flutter/material.dart';

import '../../../core/domain/cleaning_values.dart';
import '../../../core/state/cleaning_app_scope.dart';
import '../../today/domain/cleaning_task.dart';

enum _DurationFilter { any, short, medium, long }

class TaskSearchScreen extends StatefulWidget {
  const TaskSearchScreen({super.key});

  @override
  State<TaskSearchScreen> createState() => _TaskSearchScreenState();
}

class _TaskSearchScreenState extends State<TaskSearchScreen> {
  final _queryController = TextEditingController();
  String? _room;
  EnergyLevel? _energy;
  GoalCadence? _cadence;
  _DurationFilter _duration = _DurationFilter.any;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  bool _matchesDuration(int minutes) => switch (_duration) {
        _DurationFilter.any => true,
        _DurationFilter.short => minutes <= 5,
        _DurationFilter.medium => minutes >= 6 && minutes <= 15,
        _DurationFilter.long => minutes >= 16,
      };

  @override
  Widget build(BuildContext context) {
    final controller = CleaningAppScope.of(context);
    final query = _queryController.text.trim().toLowerCase();
    final rooms = {
      for (final goal in controller.goals)
        if (goal.room.isNotEmpty) goal.room,
    }.toList()
      ..sort();
    final tasks = controller.activeTasks.where((task) {
      final goal = controller.goalById(task.goalId);
      if (goal == null) return false;
      return (query.isEmpty || task.title.toLowerCase().contains(query)) &&
          (_room == null || goal.room == _room) &&
          (_energy == null || task.energyLevel == _energy) &&
          (_cadence == null || goal.cadence == _cadence) &&
          _matchesDuration(task.estimatedMinutes);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Find a small step')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          TextField(
            controller: _queryController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Search tasks',
              hintText: 'Clear a surface',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _queryController.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _queryController.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          _FilterSection<String>(
            label: 'Room',
            values: rooms,
            selected: _room,
            allLabel: 'All rooms',
            onChanged: (value) => setState(() => _room = value),
          ),
          _FilterSection<EnergyLevel>(
            label: 'Energy',
            values: EnergyLevel.values,
            selected: _energy,
            allLabel: 'Any energy',
            labelFor: (value) => value.label.replaceAll(' energy', ''),
            onChanged: (value) => setState(() => _energy = value),
          ),
          _FilterSection<GoalCadence>(
            label: 'Cadence',
            values: GoalCadence.values,
            selected: _cadence,
            allLabel: 'Any cadence',
            labelFor: (value) => value.label,
            onChanged: (value) => setState(() => _cadence = value),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<_DurationFilter>(
            initialValue: _duration,
            decoration: const InputDecoration(
              labelText: 'Duration',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                  value: _DurationFilter.any, child: Text('Any length')),
              DropdownMenuItem(
                  value: _DurationFilter.short,
                  child: Text('5 minutes or less')),
              DropdownMenuItem(
                  value: _DurationFilter.medium, child: Text('6–15 minutes')),
              DropdownMenuItem(
                  value: _DurationFilter.long,
                  child: Text('16 minutes or more')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _duration = value);
            },
          ),
          const SizedBox(height: 24),
          Text(
              '${tasks.length} matching ${tasks.length == 1 ? 'step' : 'steps'}',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (tasks.isEmpty)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                        'No small steps match these filters. Try widening the search.')))
          else
            for (final task in tasks)
              _TaskResult(
                  task: task,
                  goalTitle: controller.goalById(task.goalId)!.title,
                  room: controller.goalById(task.goalId)!.room),
        ],
      ),
    );
  }
}

class _FilterSection<T> extends StatelessWidget {
  const _FilterSection(
      {required this.label,
      required this.values,
      required this.selected,
      required this.allLabel,
      required this.onChanged,
      this.labelFor});
  final String label;
  final List<T> values;
  final T? selected;
  final String allLabel;
  final ValueChanged<T?> onChanged;
  final String Function(T value)? labelFor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 6),
            Wrap(spacing: 8, runSpacing: 8, children: [
              ChoiceChip(
                  label: Text(allLabel),
                  selected: selected == null,
                  onSelected: (_) => onChanged(null)),
              for (final value in values)
                ChoiceChip(
                    label: Text(labelFor?.call(value) ?? value.toString()),
                    selected: selected == value,
                    onSelected: (_) => onChanged(value)),
            ]),
          ],
        ),
      );
}

class _TaskResult extends StatelessWidget {
  const _TaskResult(
      {required this.task, required this.goalTitle, required this.room});
  final CleaningTask task;
  final String goalTitle;
  final String room;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: const Icon(Icons.radio_button_unchecked_rounded),
          title: Text(task.title),
          subtitle: Text(
              '$goalTitle · $room · ${task.estimatedMinutes} min · ${task.energyLevel.label} · ${task.repeatMode.label}'),
        ),
      );
}
