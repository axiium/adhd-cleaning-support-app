enum GoalCadence { daily, weekly, monthly, yearly }

enum EnergyLevel { low, medium, high }

extension GoalCadenceLabel on GoalCadence {
  String get label => switch (this) {
        GoalCadence.daily => 'Daily',
        GoalCadence.weekly => 'Weekly',
        GoalCadence.monthly => 'Monthly',
        GoalCadence.yearly => 'Yearly',
      };

  String get completionLabel => switch (this) {
        GoalCadence.daily => 'Done today',
        GoalCadence.weekly => 'Done this week',
        GoalCadence.monthly => 'Done this month',
        GoalCadence.yearly => 'Done this year',
      };
}

extension EnergyLevelLabel on EnergyLevel {
  String get label => switch (this) {
        EnergyLevel.low => 'Low energy',
        EnergyLevel.medium => 'Medium energy',
        EnergyLevel.high => 'High energy',
      };
}
