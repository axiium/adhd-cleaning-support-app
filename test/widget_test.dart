import 'package:adhd_cleaning_support/app.dart';
import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
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
}

Future<void> _pumpSeededApp(WidgetTester tester) async {
  await tester.pumpWidget(
    CleaningSupportApp(repository: MemoryCleaningRepository.seeded()),
  );
  await tester.pumpAndSettle();
}
