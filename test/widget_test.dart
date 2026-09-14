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
    await tester.ensureVisible(find.text('Save goal'));
    await tester.pump();
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

  testWidgets('starter templates add an editable room bundle', (tester) async {
    await _pumpSeededApp(tester);
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Starter templates'), findsOneWidget);
    await tester.tap(find.text('Starter templates'));
    await tester.pumpAndSettle();

    expect(find.text('Starter templates'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);
    await tester.tap(find.text('Add this starter').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('added with 3 small steps'), findsOneWidget);
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
    await tester.tap(find.text('One-time'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('5 minutes'));
    await tester.pumpAndSettle();
    expect(find.text('60 minutes'), findsOneWidget);
    await tester.tap(find.text('60 minutes'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add to Today'));
    await tester.pump();
    await tester.tap(find.text('Add to Today'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Put three things away'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Put three things away'), findsOneWidget);
    expect(find.textContaining('One-time'), findsWidgets);
    expect(find.textContaining('60 min'), findsWidgets);

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

    await tester.ensureVisible(find.text('Start 5 min timer'));
    await tester.pump();
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
    await tester.scrollUntilVisible(
      find.text('1 of 3 small steps complete'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('1 of 3 small steps complete'), findsOneWidget);
  });

  testWidgets('stopping a timer does not complete the step', (tester) async {
    await _pumpSeededApp(tester);

    await tester.ensureVisible(find.text('Start 5 min timer'));
    await tester.pump();
    await tester.tap(find.text('Start 5 min timer'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Stop for now'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Stop for now'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('0 of 3 small steps complete'),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
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
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('Every day at 6:00 PM'), findsOneWidget);
    expect(find.text('Gentle persistence'), findsOneWidget);
    expect(
      find.text('Offer a quiet follow-up after repeated skips.'),
      findsOneWidget,
    );
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

    await tester.tap(find.byType(Switch).first);
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
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
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

    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pump();
    expect(find.text('Recent activity'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Clear one section of the counter'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Clear one section of the counter'), findsOneWidget);
    expect(find.text('Keep the kitchen usable · Kitchen'), findsOneWidget);
    expect(find.text('10:15 AM'), findsOneWidget);
    await tester.tap(find.text('Clear one section of the counter'));
    await tester.pumpAndSettle();
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('Estimated time'), findsOneWidget);
    expect(find.text('Low energy'), findsOneWidget);
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
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pump();
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
    await tester.ensureVisible(find.text('Save changes'));
    await tester.pump();
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
    await tester.tap(find.byType(Slider));
    await tester.pumpAndSettle();
    final largerScale = MediaQuery.textScalerOf(
      tester.element(heading),
    ).scale(16);
    expect(largerScale, greaterThan(initialScale));

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(Theme.of(tester.element(heading)).brightness, Brightness.dark);
    expect(find.text('Settings'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Reduce motion'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    final reduceMotion = find.text('Reduce motion');
    await tester.ensureVisible(reduceMotion);
    await tester.pump();
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

  testWidgets('rescue mode matches one task to the selected energy',
      (tester) async {
    await _pumpSeededApp(
      tester,
      now: () => DateTime(2026, 9, 12, 10),
    );

    expect(find.text('Clear one section of the counter'), findsWidgets);
    await tester.tap(find.text('Choose'));
    await tester.pumpAndSettle();
    expect(find.text('What energy do you have?'), findsOneWidget);
    await tester.tap(find.text('Medium energy').last);
    await tester.pumpAndSettle();

    expect(find.text('Medium energy match'), findsOneWidget);
    expect(find.text('Wipe the bathroom sink'), findsWidgets);
    expect(
      find.text('Exact matches come first, then gentler options.'),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Show any energy level'));
    await tester.pumpAndSettle();
    expect(find.text('Do one thing'), findsOneWidget);
    expect(find.text('Clear one section of the counter'), findsWidgets);
  });

  testWidgets('quiet hours and snooze controls are available in settings',
      (tester) async {
    await _pumpSeededApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Active reminder limit'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Active reminder limit'), findsOneWidget);
    expect(find.text('Snooze length'), findsOneWidget);
    await tester.tap(find.text('Quiet hours'));
    await tester.pumpAndSettle();

    expect(find.text('Quiet hours begin'), findsOneWidget);
    expect(find.text('Reminders resume'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('1 hour'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('15 min'), findsOneWidget);
    expect(find.text('30 min'), findsOneWidget);
    expect(find.text('1 hour'), findsOneWidget);
  });

  testWidgets('a task can be skipped for now', (tester) async {
    await _pumpSeededApp(tester);
    await tester.ensureVisible(find.text('Skip for now'));
    await tester.pump();
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(
      find.text('Skipped for now. You can come back when you are ready.'),
      findsOneWidget,
    );
  });

  testWidgets('a new user can skip onboarding and enter the app',
      (tester) async {
    await tester.pumpWidget(
      CleaningSupportApp(
        repository: MemoryCleaningRepository(),
        reminderScheduler: MemoryReminderScheduler(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Let’s make this easier to begin.'), findsOneWidget);
    expect(
      find.textContaining('creates a small, editable pool'),
      findsOneWidget,
    );
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pump();
    await tester.ensureVisible(find.text('Start gently'));
    expect(find.text('Start gently'), findsOneWidget);
    await tester.ensureVisible(find.text('Skip setup for now'));
    await tester.tap(find.text('Skip setup for now'));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsWidgets);
  });

  testWidgets('guided setup can add goals without replacing existing ones',
      (tester) async {
    await _pumpSeededApp(tester);
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add rooms and starter goals'));
    await tester.pumpAndSettle();

    expect(find.text('Guided setup'), findsOneWidget);
    expect(
      find.textContaining('without replacing anything'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.textContaining('Already added'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('Already added'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Bedroom'),
      -300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Bedroom'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Make the bedroom restful'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Make the bedroom restful'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Add selected goals'));
    await tester.tap(find.text('Add selected goals'));
    await tester.pumpAndSettle();

    expect(find.text('Starter goals added.'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Keep the kitchen usable'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Make the bedroom restful'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Make the bedroom restful'), findsOneWidget);
  });

  testWidgets('Power Hour builds a buffered plan for available time and energy',
      (tester) async {
    await _pumpSeededApp(
      tester,
      now: () => DateTime(2026, 9, 14, 10),
    );
    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();

    expect(find.text('Power Hour'), findsOneWidget);
    expect(find.textContaining('leaves breathing room'), findsOneWidget);
    await tester.tap(find.text('15 min'));
    await tester.tap(find.text('Build my plan'));
    await tester.pumpAndSettle();

    expect(find.text('Your gentle plan'), findsOneWidget);
    expect(find.textContaining('7 of 15 minutes planned'), findsOneWidget);
    expect(find.textContaining('0 of 2 done'), findsOneWidget);

    final markComplete = find.byTooltip('Mark complete').first;
    await tester.ensureVisible(markComplete);
    await tester.pump();
    await tester.tap(markComplete);
    await tester.pumpAndSettle();
    expect(find.textContaining('1 of 2 done'), findsOneWidget);
  });

  testWidgets('an optional deadline adds gentle pacing without overdue work',
      (tester) async {
    await _pumpSeededApp(
      tester,
      now: () => DateTime(2026, 9, 14, 10),
    );
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep the kitchen usable'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Goal options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit goal'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Add a gentle deadline'));
    await tester.tap(find.text('Add a gentle deadline'));
    await tester.pumpAndSettle();
    expect(find.text('Breathing-room target'), findsOneWidget);
    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Gentle deadline pace'), findsOneWidget);
    expect(find.textContaining('Aim for'), findsOneWidget);
    expect(find.textContaining('no backlog'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.today_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Gentle deadline pace'), findsOneWidget);
    expect(
      find.text('A suggestion for today, never an overdue backlog.'),
      findsOneWidget,
    );
  });

  testWidgets('small-step search exposes task filters', (tester) async {
    await _pumpSeededApp(tester);
    await tester.tap(find.byIcon(Icons.flag_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.search_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Find a small step'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Cadence'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('Clear one section of the counter'), findsOneWidget);
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
