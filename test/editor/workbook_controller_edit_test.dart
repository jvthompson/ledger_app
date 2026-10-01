import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/editor/workbook_controller.dart';
import 'package:ledger/model/workbook.dart';
import 'package:ledger/util/cell_ref.dart';

void main() {
  late WorkbookController controller;

  setUp(() {
    controller = WorkbookController(
      Workbook(sheets: [Sheet(name: 'S', rowCount: 5, columnCount: 5)]),
    );
  });

  test('selectCell commits an in-progress edit instead of dropping it', () {
    controller.selectCell(const CellRef(0, 0));
    controller.beginEdit();
    controller.updateEditText('typed text');
    controller.selectCell(const CellRef(2, 2));

    expect(controller.activeSheet.textAt(const CellRef(0, 0)), 'typed text');
    expect(controller.isEditing, isFalse);
    expect(controller.selection, const CellRef(2, 2));
  });

  test('commitEdit with unchanged text does not bump editVersion', () {
    controller.activeSheet.setText(const CellRef(1, 1), 'keep');
    final v0 = controller.editVersion;

    controller.selectCell(const CellRef(1, 1));
    controller.beginEdit();
    controller.commitEdit('keep');

    expect(controller.editVersion, v0);
    expect(controller.activeSheet.textAt(const CellRef(1, 1)), 'keep');
  });

  test('commitEdit with changed text bumps editVersion once', () {
    final v0 = controller.editVersion;

    controller.selectCell(const CellRef(1, 1));
    controller.beginEdit();
    controller.updateEditText('new');
    controller.commitEdit('new');

    expect(controller.editVersion, v0 + 1);
    expect(controller.activeSheet.textAt(const CellRef(1, 1)), 'new');
  });

  test('clearSelectedCell on an empty cell does not bump editVersion', () {
    final v0 = controller.editVersion;

    controller.selectCell(const CellRef(3, 3));
    controller.clearSelectedCell();

    expect(controller.editVersion, v0);
  });

  test('beginEdit while editing commits the previous edit', () {
    controller.selectCell(const CellRef(0, 0));
    controller.beginEdit();
    controller.updateEditText('first');

    controller.selectCell(const CellRef(1, 1));
    controller.beginEdit();

    expect(controller.activeSheet.textAt(const CellRef(0, 0)), 'first');
    expect(controller.editingCell, const CellRef(1, 1));
  });

  test('loadWorkbook adopts the saved activeSheetIndex', () {
    final wb = Workbook(
      sheets: [Sheet(name: 'A'), Sheet(name: 'B'), Sheet(name: 'C')],
      activeSheetIndex: 2,
    );
    controller.loadWorkbook(wb);
    expect(controller.activeSheetIndex, 2);
  });

  test('loadWorkbook clamps an out-of-range activeSheetIndex', () {
    final wb = Workbook(
      sheets: [Sheet(name: 'A')],
      activeSheetIndex: 7,
    );
    controller.loadWorkbook(wb);
    expect(controller.activeSheetIndex, 0);
  });
}
