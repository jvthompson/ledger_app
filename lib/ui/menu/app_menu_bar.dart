import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../editor/workbook_controller.dart';
import '../../util/app_dimens.dart';

/// Same visual chrome as Write's AppMenuBar: Flutter's built-in Material
/// MenuBar/SubmenuButton/MenuItemButton widgets, fixed 32px height. Content
/// is spreadsheet-appropriate; anything not implemented this pass is a
/// disabled stub rather than omitted, to keep the menu bar's shape.
class AppMenuBar extends StatelessWidget implements PreferredSizeWidget {
  const AppMenuBar({
    super.key,
    required this.controller,
    this.onNew,
    this.onOpen,
    this.onSave,
    this.onSaveAs,
    this.onExit,
  });

  final WorkbookController controller;
  final VoidCallback? onNew;
  final VoidCallback? onOpen;
  final VoidCallback? onSave;
  final VoidCallback? onSaveAs;
  final VoidCallback? onExit;

  @override
  Size get preferredSize => const Size.fromHeight(AppDimens.menuBarHeight);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppDimens.menuBarHeight,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return MenuBar(
            children: [
              _buildFileMenu(),
              _buildEditMenu(),
              _buildInsertMenu(),
              _buildFormatMenu(),
              _buildViewMenu(),
            ],
          );
        },
      ),
    );
  }

  SubmenuButton _buildFileMenu() {
    return SubmenuButton(
      menuChildren: [
        _item('New', shortcut: const SingleActivator(LogicalKeyboardKey.keyN, control: true), onPressed: onNew),
        _item('Open...', shortcut: const SingleActivator(LogicalKeyboardKey.keyO, control: true), onPressed: onOpen),
        const Divider(),
        _item('Save', shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true), onPressed: onSave),
        _item(
          'Save As...',
          shortcut: const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true),
          onPressed: onSaveAs,
        ),
        const Divider(),
        _item('Exit', onPressed: onExit),
      ],
      child: const Text('File'),
    );
  }

  SubmenuButton _buildEditMenu() {
    return SubmenuButton(
      menuChildren: [
        _item('Undo', shortcut: const SingleActivator(LogicalKeyboardKey.keyZ, control: true), onPressed: null),
        _item('Redo', shortcut: const SingleActivator(LogicalKeyboardKey.keyY, control: true), onPressed: null),
        const Divider(),
        _item('Cut', shortcut: const SingleActivator(LogicalKeyboardKey.keyX, control: true), onPressed: null),
        _item('Copy', shortcut: const SingleActivator(LogicalKeyboardKey.keyC, control: true), onPressed: null),
        _item('Paste', shortcut: const SingleActivator(LogicalKeyboardKey.keyV, control: true), onPressed: null),
        const Divider(),
        _item(
          'Clear Cell',
          shortcut: const SingleActivator(LogicalKeyboardKey.delete),
          onPressed: controller.clearSelectedCell,
        ),
        _item('Select All', shortcut: const SingleActivator(LogicalKeyboardKey.keyA, control: true), onPressed: null),
      ],
      child: const Text('Edit'),
    );
  }

  SubmenuButton _buildInsertMenu() {
    return SubmenuButton(
      menuChildren: [
        _item('Row Above', onPressed: null),
        _item('Row Below', onPressed: null),
        const Divider(),
        _item('Column Left', onPressed: null),
        _item('Column Right', onPressed: null),
      ],
      child: const Text('Insert'),
    );
  }

  SubmenuButton _buildFormatMenu() {
    return SubmenuButton(
      menuChildren: [
        _item('Number Format...', onPressed: null),
        _item('Cell Color...', onPressed: null),
      ],
      child: const Text('Format'),
    );
  }

  SubmenuButton _buildViewMenu() {
    return SubmenuButton(
      menuChildren: [
        _item('Freeze Panes', onPressed: null),
      ],
      child: const Text('View'),
    );
  }

  MenuItemButton _item(String label, {MenuSerializableShortcut? shortcut, VoidCallback? onPressed}) {
    return MenuItemButton(
      shortcut: shortcut,
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
