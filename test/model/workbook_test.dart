import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/model/workbook.dart';
import 'package:ledger/util/cell_ref.dart';

void main() {
  test('Workbook.blank has one empty sheet', () {
    final wb = Workbook.blank();
    expect(wb.sheets, hasLength(1));
    expect(wb.sheets.first.name, 'Sheet1');
    expect(wb.sheets.first.cells, isEmpty);
  });

  group('Sheet sparse storage', () {
    test('setText stores a cell and textAt reads it back', () {
      final sheet = Sheet(name: 'S');
      sheet.setText(const CellRef(3, 2), 'hello');
      expect(sheet.textAt(const CellRef(3, 2)), 'hello');
      expect(sheet.cells, hasLength(1));
    });

    test('untouched cells read as empty string', () {
      final sheet = Sheet(name: 'S');
      expect(sheet.textAt(const CellRef(10, 10)), '');
      expect(sheet.cellAt(const CellRef(10, 10)), isNull);
    });

    test('setting empty text removes the cell, keeping storage sparse', () {
      final sheet = Sheet(name: 'S');
      sheet.setText(const CellRef(0, 0), 'x');
      expect(sheet.cells, hasLength(1));
      sheet.setText(const CellRef(0, 0), '');
      expect(sheet.cells, isEmpty);
    });
  });
}
