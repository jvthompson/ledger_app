import 'package:flutter/foundation.dart';

import '../editor/workbook_controller.dart';
import '../model/workbook.dart';

/// Wraps a [WorkbookController], tracking the open file path and whether
/// there are unsaved changes. Mirrors Write's DocumentSession: dirty state
/// is derived by comparing the controller's editVersion counter against the
/// version last seen at save time, not by counting notifications.
class WorkbookSession extends ChangeNotifier {
  WorkbookController controller;
  String? filePath;
  bool _dirty = false;
  int _lastSavedEditVersion;

  WorkbookSession(Workbook workbook)
      : controller = WorkbookController(workbook),
        _lastSavedEditVersion = 0 {
    controller.addListener(_onControllerChanged);
  }

  bool get isDirty => _dirty;

  String get displayName =>
      filePath == null ? 'Untitled' : filePath!.split(RegExp(r'[\\/]')).last;

  void _onControllerChanged() {
    final v = controller.editVersion;
    if (v == _lastSavedEditVersion) return;
    if (!_dirty) {
      _dirty = true;
      notifyListeners();
    }
  }

  void replaceWorkbook(Workbook workbook, {String? filePath}) {
    controller.loadWorkbook(workbook);
    this.filePath = filePath;
    _lastSavedEditVersion = 0;
    _dirty = false;
    notifyListeners();
  }

  void markSaved(String path) {
    filePath = path;
    _lastSavedEditVersion = controller.editVersion;
    _dirty = false;
    notifyListeners();
  }

  @override
  void dispose() {
    controller.removeListener(_onControllerChanged);
    controller.dispose();
    super.dispose();
  }
}
