import 'package:flutter/foundation.dart';

import '../model/workbook.dart';
import '../util/cell_ref.dart';

/// Owns selection/editing state for the active sheet and mutates the
/// [Workbook] model. Mirrors Write's EditorController: the grid UI reads
/// from this and dispatches user actions through its methods.
class WorkbookController extends ChangeNotifier {
  Workbook workbook;
  int activeSheetIndex = 0;

  CellRef selection = const CellRef(0, 0);

  /// Non-null while a cell is in edit mode.
  CellRef? editingCell;

  /// Seed text for the edit TextField when [editingCell] is set.
  String editingInitialText = '';

  int _editVersion = 0;

  /// Increments on every committed mutation. Used by WorkbookSession for
  /// dirty-tracking (compare against the last-seen value, not raw
  /// notifyListeners() calls).
  int get editVersion => _editVersion;

  WorkbookController(this.workbook);

  Sheet get activeSheet => workbook.sheets[activeSheetIndex];

  bool get isEditing => editingCell != null;

  void selectCell(CellRef ref) {
    selection = _clamp(ref);
    notifyListeners();
  }

  void moveSelection(int dCol, int dRow) {
    selectCell(CellRef(selection.row + dRow, selection.col + dCol));
  }

  /// Enters edit mode on the current selection. If [seedChar] is given the
  /// editor starts with just that character (Excel's "type to replace"
  /// behavior); otherwise it starts with the cell's existing text.
  void beginEdit({String? seedChar}) {
    editingCell = selection;
    editingInitialText = seedChar ?? activeSheet.textAt(selection);
    notifyListeners();
  }

  void commitEdit(String text, {CellRef? moveTo}) {
    final target = editingCell;
    if (target == null) return;
    activeSheet.setText(target, text);
    _editVersion++;
    editingCell = null;
    selectCell(moveTo ?? target);
  }

  void cancelEdit() {
    editingCell = null;
    notifyListeners();
  }

  void clearSelectedCell() {
    activeSheet.setText(selection, '');
    _editVersion++;
    notifyListeners();
  }

  void loadWorkbook(Workbook newWorkbook) {
    workbook = newWorkbook;
    activeSheetIndex = 0;
    selection = const CellRef(0, 0);
    editingCell = null;
    _editVersion = 0;
    notifyListeners();
  }

  CellRef _clamp(CellRef r) => CellRef(
        r.row.clamp(0, activeSheet.rowCount - 1),
        r.col.clamp(0, activeSheet.columnCount - 1),
      );
}
