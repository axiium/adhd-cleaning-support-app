import '../../../core/domain/cleaning_values.dart';
import 'cleaning_task.dart';

class EnergyTaskRecommender {
  const EnergyTaskRecommender._();

  static List<CleaningTask> recommendations({
    required List<CleaningTask> tasks,
    required EnergyLevel availableEnergy,
  }) {
    final preferredLevels = switch (availableEnergy) {
      EnergyLevel.low => const [EnergyLevel.low],
      EnergyLevel.medium => const [EnergyLevel.medium, EnergyLevel.low],
      EnergyLevel.high => const [
          EnergyLevel.high,
          EnergyLevel.medium,
          EnergyLevel.low,
        ],
    };

    return [
      for (final level in preferredLevels)
        ...tasks.where((task) => task.energyLevel == level),
    ];
  }
}
