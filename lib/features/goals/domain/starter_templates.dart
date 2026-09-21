import '../../../core/domain/cleaning_values.dart';

class StarterTemplate {
  const StarterTemplate({
    required this.room,
    required this.title,
    required this.cadence,
    required this.energyLevel,
    required this.steps,
  });

  final String room;
  final String title;
  final GoalCadence cadence;
  final EnergyLevel energyLevel;
  final List<StarterTemplateStep> steps;

  String get energySummary {
    final included = EnergyLevel.values
        .where((energy) => steps.any((step) => step.energyLevel == energy))
        .map((energy) => energy.label.replaceAll(' energy', ''))
        .toList();
    if (included.length == 1) return '${included.single} energy';
    return '${included.join(' + ')} energy mix';
  }
}

class StarterTemplateStep {
  const StarterTemplateStep(
      this.title, this.estimatedMinutes, this.energyLevel);

  final String title;
  final int estimatedMinutes;
  final EnergyLevel energyLevel;
}

const starterTemplates = [
  StarterTemplate(
    room: 'Kitchen',
    title: 'Keep the kitchen usable',
    cadence: GoalCadence.daily,
    energyLevel: EnergyLevel.low,
    steps: [
      StarterTemplateStep(
          'Clear one section of the counter', 5, EnergyLevel.low),
      StarterTemplateStep(
          'Put dishes by the sink or dishwasher', 5, EnergyLevel.low),
      StarterTemplateStep(
          'Take out food trash if it smells', 3, EnergyLevel.medium),
    ],
  ),
  StarterTemplate(
    room: 'Bathroom',
    title: 'Make the bathroom comfortable',
    cadence: GoalCadence.weekly,
    energyLevel: EnergyLevel.medium,
    steps: [
      StarterTemplateStep('Wipe the sink', 5, EnergyLevel.low),
      StarterTemplateStep('Refresh the toilet', 5, EnergyLevel.medium),
      StarterTemplateStep('Put loose items back in place', 5, EnergyLevel.low),
    ],
  ),
  StarterTemplate(
    room: 'Bedroom',
    title: 'Make the bedroom restful',
    cadence: GoalCadence.weekly,
    energyLevel: EnergyLevel.low,
    steps: [
      StarterTemplateStep('Clear one small surface', 5, EnergyLevel.low),
      StarterTemplateStep('Gather laundry into one spot', 5, EnergyLevel.low),
      StarterTemplateStep(
          'Change the sheets when ready', 10, EnergyLevel.medium),
    ],
  ),
  StarterTemplate(
    room: 'Living room',
    title: 'Reset the living room',
    cadence: GoalCadence.weekly,
    energyLevel: EnergyLevel.low,
    steps: [
      StarterTemplateStep('Collect cups and dishes', 5, EnergyLevel.low),
      StarterTemplateStep(
          'Return five things to their homes', 5, EnergyLevel.low),
      StarterTemplateStep('Clear a place to sit', 5, EnergyLevel.low),
    ],
  ),
];
