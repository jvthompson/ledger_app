import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';

import '../../editor/workbook_controller.dart';
import '../../util/app_dimens.dart';
import '../../util/cell_ref.dart';
import 'cell_editor_overlay.dart';

/// The Excel-like grid: virtualized, with a pinned header row (column
/// letters) and header column (row numbers), click/keyboard selection, and
/// a single positioned text-edit overlay for whichever cell is being
/// edited.
class SheetGridView extends StatefulWidget {
  const SheetGridView({super.key, required this.controller});

  final WorkbookController controller;

  @override
  State<SheetGridView> createState() => _SheetGridViewState();
}

class _SheetGridViewState extends State<SheetGridView> {
  static const double headerColWidth = 48;
  static const double dataColWidth = 100;
  static const double headerRowHeight = 28;
  static const double dataRowHeight = 24;

  final ScrollController _verticalController = ScrollController();
  final ScrollController _horizontalController = ScrollController();
  final FocusNode _gridFocusNode = FocusNode(debugLabel: 'SheetGrid');
  final TextEditingController _editController = TextEditingController();
  final FocusNode _editFocusNode = FocusNode(debugLabel: 'CellEditor');

  CellRef? _lastEditingCell;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
    _verticalController.addListener(_onScroll);
    _horizontalController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    _verticalController.dispose();
    _horizontalController.dispose();
    _gridFocusNode.dispose();
    _editController.dispose();
    _editFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (mounted) setState(() {});
  }

  void _onControllerChanged() {
    final controller = widget.controller;
    if (controller.editingCell != null &&
        controller.editingCell != _lastEditingCell) {
      _lastEditingCell = controller.editingCell;
      _editController.text = controller.editingInitialText;
      _editController.selection =
          TextSelection.collapsed(offset: _editController.text.length);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _editFocusNode.requestFocus();
      });
    } else if (controller.editingCell == null && _lastEditingCell != null) {
      _lastEditingCell = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _gridFocusNode.requestFocus();
      });
    }
    _scrollSelectionIntoView();
    if (mounted) setState(() {});
  }

  void _scrollSelectionIntoView() {
    final sel = widget.controller.selection;
    if (_verticalController.hasClients) {
      final pos = _verticalController.position;
      final dataViewportHeight = pos.viewportDimension - headerRowHeight;
      final rowTop = sel.row * dataRowHeight;
      final rowBottom = rowTop + dataRowHeight;
      if (rowTop < pos.pixels) {
        _verticalController.jumpTo(rowTop.clamp(0.0, pos.maxScrollExtent));
      } else if (rowBottom > pos.pixels + dataViewportHeight) {
        _verticalController.jumpTo(
          (rowBottom - dataViewportHeight).clamp(0.0, pos.maxScrollExtent),
        );
      }
    }
    if (_horizontalController.hasClients) {
      final pos = _horizontalController.position;
      final dataViewportWidth = pos.viewportDimension - headerColWidth;
      final colLeft = sel.col * dataColWidth;
      final colRight = colLeft + dataColWidth;
      if (colLeft < pos.pixels) {
        _horizontalController.jumpTo(colLeft.clamp(0.0, pos.maxScrollExtent));
      } else if (colRight > pos.pixels + dataViewportWidth) {
        _horizontalController.jumpTo(
          (colRight - dataViewportWidth).clamp(0.0, pos.maxScrollExtent),
        );
      }
    }
  }

  KeyEventResult _handleGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final controller = widget.controller;
    if (controller.isEditing) {
      // The cell-edit TextField is focused; let its own key handling (and
      // the platform text input channel) process the keystroke. Without
      // this guard, every character bubbles up to this handler (which sits
      // above the TextField in the Focus tree), gets treated as "start a
      // new edit", and returning `handled` here suppresses the framework
      // from also delivering the character to the focused TextField.
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowUp) {
      controller.moveSelection(0, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      controller.moveSelection(0, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      controller.moveSelection(-1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      controller.moveSelection(1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      final shift = HardwareKeyboard.instance.isShiftPressed;
      controller.moveSelection(shift ? -1 : 1, 0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      controller.moveSelection(0, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.f2) {
      controller.beginEdit();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      controller.clearSelectedCell();
      return KeyEventResult.handled;
    }

    if (event is KeyDownEvent) {
      final char = event.character;
      final hk = HardwareKeyboard.instance;
      if (char != null &&
          char.isNotEmpty &&
          !hk.isControlPressed &&
          !hk.isMetaPressed &&
          !hk.isAltPressed) {
        controller.beginEdit(seedChar: char);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  TableSpan _columnBuilder(int index) => TableSpan(
        extent: FixedTableSpanExtent(index == 0 ? headerColWidth : dataColWidth),
      );

  TableSpan _rowBuilder(int index) => TableSpan(
        extent: FixedTableSpanExtent(index == 0 ? headerRowHeight : dataRowHeight),
      );

  TableViewCell _cellBuilder(BuildContext context, TableVicinity vicinity) {
    if (vicinity.row == 0 && vicinity.column == 0) {
      return _cornerCell(context);
    }
    if (vicinity.row == 0) {
      return _columnHeaderCell(context, vicinity.column - 1);
    }
    if (vicinity.column == 0) {
      return _rowHeaderCell(context, vicinity.row - 1);
    }
    return _dataCell(context, CellRef(vicinity.row - 1, vicinity.column - 1));
  }

  TableViewCell _cornerCell(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TableViewCell(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: const Border(
            right: BorderSide(color: AppDimens.borderColor),
            bottom: BorderSide(color: AppDimens.borderColor),
          ),
        ),
      ),
    );
  }

  TableViewCell _columnHeaderCell(BuildContext context, int col) {
    final scheme = Theme.of(context).colorScheme;
    return TableViewCell(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: const Border(
            right: BorderSide(color: AppDimens.borderColor),
            bottom: BorderSide(color: AppDimens.borderColor),
          ),
        ),
        child: Center(
          child: Text(
            columnLetters(col),
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }

  TableViewCell _rowHeaderCell(BuildContext context, int row) {
    final scheme = Theme.of(context).colorScheme;
    return TableViewCell(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          border: const Border(
            right: BorderSide(color: AppDimens.borderColor),
            bottom: BorderSide(color: AppDimens.borderColor),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${row + 1}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ),
    );
  }

  TableViewCell _dataCell(BuildContext context, CellRef ref) {
    final controller = widget.controller;
    final isSelected = !controller.isEditing && ref == controller.selection;
    final text = controller.activeSheet.textAt(ref);
    final scheme = Theme.of(context).colorScheme;
    return TableViewCell(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Use onTapDown (fires immediately on pointer-down) rather than
        // onTap for selection: onTap shares a GestureDetector with
        // onDoubleTap below, so it would wait out kDoubleTapTimeout
        // (~300ms) every click to see if a second tap follows, before
        // committing to a single tap.
        onTapDown: (_) {
          _gridFocusNode.requestFocus();
          controller.selectCell(ref);
        },
        onDoubleTap: () {
          _gridFocusNode.requestFocus();
          controller.selectCell(ref);
          controller.beginEdit();
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            border: const Border(
              right: BorderSide(color: AppDimens.borderColor),
              bottom: BorderSide(color: AppDimens.borderColor),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.clip,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: scheme.primary, width: 2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditOverlay() {
    final controller = widget.controller;
    final cell = controller.editingCell!;
    final vOffset = _verticalController.hasClients ? _verticalController.offset : 0.0;
    final hOffset = _horizontalController.hasClients ? _horizontalController.offset : 0.0;
    final left = headerColWidth + cell.col * dataColWidth - hOffset;
    final top = headerRowHeight + cell.row * dataRowHeight - vOffset;
    return Positioned(
      left: left,
      top: top,
      width: dataColWidth,
      height: dataRowHeight,
      child: CellEditorOverlay(
        controller: controller,
        editController: _editController,
        editFocusNode: _editFocusNode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final sheet = controller.activeSheet;
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Focus(
          focusNode: _gridFocusNode,
          autofocus: true,
          onKeyEvent: _handleGridKey,
          child: ClipRect(
            child: Stack(
              children: [
                TableView.builder(
                  verticalDetails:
                      ScrollableDetails.vertical(controller: _verticalController),
                  horizontalDetails: ScrollableDetails.horizontal(
                    controller: _horizontalController,
                  ),
                  pinnedRowCount: 1,
                  pinnedColumnCount: 1,
                  columnCount: sheet.columnCount + 1,
                  rowCount: sheet.rowCount + 1,
                  columnBuilder: _columnBuilder,
                  rowBuilder: _rowBuilder,
                  cellBuilder: _cellBuilder,
                ),
                if (controller.isEditing) _buildEditOverlay(),
              ],
            ),
          ),
        );
      },
    );
  }
}
