import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/io/json/ledger_json_reader.dart';
import 'package:ledger/io/json/ledger_json_writer.dart';
import 'package:ledger/model/workbook.dart';
import 'package:ledger/util/cell_ref.dart';

void main() {
  test('reader rejects non-JSON input', () {
    expect(
      () => LedgerJsonReader.read('this is not json {{{'),
      throwsA(isA<LedgerFormatException>()),
    );
  });

  test('reader rejects a non-object document', () {
    expect(
      () => LedgerJsonReader.read('[1, 2, 3]'),
      throwsA(isA<LedgerFormatException>()),
    );
  });

  test('reader rejects unsupported format version', () {
    expect(
      () => LedgerJsonReader.read('{"formatVersion": 999, "sheets": []}'),
      throwsA(isA<LedgerFormatException>()),
    );
  });

  test('reader rejects a missing sheet list', () {
    expect(
      () => LedgerJsonReader.read('{"formatVersion": 1}'),
      throwsA(isA<LedgerFormatException>()),
    );
  });

  test('reader rejects zero rowCount', () {
    expect(
      () => LedgerJsonReader.read(
        '{"formatVersion": 1, "sheets": '
        '[{"name": "S", "rowCount": 0, "columnCount": 5, "cells": []}]}',
      ),
      throwsA(isA<LedgerFormatException>()),
    );
  });

  test('reader skips malformed cell entries instead of failing', () {
    final wb = LedgerJsonReader.read(
      '{"formatVersion": 1, "sheets": [{"name": "S", "rowCount": 10, '
      '"columnCount": 10, "cells": ['
      '{"row": 0, "col": 0, "value": "ok"}, '
      '{"row": -1, "col": 0, "value": "negative row"}, '
      '{"row": 0, "value": "missing col"}, '
      '{"row": 99, "col": 0, "value": "out of range"}, '
      '{"row": 1, "col": 1, "value": 42}'
      ']}]}',
    );
    final sheet = wb.sheets.first;
    expect(sheet.cells, hasLength(1));
    expect(sheet.textAt(const CellRef(0, 0)), 'ok');
  });

  test('activeSheetIndex round-trips through save and load', () {
    final wb = Workbook(
      sheets: [Sheet(name: 'A'), Sheet(name: 'B'), Sheet(name: 'C')],
      activeSheetIndex: 2,
    );
    final jsonStr =
        LedgerJsonWriter.write(wb, activeSheetIndex: wb.activeSheetIndex);
    final restored = LedgerJsonReader.read(jsonStr);
    expect(restored.activeSheetIndex, 2);
    expect(restored.sheets, hasLength(3));
  });

  test('out-of-range activeSheetIndex is clamped on read', () {
    const jsonStr = '{"formatVersion": 1, "activeSheetIndex": 42, '
        '"sheets": [{"name": "S", "rowCount": 5, '
        '"columnCount": 5, "cells": []}]}';
    final restored = LedgerJsonReader.read(jsonStr);
    expect(restored.activeSheetIndex, 0);
  });
}
