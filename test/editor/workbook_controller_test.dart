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

  test('moveSelection clamps at top-left edge', () {
    controller.selectCell(const CellRef(0, 0));
    controller.moveSelection(-1, -1);
    expect(controller.selection, const CellRef(0, 0));
  });

  test('moveSelection clamps at bottom-right edge', () {
    controller.selectCell(const CellRef(4, 4));
    controller.moveSelection(1, 1);
    expect(controller.selection, const CellRef(4, 4));
  });

  test('commitEdit writes value and moves selection', () {
    controller.selectCell(const CellRef(1, 1));
    controller.beginEdit();
    expect(controller.isEditing, isTrue);
    controller.commitEdit('42', moveTo: const CellRef(2, 1));
    expect(controller.activeSheet.textAt(const CellRef(1, 1)), '42');
    expect(controller.isEditing, isFalse);
    expect(controller.selection, const CellRef(2, 1));
    expect(controller.editVersion, 1);
  });

  test('cancelEdit discards without mutating the cell', () {
    controller.activeSheet.setText(const CellRef(0, 0), 'orig');
    controller.selectCell(const CellRef(0, 0));
    controller.beginEdit(seedChar: 'x');
    controller.cancelEdit();
    expect(controller.isEditing, isFalse);
    expect(controller.activeSheet.textAt(const CellRef(0, 0)), 'orig');
    expect(controller.editVersion, 0);
  });
}
