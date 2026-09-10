import 'package:flutter/widgets.dart';

import 'cleaning_app_controller.dart';

class CleaningAppScope extends InheritedNotifier<CleaningAppController> {
  const CleaningAppScope({
    required CleaningAppController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static CleaningAppController of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<CleaningAppScope>();
    assert(scope != null, 'No CleaningAppScope found in this context.');
    return scope!.notifier!;
  }
}
