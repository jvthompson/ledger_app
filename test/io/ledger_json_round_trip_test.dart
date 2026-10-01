import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/io/json/ledger_json_reader.dart';
import 'package:ledger/io/json/ledger_json_writer.dart';
import 'package:ledger/model/workbook.dart';
import 'package:ledger/util/cell_ref.dart';

void main() {
  test('workbook round-trips through JSON, sparse cells only', () {
    final wb = Workbook.blank();
    final sheet = wb.sheets.first;
    sheet.setText(const CellRef(0, 0), 'Hello');
    sheet.setText(const CellRef(2000, 150), '42');

    final jsonStr = LedgerJsonWriter.write(wb);
    final restored = LedgerJsonReader.read(jsonStr);

    final restoredSheet = restored.sheets.first;
    expect(restoredSheet.textAt(const CellRef(0, 0)), 'Hello');
    expect(restoredSheet.textAt(const CellRef(2000, 150)), '42');
    expect(restoredSheet.cells, hasLength(2));
    expect(restoredSheet.textAt(const CellRef(1, 1)), '');
  });
}
