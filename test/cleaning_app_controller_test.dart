import 'package:adhd_cleaning_support/core/domain/cleaning_values.dart';
import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:adhd_cleaning_support/core/state/cleaning_app_controller.dart';
import 'package:adhd_cleaning_support/features/goals/domain/cleaning_goal.dart';
import 'package:adhd_cleaning_support/features/goals/domain/goal_schedule.dart';
import 'package:adhd_cleaning_support/features/history/domain/completion_history.dart';
import 'package:adhd_cleaning_support/features/reminders/application/reminder_scheduler.dart';
import 'package:adhd_cleaning_support/features/reminders/domain/goal_reminder.dart';
import 'package:adhd_cleaning_support/features/settings/domain/app_preferences.dart';
import 'package:adhd_cleaning_support/features/today/domain/cleaning_task.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('goals, steps, and completion survive controller recreation', () async {
    final repository = MemoryCleaningRepository.seeded();
    var now = DateTime(2026, 9, 10, 10);
    final firstController = CleaningAppController(
      repository: repository,
      now: () => now,
    );
    await firstController.initialize();

    const goal = CleaningGoal(
      id: 'entryway-clear',
      title: 'Keep the entryway clear',
      room: 'Entryway',
      cadence: GoalCadence.daily,
      energyLevel: EnergyLevel.low,
    );
    const task = CleaningTask(
      id: 'shoes-away',
      title: 'Put away two pairs of shoes',
      goalId: 'entryway-clear',
      estimatedMinutes: 2,
      energyLevel: EnergyLevel.low,
    );

    expect(await firstController.addGoal(goal), isTrue);
    expect(await firstController.addTask(task), isTrue);
    expect(await firstController.completeTask(task.id), isTrue);
    firstController.dispose();

    final restoredController = CleaningAppController(
      repository: repository,
      now: () => now,
    );
    await restoredController.initialize();

    expect(restoredController.goalById(goal.id)?.title, goal.title);
    expect(restoredController.tasksForGoal(goal.id), hasLength(1));
    final restoredTask = restoredController.tasksForGoal(goal.id).single;
    expect(restoredController.isTaskComplete(restoredTask), isTrue);

    now = DateTime(2026, 9, 11, 10);
    expect(restoredController.isTaskComplete(restoredTask), isFalse);
    restoredController.dispose();
  });

  test('a reminder is opt-in, persisted, scheduled, and cancellable', () async {
    final repository = MemoryCleaningRepository.seeded();
    final scheduler = MemoryReminderScheduler();
    final controller = CleaningAppController(
      repository: repository,
      reminderScheduler: scheduler,
    );
    await controller.initialize();

    const reminder = GoalReminder(
      hour: 18,
      minute: 30,
      weekday: DateTime.thursday,
      dayOfMonth: 10,
      month: DateTime.september,
    );
    final enabled = await controller.setGoalReminder(
      'kitchen-usable',
      reminder,
    );

    expect(enabled, ReminderUpdateResult.saved);
    expect(scheduler.scheduledGoalIds, contains('kitchen-usable'));
    expect(controller.goalById('kitchen-usable')?.reminder, reminder);

    final testResult = await controller.sendTestReminder('kitchen-usable');
    expect(testResult, ReminderUpdateResult.saved);
    expect(scheduler.shownTestGoalIds, contains('kitchen-usable'));

    final restoredController = CleaningAppController(
      repository: repository,
      reminderScheduler: MemoryReminderScheduler(),
    );
    await restoredController.initialize();
    expect(
      restoredController.goalById('kitchen-usable')?.reminder?.hour,
      18,
    );

    final disabled = await controller.setGoalReminder('kitchen-usable', null);
    expect(disabled, ReminderUpdateResult.saved);
    expect(scheduler.cancelledGoalIds, contains('kitchen-usable'));
    expect(controller.goalById('kitchen-usable')?.reminder, isNull);

    controller.dispose();
    restoredController.dispose();
  });

  test('denied notification permission leaves the reminder off', () async {
    final scheduler = MemoryReminderScheduler(permissionGranted: false);
    final controller = CleaningAppController(
      repository: MemoryCleaningRepository.seeded(),
      reminderScheduler: scheduler,
    );
    await controller.initialize();

    const reminder = GoalReminder(
      hour: 9,
      minute: 0,
      weekday: DateTime.monday,
      dayOfMonth: 1,
      month: DateTime.january,
    );
    final result = await controller.setGoalReminder(
      'kitchen-usable',
      reminder,
    );

    expect(result, ReminderUpdateResult.permissionDenied);
    expect(controller.goalById('kitchen-usable')?.reminder, isNull);
    expect(scheduler.scheduledGoalIds, isEmpty);
    controller.dispose();
  });

  test('editing a step preserves its completion history', () async {
    final controller = CleaningAppController(
      repository: MemoryCleaningRepository.seeded(),
      now: () => DateTime(2026, 9, 11, 10),
    );
    await controller.initialize();
    await controller.completeTask('kitchen-counter');
    final original = controller.tasksForGoal('kitchen-usable').first;

    final edited = CleaningTask(
      id: original.id,
      title: 'Clear half of the counter',
      goalId: original.goalId,
      estimatedMinutes: 10,
      energyLevel: EnergyLevel.medium,
      completions: original.completions,
    );

    expect(await controller.updateTask(edited), isTrue);
    final restored = controller.tasksForGoal('kitchen-usable').first;
    expect(restored.title, 'Clear half of the counter');
    expect(restored.completions, hasLength(1));
    expect(controller.isTaskComplete(restored), isTrue);
    controller.dispose();
  });

  test('removing a goal removes its steps and cancels its reminder', () async {
    final scheduler = MemoryReminderScheduler();
    final controller = CleaningAppController(
      repository: MemoryCleaningRepository.seeded(),
      reminderScheduler: scheduler,
    );
    await controller.initialize();

    const reminder = GoalReminder(
      hour: 18,
      minute: 0,
      weekday: DateTime.friday,
      dayOfMonth: 11,
      month: DateTime.september,
    );
    await controller.setGoalReminder('bathroom-reset', reminder);

    expect(await controller.deleteGoal('bathroom-reset'), isTrue);
    expect(controller.goalById('bathroom-reset'), isNull);
    expect(controller.tasksForGoal('bathroom-reset'), isEmpty);
    expect(scheduler.cancelledGoalIds, contains('bathroom-reset'));
    controller.dispose();
  });

  test('task completion can be toggled and remains undone after reload',
      () async {
    final repository = MemoryCleaningRepository.seeded();
    final controller = CleaningAppController(repository: repository);
    await controller.initialize();

    await controller.completeTask('kitchen-counter');
    expect(controller.isTaskComplete(controller.tasks.first), isTrue);

    expect(await controller.toggleTaskCompletion('kitchen-counter'), isTrue);
    expect(controller.isTaskComplete(controller.tasks.first), isFalse);

    final restored = CleaningAppController(repository: repository);
    await restored.initialize();
    expect(restored.isTaskComplete(restored.tasks.first), isFalse);

    controller.dispose();
    restored.dispose();
  });

  test('accessibility preferences survive controller recreation', () async {
    final repository = MemoryCleaningRepository.seeded();
    final controller = CleaningAppController(repository: repository);
    await controller.initialize();

    const preferences = AppPreferences(
      theme: AppThemePreference.dark,
      largerText: true,
      reduceMotion: true,
    );
    expect(await controller.updatePreferences(preferences), isTrue);
    controller.dispose();

    final restored = CleaningAppController(repository: repository);
    await restored.initialize();

    expect(restored.preferences.theme, AppThemePreference.dark);
    expect(restored.preferences.largerText, isTrue);
    expect(restored.preferences.reduceMotion, isTrue);
    restored.dispose();
  });

  test(
      'archiving a goal hides its steps, preserves history, and pauses reminders',
      () async {
    final repository = MemoryCleaningRepository.seeded();
    final scheduler = MemoryReminderScheduler();
    final controller = CleaningAppController(
      repository: repository,
      reminderScheduler: scheduler,
      now: () => DateTime(2026, 9, 11, 10),
    );
    await controller.initialize();
    await controller.completeTask('kitchen-counter');
    await controller.setGoalReminder(
      'kitchen-usable',
      const GoalReminder(
        hour: 18,
        minute: 0,
        weekday: DateTime.friday,
        dayOfMonth: 11,
        month: DateTime.september,
      ),
    );
    final cancellationsBeforeArchive =
        scheduler.cancelledEscalationTaskIds.length;

    expect(await controller.archiveGoal('kitchen-usable'), isTrue);
    expect(controller.goals.map((goal) => goal.id),
        isNot(contains('kitchen-usable')));
    expect(controller.tasks.map((task) => task.id),
        isNot(contains('kitchen-counter')));
    expect(controller.archivedGoals.single.id, 'kitchen-usable');
    expect(scheduler.cancelledGoalIds, contains('kitchen-usable'));
    expect(
      scheduler.cancelledEscalationTaskIds,
      hasLength(cancellationsBeforeArchive),
    );

    final history = CompletionHistory.from(
      goals: controller.allGoals,
      tasks: controller.allTasks,
      now: controller.currentTime,
    );
    expect(
        history.entries.single.taskTitle, 'Clear one section of the counter');

    expect(await controller.restoreGoal('kitchen-usable'), isTrue);
    expect(controller.goals.map((goal) => goal.id), contains('kitchen-usable'));
    expect(
        controller.tasks.map((task) => task.id), contains('kitchen-counter'));
    expect(scheduler.scheduledGoalIds.where((id) => id == 'kitchen-usable'),
        hasLength(2));

    final restored = CleaningAppController(repository: repository);
    await restored.initialize();
    expect(restored.goalById('kitchen-usable')?.isArchived, isFalse);
    expect(
        restored.allTasks
            .firstWhere((task) => task.id == 'kitchen-counter')
            .completions,
        hasLength(1));
    controller.dispose();
    restored.dispose();
  });

  test('archived steps and custom ordering survive controller recreation',
      () async {
    final repository = MemoryCleaningRepository.seeded();
    final controller = CleaningAppController(repository: repository);
    await controller.initialize();

    expect(
      await controller.reorderTasksForGoal('kitchen-usable', 0, 1),
      isTrue,
    );
    expect(await controller.archiveTask('kitchen-counter'), isTrue);
    expect(await controller.reorderGoals(0, 1), isTrue);

    final restored = CleaningAppController(repository: repository);
    await restored.initialize();
    expect(restored.goals.first.id, 'bathroom-reset');
    expect(restored.archivedTasks.single.id, 'kitchen-counter');
    expect(
      restored.tasks.map((task) => task.id),
      isNot(contains('kitchen-counter')),
    );

    expect(await restored.restoreTask('kitchen-counter'), isTrue);
    expect(
      restored.tasksForGoal('kitchen-usable').map((task) => task.id),
      ['five-dishes', 'kitchen-counter'],
    );
    controller.dispose();
    restored.dispose();
  });

  test('preferred schedule controls when a goal appears on Today', () async {
    final repository = MemoryCleaningRepository(
      initialSnapshot: CleaningSnapshot(
        goals: const [
          CleaningGoal(
            id: 'friday-reset',
            title: 'Friday reset',
            room: 'Living room',
            cadence: GoalCadence.weekly,
            energyLevel: EnergyLevel.low,
            schedule: GoalSchedule(weekday: DateTime.friday),
          ),
        ],
        tasks: const [
          CleaningTask(
            id: 'fold-blanket',
            title: 'Fold one blanket',
            goalId: 'friday-reset',
            estimatedMinutes: 2,
            energyLevel: EnergyLevel.low,
          ),
        ],
      ),
    );
    var now = DateTime(2026, 9, 10);
    final controller = CleaningAppController(
      repository: repository,
      now: () => now,
    );
    await controller.initialize();

    expect(controller.activeTasks, hasLength(1));
    expect(controller.tasks, isEmpty);
    now = DateTime(2026, 9, 11);
    controller.refreshForCurrentPeriod();
    expect(controller.tasks.single.id, 'fold-blanket');

    final restored = CleaningAppController(
      repository: repository,
      now: () => now,
    );
    await restored.initialize();
    expect(
        restored.goalById('friday-reset')?.schedule.weekday, DateTime.friday);
    controller.dispose();
    restored.dispose();
  });

  test('reminder limit prevents another goal from enabling notifications',
      () async {
    final scheduler = MemoryReminderScheduler();
    final controller = CleaningAppController(
      repository: MemoryCleaningRepository.seeded(),
      reminderScheduler: scheduler,
    );
    await controller.initialize();
    expect(
      await controller.updatePreferences(
        controller.preferences.copyWith(maxActiveReminders: 1),
      ),
      isTrue,
    );
    const reminder = GoalReminder(
      hour: 18,
      minute: 0,
      weekday: DateTime.saturday,
      dayOfMonth: 12,
      month: DateTime.september,
    );

    expect(
      await controller.setGoalReminder('kitchen-usable', reminder),
      ReminderUpdateResult.saved,
    );
    expect(
      await controller.setGoalReminder('bathroom-reset', reminder),
      ReminderUpdateResult.limitReached,
    );
    expect(controller.goalById('bathroom-reset')?.reminder, isNull);
    controller.dispose();
  });

  test('quiet hours and snooze settings persist and refresh reminders',
      () async {
    final repository = MemoryCleaningRepository.seeded();
    final scheduler = MemoryReminderScheduler();
    final controller = CleaningAppController(
      repository: repository,
      reminderScheduler: scheduler,
    );
    await controller.initialize();
    await controller.setGoalReminder(
      'kitchen-usable',
      const GoalReminder(
        hour: 22,
        minute: 0,
        weekday: DateTime.saturday,
        dayOfMonth: 12,
        month: DateTime.september,
      ),
    );

    final updated = controller.preferences.copyWith(
      quietHoursEnabled: true,
      quietStartMinute: 20 * 60,
      quietEndMinute: 9 * 60,
      snoozeMinutes: 60,
    );
    expect(await controller.updatePreferences(updated), isTrue);
    expect(scheduler.configuredPreferences.quietHoursEnabled, isTrue);
    expect(scheduler.configuredPreferences.snoozeMinutes, 60);
    expect(
      scheduler.scheduledGoalIds.where((id) => id == 'kitchen-usable'),
      hasLength(2),
    );

    final restored = CleaningAppController(repository: repository);
    await restored.initialize();
    expect(restored.preferences.quietStartMinute, 20 * 60);
    expect(restored.preferences.quietEndMinute, 9 * 60);
    expect(restored.preferences.snoozeMinutes, 60);
    controller.dispose();
    restored.dispose();
  });

  test(
      'repeated skips create capped gentle follow-ups and completion cancels them',
      () async {
    final scheduler = MemoryReminderScheduler();
    final controller = CleaningAppController(
      repository: MemoryCleaningRepository.seeded(),
      reminderScheduler: scheduler,
      now: () => DateTime(2026, 9, 12, 10),
    );
    await controller.initialize();
    await controller.setGoalReminder(
      'kitchen-usable',
      const GoalReminder(
        hour: 18,
        minute: 0,
        weekday: DateTime.saturday,
        dayOfMonth: 12,
        month: DateTime.september,
        escalationEnabled: true,
        escalateAfterSkips: 3,
        escalationDelayMinutes: 60,
        maxEscalationsPerPeriod: 2,
      ),
    );

    for (var index = 0; index < 5; index++) {
      expect(await controller.skipTask('kitchen-counter'), isTrue);
    }
    expect(scheduler.escalatedTaskIds, ['kitchen-counter', 'kitchen-counter']);
    expect(
      controller.allTasks
          .firstWhere((task) => task.id == 'kitchen-counter')
          .skips,
      hasLength(5),
    );

    expect(await controller.completeTask('kitchen-counter'), isTrue);
    expect(scheduler.cancelledEscalationTaskIds, contains('kitchen-counter'));
    controller.dispose();
  });
}
