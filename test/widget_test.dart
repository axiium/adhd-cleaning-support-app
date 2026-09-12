import 'package:adhd_cleaning_support/app.dart';
import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:adhd_cleaning_support/features/reminders/application/reminder_scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('completing a task advances gentle progress', (tester) async {
    await _pumpSeededApp(tester);

    expect(find.text('0 of 3 small steps complete'), findsOneWidget);

    await tester.ensureVisible(find.text('I did it'));
    await tester.pump();
    await tester.tap(find.text('I did it'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('1 of 3 small steps complete'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 of 3 small steps complete'), findsOneWidget);
    expect(find.text('Put away five dishes'), findsWidgets);
  });

  testWidgets('an accidental completion can be undone immediately',
      (tester) async {
    await _pumpSeededApp(tester);

    await tester.ensureVisible(find.text('I did it'));
    await tester.pump();
    await tester.tap(find.text('I did it'));
    await tester.pumpAndSettle();

    expect(find.text('Small step completed.'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('0 of 3 small steps complete'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('0 of 3 small steps complete'), findsOneWidget);
    expect(find.text('Clear one section of the counter'), findsWidgets);
  });

  testWidgets('a user can create a cleaning goal', (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add goal'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'What would you like to maintain?'),
      'Keep the entryway clear',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Room or area'),
      'Entryway',
    );
    await tester.tap(find.text('Save goal'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Keep the entryway clear'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Keep the entryway clear'), findsOneWidget);
    expect(find.text('Entryway'), findsOneWidget);
    expect(
      find.text('Goal added. Add one tiny first step.'),
      findsOneWidget,
    );
  });

  testWidgets('a new small step appears on Today', (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep the kitchen usable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add small step'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Small action'),
      'Put three things away',
    );
    await tester.tap(find.text('Add to Today'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Put three things away'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Put three things away'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Put three things away'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Put three things away'), findsOneWidget);
  });

  testWidgets('focus timer can pause and finish early', (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.text('Start 5 min timer'));
    await tester.pumpAndSettle();

    expect(find.text('Focus timer'), findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Resume'), findsOneWidget);

    await tester.ensureVisible(find.text('Finish early'));
    await tester.pump();
    await tester.tap(find.text('Finish early'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
    expect(find.text('1 of 3 small steps complete'), findsOneWidget);
  });

  testWidgets('stopping a timer does not complete the step', (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.text('Start 5 min timer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Stop for now'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Stop for now'));
    await tester.pumpAndSettle();

    expect(find.text('0 of 3 small steps complete'), findsOneWidget);
    expect(find.text('Clear one section of the counter'), findsWidgets);
  });

  testWidgets('resuming on a new day refreshes recurring steps',
      (tester) async {
    var now = DateTime(2026, 9, 10, 10);
    await _pumpSeededApp(tester, now: () => now);

    await tester.ensureVisible(find.text('I did it'));
    await tester.pump();
    await tester.tap(find.text('I did it'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('1 of 3 small steps complete'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 of 3 small steps complete'), findsOneWidget);

    now = DateTime(2026, 9, 11, 8);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('0 of 3 small steps complete'), findsOneWidget);
    expect(find.text('Clear one section of the counter'), findsWidgets);
  });

  testWidgets('a user can turn a gentle goal reminder on and off',
      (tester) async {
    final scheduler = MemoryReminderScheduler();
    await _pumpSeededApp(tester, reminderScheduler: scheduler);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep the kitchen usable'));
    await tester.pumpAndSettle();

    expect(
      find.text('Off — no notification unless you choose one.'),
      findsOneWidget,
    );
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Every day at 6:00 PM'), findsOneWidget);
    expect(find.text('Gentle reminder scheduled.'), findsOneWidget);
    expect(scheduler.scheduledGoalIds, contains('kitchen-usable'));

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.text('Send test now'));
    await tester.pumpAndSettle();
    expect(
      find.text('Test reminder sent. Check your notification shade.'),
      findsOneWidget,
    );
    expect(scheduler.shownTestGoalIds, contains('kitchen-usable'));

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    expect(
      find.text('Off — no notification unless you choose one.'),
      findsOneWidget,
    );
    expect(scheduler.cancelledGoalIds, contains('kitchen-usable'));
  });

  testWidgets('history starts with a permission-giving empty state',
      (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    expect(find.text('What you have done counts.'), findsOneWidget);
    expect(
      find.text('Nothing recorded yet — and there is no catching up to do.'),
      findsOneWidget,
    );
  });

  testWidgets('a completed step appears in gentle history', (tester) async {
    await _pumpSeededApp(
      tester,
      now: () => DateTime(2026, 9, 11, 10, 15),
    );

    await tester.ensureVisible(find.text('I did it'));
    await tester.pump();
    await tester.tap(find.text('I did it'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.history_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Recent activity'), findsOneWidget);
    expect(find.text('Clear one section of the counter'), findsOneWidget);
    expect(find.text('Keep the kitchen usable · Kitchen'), findsOneWidget);
    expect(find.text('10:15 AM'), findsOneWidget);
  });

  testWidgets('a user can edit a goal and a small step', (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep the kitchen usable'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Goal options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit goal'));
    await tester.pumpAndSettle();
    final goalName = find.widgetWithText(
      TextFormField,
      'What would you like to maintain?',
    );
    await tester.enterText(goalName, 'Keep the kitchen comfortable');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Keep the kitchen comfortable'), findsOneWidget);
    expect(find.text('Goal updated.'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byTooltip('Step options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit step'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Small action'),
      'Clear half of the counter',
    );
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Clear half of the counter'), findsOneWidget);
    expect(find.text('Small step updated.'), findsOneWidget);
  });

  testWidgets('removing a step requires explicit confirmation', (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep the kitchen usable'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Step options').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove step'));
    await tester.pumpAndSettle();

    expect(find.text('Remove this small step?'), findsOneWidget);
    expect(find.textContaining('This cannot be undone.'), findsOneWidget);
    await tester.tap(find.text('Keep step'));
    await tester.pumpAndSettle();

    expect(find.text('Clear one section of the counter'), findsOneWidget);
  });

  testWidgets('a completed task row can be marked as not done', (tester) async {
    await _pumpSeededApp(tester);

    await tester.ensureVisible(find.text('I did it'));
    await tester.pump();
    await tester.tap(find.text('I did it'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byTooltip('Mark as not done'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Mark complete'), findsNWidgets(3));
  });

  testWidgets('accessibility settings apply immediately', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpSeededApp(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Make the app easier to use.'), findsOneWidget);

    final heading = find.text('Make the app easier to use.');
    final initialScale = MediaQuery.textScalerOf(
      tester.element(heading),
    ).scale(16);
    await tester.tap(find.text('Larger text'));
    await tester.pumpAndSettle();
    final largerScale = MediaQuery.textScalerOf(
      tester.element(heading),
    ).scale(16);
    expect(largerScale, greaterThan(initialScale));

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(heading)).brightness, Brightness.dark);
    expect(find.text('Settings'), findsWidgets);

    final reduceMotion = find.text('Reduce motion');
    await tester.tap(reduceMotion);
    await tester.pumpAndSettle();
    expect(
      MediaQuery.of(tester.element(reduceMotion)).disableAnimations,
      isTrue,
    );
  });

  testWidgets('a goal can be archived and restored without deleting it',
      (tester) async {
    await _pumpSeededApp(tester);

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep the kitchen usable'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Goal options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Archive goal'));
    await tester.pumpAndSettle();

    expect(find.text('Keep the kitchen usable'), findsNothing);
    expect(find.textContaining('history is still safe'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.tap(find.byTooltip('Archived items'));
    await tester.pumpAndSettle();
    expect(find.text('Keep the kitchen usable'), findsOneWidget);

    await tester.tap(find.byTooltip('Archived goal options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Restore goal'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing is archived.'), findsOneWidget);
    expect(find.text('Goal restored.'), findsOneWidget);
  });

  testWidgets('a preferred weekday controls when steps appear on Today',
      (tester) async {
    await _pumpSeededApp(
      tester,
      now: () => DateTime(2026, 9, 10, 10),
    );

    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Weekly bathroom reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Goal options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit goal'));
    await tester.pumpAndSettle();

    expect(find.text('Preferred weekday'), findsOneWidget);
    await tester.tap(find.text('Monday').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Friday').last);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pump();
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Available from Friday each week'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('0 of 2 small steps complete'), findsOneWidget);
    expect(find.text('Wipe the bathroom sink'), findsNothing);
  });
}

Future<void> _pumpSeededApp(
  WidgetTester tester, {
  DateTime Function()? now,
  ReminderScheduler? reminderScheduler,
}) async {
  await tester.pumpWidget(
    CleaningSupportApp(
      repository: MemoryCleaningRepository.seeded(),
      reminderScheduler: reminderScheduler ?? MemoryReminderScheduler(),
      now: now,
    ),
  );
  await tester.pumpAndSettle();
}
