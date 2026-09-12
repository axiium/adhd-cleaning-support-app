import '../../features/goals/domain/cleaning_goal.dart';
import '../../features/settings/domain/app_preferences.dart';
import '../../features/today/domain/cleaning_task.dart';
import '../domain/cleaning_values.dart';

class CleaningSnapshot {
  CleaningSnapshot({
    required List<CleaningGoal> goals,
    required List<CleaningTask> tasks,
    this.preferences = const AppPreferences(),
  })  : goals = List.unmodifiable(goals),
        tasks = List.unmodifiable(tasks);

  factory CleaningSnapshot.seeded() {
    return CleaningSnapshot(
      goals: const [
        CleaningGoal(
          id: 'kitchen-usable',
          title: 'Keep the kitchen usable',
          room: 'Kitchen',
          cadence: GoalCadence.daily,
          energyLevel: EnergyLevel.low,
        ),
        CleaningGoal(
          id: 'bathroom-reset',
          title: 'Weekly bathroom reset',
          room: 'Bathroom',
          cadence: GoalCadence.weekly,
          energyLevel: EnergyLevel.medium,
        ),
      ],
      tasks: const [
        CleaningTask(
          id: 'kitchen-counter',
          title: 'Clear one section of the counter',
          goalId: 'kitchen-usable',
          estimatedMinutes: 5,
          energyLevel: EnergyLevel.low,
        ),
        CleaningTask(
          id: 'five-dishes',
          title: 'Put away five dishes',
          goalId: 'kitchen-usable',
          estimatedMinutes: 2,
          energyLevel: EnergyLevel.low,
        ),
        CleaningTask(
          id: 'bathroom-sink',
          title: 'Wipe the bathroom sink',
          goalId: 'bathroom-reset',
          estimatedMinutes: 5,
          energyLevel: EnergyLevel.medium,
        ),
      ],
    );
  }

  final List<CleaningGoal> goals;
  final List<CleaningTask> tasks;
  final AppPreferences preferences;
}

abstract interface class CleaningRepository {
  Future<CleaningSnapshot?> load();

  Future<void> save(CleaningSnapshot snapshot);
}

class MemoryCleaningRepository implements CleaningRepository {
  MemoryCleaningRepository({CleaningSnapshot? initialSnapshot})
      : _snapshot = initialSnapshot;

  factory MemoryCleaningRepository.seeded() {
    return MemoryCleaningRepository(initialSnapshot: CleaningSnapshot.seeded());
  }

  CleaningSnapshot? _snapshot;

  @override
  Future<CleaningSnapshot?> load() async {
    final snapshot = _snapshot;
    if (snapshot == null) return null;
    return CleaningSnapshot(
      goals: snapshot.goals,
      tasks: snapshot.tasks,
      preferences: snapshot.preferences,
    );
  }

  @override
  Future<void> save(CleaningSnapshot snapshot) async {
    _snapshot = CleaningSnapshot(
      goals: snapshot.goals,
      tasks: snapshot.tasks,
      preferences: snapshot.preferences,
    );
  }
}
