import 'dart:convert';

import '../../model/cell.dart';
import '../../model/workbook.dart';
import '../../util/cell_ref.dart';

class LedgerJsonReader {
  static Workbook read(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final sheetsJson = map['sheets'] as List;
    final sheets = [
      for (final sheetJson in sheetsJson)
        _sheetFrom(sheetJson as Map<String, dynamic>),
    ];
    return Workbook(sheets: sheets.isEmpty ? [Sheet(name: 'Sheet1')] : sheets);
  }

  static Sheet _sheetFrom(Map<String, dynamic> sheetJson) {
    final sheet = Sheet(
      name: sheetJson['name'] as String,
      rowCount: sheetJson['rowCount'] as int,
      columnCount: sheetJson['columnCount'] as int,
    );
    final cellsJson = sheetJson['cells'] as List;
    for (final cellJson in cellsJson) {
      final c = cellJson as Map<String, dynamic>;
      sheet.cells[CellRef(c['row'] as int, c['col'] as int)] =
          Cell(value: c['value'] as String);
    }
    return sheet;
  }
}
