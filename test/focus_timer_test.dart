import 'package:adhd_cleaning_support/core/persistence/cleaning_repository.dart';
import 'package:adhd_cleaning_support/core/state/cleaning_app_controller.dart';
import 'package:adhd_cleaning_support/core/state/cleaning_app_scope.dart';
import 'package:adhd_cleaning_support/features/timer/presentation/focus_timer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('timer ending asks the user whether the step is done', (
    tester,
  ) async {
    final controller = CleaningAppController(
      repository: MemoryCleaningRepository.seeded(),
    );
    await controller.initialize();
    var now = DateTime(2026, 9, 10, 12);

    await tester.pumpWidget(
      CleaningAppScope(
        controller: controller,
        child: MaterialApp(
          home: FocusTimerScreen(
            taskId: 'kitchen-counter',
            taskTitle: 'Clear one section of the counter',
            goalTitle: 'Keep the kitchen usable',
            duration: const Duration(seconds: 1),
            now: () => now,
          ),
        ),
      ),
    );

    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Time is up. The effort still counts.'), findsOneWidget);
    expect(find.text('Mark step done'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
