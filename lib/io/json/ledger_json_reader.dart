import 'dart:convert';

import '../../model/workbook.dart';
import '../../util/cell_ref.dart';

/// Thrown when a `.ledger` file is missing, corrupt, or uses an
/// unsupported format. Caught by the UI layer and shown as an error dialog
/// instead of crashing the app.
class LedgerFormatException implements Exception {
  final String message;

  LedgerFormatException(this.message);

  @override
  String toString() => 'LedgerFormatException: $message';
}

class LedgerJsonReader {
  static const int supportedVersion = 1;

  /// Excel-scale sanity caps. Anything outside these ranges is treated as
  /// a corrupt/malicious file rather than a real sheet.
  static const int maxRowCount = 1048576;
  static const int maxColumnCount = 16384;

  static Workbook read(String jsonStr) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(jsonStr);
    } on FormatException catch (e) {
      throw LedgerFormatException('File is not valid JSON: ${e.message}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw LedgerFormatException('Ledger file must contain a JSON object.');
    }

    final version = decoded['formatVersion'];
    if (version != supportedVersion) {
      throw LedgerFormatException(
        'Unsupported ledger format version: $version '
        '(this app reads version $supportedVersion).',
      );
    }

    final sheetsJson = decoded['sheets'];
    if (sheetsJson is! List) {
      throw LedgerFormatException('Ledger file is missing its sheet list.');
    }
    final sheets = <Sheet>[];
    for (final s in sheetsJson) {
      if (s is Map<String, dynamic>) sheets.add(_sheetFrom(s));
    }

    final workbook = Workbook(
      sheets: sheets.isEmpty ? [Sheet(name: 'Sheet1')] : sheets,
      activeSheetIndex: decoded['activeSheetIndex'] is int
          ? decoded['activeSheetIndex'] as int
          : 0,
    );
    workbook.activeSheetIndex =
        workbook.activeSheetIndex.clamp(0, workbook.sheets.length - 1);
    return workbook;
  }

  static Sheet _sheetFrom(Map<String, dynamic> sheetJson) {
    final name = sheetJson['name'];
    final rowCount = sheetJson['rowCount'];
    final columnCount = sheetJson['columnCount'];

    if (name is! String || name.isEmpty) {
      throw LedgerFormatException('A sheet is missing a valid name.');
    }
    if (rowCount is! int || rowCount < 1 || rowCount > maxRowCount) {
      throw LedgerFormatException(
          'Sheet "$name" has an invalid rowCount: $rowCount.');
    }
    if (columnCount is! int ||
        columnCount < 1 ||
        columnCount > maxColumnCount) {
      throw LedgerFormatException(
          'Sheet "$name" has an invalid columnCount: $columnCount.');
    }

    final sheet =
        Sheet(name: name, rowCount: rowCount, columnCount: columnCount);
    final cellsJson = sheetJson['cells'];
    if (cellsJson is List) {
      for (final cellJson in cellsJson) {
        // Skip malformed cell entries instead of failing the whole file.
        if (cellJson is! Map<String, dynamic>) continue;
        final row = cellJson['row'];
        final col = cellJson['col'];
        final value = cellJson['value'];
        if (row is! int || col is! int || value is! String) continue;
        if (row < 0 || row >= rowCount || col < 0 || col >= columnCount) {
          continue;
        }
        sheet.setText(CellRef(row, col), value);
      }
    }
    return sheet;
  }
}
