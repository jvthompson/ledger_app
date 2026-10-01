import 'package:flutter/material.dart';

import '../../editor/workbook_controller.dart';
import '../../util/app_dimens.dart';

/// Same shell as Write's StatusBar: thin bar, colorScheme.surfaceContainerHighest.
class StatusBar extends StatelessWidget {
  const StatusBar({super.key, required this.controller});

  final WorkbookController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: SizedBox(
            height: AppDimens.statusBarHeight,
            child: Row(
              children: [
                const SizedBox(width: 8),
                Text(controller.selection.a1, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 16),
                Text(controller.activeSheet.name, style: const TextStyle(fontSize: 12)),
                const Spacer(),
              ],
            ),
          ),
        );
      },
    );
  }
}
