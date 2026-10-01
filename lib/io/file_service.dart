import 'dart:io';

import 'package:file_selector/file_selector.dart';

import '../model/workbook.dart';
import 'json/ledger_json_reader.dart';
import 'json/ledger_json_writer.dart';

const _ledgerTypeGroup = XTypeGroup(
  label: 'Ledger Workbook',
  extensions: ['ledger'],
);

/// Open/save dispatch for Ledger's native `.ledger` (JSON) file format.
/// Mirrors Write's FileService: pick paths via file_selector, auto-append
/// the extension on save, stamp the modified timestamp.
class FileService {
  static Future<String?> pickOpenPath() async {
    final file = await openFile(acceptedTypeGroups: [_ledgerTypeGroup]);
    return file?.path;
  }

  static Future<String?> pickSaveAsPath({String? suggestedName}) async {
    final location = await getSaveLocation(
      acceptedTypeGroups: [_ledgerTypeGroup],
      suggestedName: suggestedName ?? 'Untitled.ledger',
    );
    if (location == null) return null;
    return _withExtension(location.path);
  }

  static String _withExtension(String path) {
    return path.toLowerCase().endsWith('.ledger') ? path : '$path.ledger';
  }

  static Future<Workbook> readWorkbook(String path) async {
    final jsonStr = await File(path).readAsString();
    return LedgerJsonReader.read(jsonStr);
  }

  static Future<void> writeWorkbook(Workbook workbook, String path) async {
    final jsonStr = LedgerJsonWriter.write(workbook);
    await File(path).writeAsString(jsonStr);
  }
}
