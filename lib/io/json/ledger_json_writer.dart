import 'dart:convert';

import '../../model/workbook.dart';

class LedgerJsonWriter {
  static String write(Workbook workbook) {
    final map = {
      'formatVersion': 1,
      'properties': {'modified': DateTime.now().toIso8601String()},
      'activeSheetIndex': 0,
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
