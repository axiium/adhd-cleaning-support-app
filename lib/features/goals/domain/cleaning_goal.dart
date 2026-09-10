import '../../../core/domain/cleaning_values.dart';

class CleaningGoal {
  const CleaningGoal({
    required this.id,
    required this.title,
    required this.room,
    required this.cadence,
    required this.energyLevel,
  });

  final String id;
  final String title;
  final String room;
  final GoalCadence cadence;
  final EnergyLevel energyLevel;
}
