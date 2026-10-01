import 'dart:convert';

import '../../model/workbook.dart';

class LedgerJsonWriter {
  /// Serializes [workbook]. [activeSheetIndex] records which sheet was
  /// active at save time; the reader restores it on open.
  static String write(Workbook workbook, {int activeSheetIndex = 0}) {
    final map = {
      'formatVersion': 1,
      'properties': {'modified': DateTime.now().toIso8601String()},
      'activeSheetIndex': activeSheetIndex,
      'sheets': [for (final s in workbook.sheets) _sheetJson(s)],
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }

  static Map<String, dynamic> _sheetJson(Sheet sheet) => {
        'name': sheet.name,
        'rowCount': sheet.rowCount,
        'columnCount': sheet.columnCount,
        'cells': [
          for (final entry in sheet.cells.entries)
            {
              'row': entry.key.row,
              'col': entry.key.col,
              'value': entry.value.value,
            },
        ],
      };
}
