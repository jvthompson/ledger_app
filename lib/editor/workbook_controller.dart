import 'package:flutter/foundation.dart';

import '../model/workbook.dart';
import '../util/cell_ref.dart';

/// Owns selection/editing state for the active sheet and mutates the
/// [Workbook] model. Mirrors Write's EditorController: the grid UI reads
/// from this and dispatches user actions through its methods.
///
/// This is the only sanctioned mutation path for cell content — the model
/// exposes no public mutators — so every content change flows through here
/// and is reflected in [editVersion] for dirty tracking.
class WorkbookController extends ChangeNotifier {
  Workbook workbook;
  int activeSheetIndex = 0;

  CellRef selection = const CellRef(0, 0);

  /// Non-null while a cell is in edit mode.
  CellRef? editingCell;

  /// Seed text for the edit TextField when [editingCell] is set.
  String editingInitialText = '';

  /// Latest text from the edit field, pushed by the UI on every keystroke
  /// via [updateEditText]. Lets [selectCell] commit (rather than abandon)
  /// an in-progress edit when the user clicks another cell, Excel-style.
  String _editText = '';

  int _editVersion = 0;

  /// Increments on every committed mutation. Used by WorkbookSession for
  /// dirty-tracking (compare against the last-seen value, not raw
  /// notifyListeners() calls).
  int get editVersion => _editVersion;

  WorkbookController(this.workbook);

  Sheet get activeSheet => workbook.sheets[activeSheetIndex];

  bool get isEditing => editingCell != null;

  void selectCell(CellRef ref) {
    _commitPendingEdit();
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
    _commitPendingEdit();
    editingCell = selection;
    editingInitialText = seedChar ?? activeSheet.textAt(selection);
    _editText = editingInitialText;
    notifyListeners();
  }

  /// Records the edit field's current text. Called by the grid on every
  /// keystroke so a click-away can commit the in-progress edit instead of
  /// silently discarding it.
  void updateEditText(String text) {
    _editText = text;
  }

  void commitEdit(String text, {CellRef? moveTo}) {
    final target = editingCell;
    if (target == null) return;
    _applyEdit(target, text);
    editingCell = null;
    selectCell(moveTo ?? target);
  }

  void cancelEdit() {
    editingCell = null;
    notifyListeners();
  }

  void clearSelectedCell() {
    if (activeSheet.textAt(selection).isEmpty) return;
    activeSheet.setText(selection, '');
    _editVersion++;
    notifyListeners();
  }

  void loadWorkbook(Workbook newWorkbook) {
    workbook = newWorkbook;
    activeSheetIndex = newWorkbook.sheets.isEmpty
        ? 0
        : newWorkbook.activeSheetIndex.clamp(0, newWorkbook.sheets.length - 1);
    selection = const CellRef(0, 0);
    editingCell = null;
    _editVersion = 0;
    notifyListeners();
  }

  /// Commits any in-progress edit using the latest text seen via
  /// [updateEditText]. Called before selection changes so clicking another
  /// cell mid-edit commits instead of silently discarding the typing.
  void _commitPendingEdit() {
    final target = editingCell;
    if (target == null) return;
    _applyEdit(target, _editText);
    editingCell = null;
  }

  /// Writes [text] to [target], bumping [_editVersion] only when the
  /// content actually changed (avoids phantom dirty state).
  void _applyEdit(CellRef target, String text) {
    if (activeSheet.textAt(target) == text) return;
    activeSheet.setText(target, text);
    _editVersion++;
  }

  CellRef _clamp(CellRef r) => CellRef(
        r.row.clamp(0, activeSheet.rowCount - 1),
        r.col.clamp(0, activeSheet.columnCount - 1),
      );
}
