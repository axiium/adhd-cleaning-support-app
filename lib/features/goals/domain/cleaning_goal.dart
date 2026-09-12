import '../../../core/domain/cleaning_values.dart';
import '../../reminders/domain/goal_reminder.dart';
import 'goal_schedule.dart';

class CleaningGoal {
  const CleaningGoal({
    required this.id,
    required this.title,
    required this.room,
    required this.cadence,
    required this.energyLevel,
    this.reminder,
    this.isArchived = false,
    this.schedule = const GoalSchedule(),
  });

  final String id;
  final String title;
  final String room;
  final GoalCadence cadence;
  final EnergyLevel energyLevel;
  final GoalReminder? reminder;
  final bool isArchived;
  final GoalSchedule schedule;

  CleaningGoal withReminder(GoalReminder? reminder) {
    return CleaningGoal(
      id: id,
      title: title,
      room: room,
      cadence: cadence,
      energyLevel: energyLevel,
      reminder: reminder,
      isArchived: isArchived,
      schedule: schedule,
    );
  }

  CleaningGoal withArchived(bool isArchived) {
    return CleaningGoal(
      id: id,
      title: title,
      room: room,
      cadence: cadence,
      energyLevel: energyLevel,
      reminder: reminder,
      isArchived: isArchived,
      schedule: schedule,
    );
  }

  CleaningGoal withSchedule(GoalSchedule schedule) {
    return CleaningGoal(
      id: id,
      title: title,
      room: room,
      cadence: cadence,
      energyLevel: energyLevel,
      reminder: reminder?.alignedWith(schedule),
      isArchived: isArchived,
      schedule: schedule,
    );
  }

  bool isAvailableOn(DateTime date) => schedule.isAvailableOn(cadence, date);
}
