import 'package:flutter/material.dart';

import '../../features/today/domain/cleaning_task.dart';
import '../state/cleaning_app_controller.dart';

void showTaskCompletionFeedback({
  required BuildContext context,
  required CleaningTask task,
  required CleaningAppController controller,
}) {
  final messenger = ScaffoldMessenger.of(context);
  final actionColor = Theme.of(context).colorScheme.inversePrimary;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 7),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Small step completed.'),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: 4,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: actionColor),
                  onPressed: () async {
                    messenger.hideCurrentSnackBar();
                    final saved = await controller.undoTaskCompletion(task.id);
                    if (!context.mounted || saved) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'That completion could not be undone. Please try again.',
                        ),
                      ),
                    );
                  },
                  child: const Text('Undo'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: actionColor),
                  onPressed: () async {
                    messenger.hideCurrentSnackBar();
                    final saved = await controller.archiveTask(task.id);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          saved
                              ? 'Step archived. Its history is still safe.'
                              : 'That step could not be archived. Please try again.',
                        ),
                        action: saved
                            ? SnackBarAction(
                                label: 'Restore',
                                onPressed: () =>
                                    controller.restoreTask(task.id),
                              )
                            : null,
                      ),
                    );
                  },
                  child: const Text('Done for good'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
