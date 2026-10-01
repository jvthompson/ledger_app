import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../editor/workbook_controller.dart';
import '../../util/cell_ref.dart';

/// The single live text-editing widget for whichever cell is currently
/// being edited. Positioned by the caller over that cell's on-screen rect;
/// only one instance ever exists regardless of grid size.
class CellEditorOverlay extends StatelessWidget {
  const CellEditorOverlay({
    super.key,
    required this.controller,
    required this.editController,
    required this.editFocusNode,
  });

  final WorkbookController controller;
  final TextEditingController editController;
  final FocusNode editFocusNode;

  void _commitAndMove(int dCol, int dRow) {
    final cell = controller.editingCell;
    if (cell == null) return;
    controller.commitEdit(
      editController.text,
      moveTo: CellRef(cell.row + dRow, cell.col + dCol),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            controller.cancelEdit();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.tab) {
            final shift = HardwareKeyboard.instance.isShiftPressed;
            _commitAndMove(shift ? -1 : 1, 0);
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: TextField(
          controller: editController,
          focusNode: editFocusNode,
          autofocus: true,
          maxLines: 1,
          style: const TextStyle(fontSize: 13),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            border: OutlineInputBorder(borderRadius: BorderRadius.zero),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Colors.blue, width: 2),
            ),
          ),
          onSubmitted: (_) => _commitAndMove(0, 1),
        ),
      ),
    );
  }
}
