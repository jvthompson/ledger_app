import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import 'app_state/workbook_session.dart';
import 'io/file_service.dart';
import 'model/workbook.dart';
import 'ui/menu/app_menu_bar.dart';
import 'ui/toolbar/formatting_toolbar.dart';
import 'ui/grid/sheet_grid_view.dart';
import 'ui/widgets/status_bar.dart';

class LedgerApp extends StatelessWidget {
  const LedgerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ledger',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const LedgerHomePage(),
    );
  }
}

class LedgerHomePage extends StatefulWidget {
  const LedgerHomePage({super.key});

  @override
  State<LedgerHomePage> createState() => _LedgerHomePageState();
}

class _LedgerHomePageState extends State<LedgerHomePage> with WindowListener {
  late WorkbookSession _session;

  @override
  void initState() {
    super.initState();
    _session = WorkbookSession(Workbook.blank());
    _session.addListener(_onSessionChanged);
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
    _updateTitle();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _session.removeListener(_onSessionChanged);
    _session.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    _updateTitle();
    setState(() {});
  }

  Future<void> _updateTitle() async {
    final dirtyMark = _session.isDirty ? '• ' : '';
    await windowManager.setTitle('$dirtyMark${_session.displayName} - Ledger');
  }

  @override
  void onWindowClose() async {
    final shouldClose = await _confirmDiscardIfDirty();
    if (shouldClose) {
      await windowManager.destroy();
    }
  }

  Future<bool> _confirmDiscardIfDirty() async {
    if (!_session.isDirty) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: Text('Discard unsaved changes to ${_session.displayName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _handleNew() async {
    if (!await _confirmDiscardIfDirty()) return;
    _session.replaceWorkbook(Workbook.blank());
  }

  Future<void> _handleOpen() async {
    if (!await _confirmDiscardIfDirty()) return;
    final path = await FileService.pickOpenPath();
    if (path == null) return;
    try {
      final workbook = await FileService.readWorkbook(path);
      _session.replaceWorkbook(workbook, filePath: path);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Could not open file', '$e');
    }
  }

  Future<void> _handleSave() async {
    final path = _session.filePath;
    if (path == null) {
      await _handleSaveAs();
      return;
    }
    try {
      await FileService.writeWorkbook(
        _session.controller.workbook,
        path,
        activeSheetIndex: _session.controller.activeSheetIndex,
      );
      _session.markSaved(path);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Could not save file', '$e');
    }
  }

  Future<void> _handleSaveAs() async {
    final path = await FileService.pickSaveAsPath(
      suggestedName: '${_saveBaseName()}.ledger',
    );
    if (path == null) return;
    try {
      await FileService.writeWorkbook(
        _session.controller.workbook,
        path,
        activeSheetIndex: _session.controller.activeSheetIndex,
      );
      _session.markSaved(path);
    } catch (e) {
      if (!mounted) return;
      await _showErrorDialog('Could not save file', '$e');
    }
  }

  /// Base file name without any existing `.ledger` extension, so Save As
  /// on `Report.ledger` suggests `Report.ledger` instead of
  /// `Report.ledger.ledger`.
  String _saveBaseName() {
    final name = _session.displayName;
    if (name == 'Untitled') return name;
    const ext = '.ledger';
    return name.toLowerCase().endsWith(ext)
        ? name.substring(0, name.length - ext.length)
        : name;
  }

  Future<void> _showErrorDialog(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExit() async {
    if (!await _confirmDiscardIfDirty()) return;
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): _handleNew,
        const SingleActivator(LogicalKeyboardKey.keyO, control: true): _handleOpen,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _handleSave,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true, shift: true): _handleSaveAs,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            children: [
              AppMenuBar(
                controller: _session.controller,
                onNew: _handleNew,
                onOpen: _handleOpen,
                onSave: _handleSave,
                onSaveAs: _handleSaveAs,
                onExit: _handleExit,
              ),
              const Divider(height: 1),
              FormattingToolbar(controller: _session.controller),
              const Divider(height: 1),
              Expanded(child: SheetGridView(controller: _session.controller)),
            ],
          ),
          bottomNavigationBar: StatusBar(controller: _session.controller),
        ),
      ),
    );
  }
}
