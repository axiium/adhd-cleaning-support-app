import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:adhd_cleaning_support/features/today/domain/energy_task_recommender.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tasks = [
    CleaningTask(
      id: 'low-one',
      title: 'Low one',
      goalId: 'goal',
      estimatedMinutes: 2,
      energyLevel: EnergyLevel.low,
    ),
    CleaningTask(
      id: 'high-one',
      title: 'High one',
      goalId: 'goal',
      estimatedMinutes: 15,
      energyLevel: EnergyLevel.high,
    ),
    CleaningTask(
      id: 'medium-one',
      title: 'Medium one',
      goalId: 'goal',
      estimatedMinutes: 5,
      energyLevel: EnergyLevel.medium,
    ),
    CleaningTask(
      id: 'low-two',
      title: 'Low two',
      goalId: 'goal',
      estimatedMinutes: 5,
      energyLevel: EnergyLevel.low,
    ),
  ];

  test('exact energy matches come before gentler options', () {
    final recommendations = EnergyTaskRecommender.recommendations(
      tasks: tasks,
      availableEnergy: EnergyLevel.medium,
    );

    expect(
      recommendations.map((task) => task.id),
      ['medium-one', 'low-one', 'low-two'],
    );
  });

  test('rescue mode never suggests a task above available energy', () {
    final recommendations = EnergyTaskRecommender.recommendations(
      tasks: tasks,
      availableEnergy: EnergyLevel.low,
    );

    expect(recommendations.map((task) => task.id), ['low-one', 'low-two']);
  });
}
