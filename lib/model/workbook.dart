import '../util/cell_ref.dart';
import 'cell.dart';

/// One sheet's data. Cells are stored sparsely - only cells that have ever
/// held a value are present - since [rowCount]/[columnCount]
/// describe a large virtual extent (Excel-like scale), not a dense matrix
/// to allocate up front.
///
/// [setText] is the only mutator. [cells] exposes a read-only view so
/// outside code (e.g. serialization, tests) can inspect entries without
/// bypassing the controller's change tracking.
class Sheet {
  String name;
  final Map<CellRef, Cell> _cells;
  int rowCount;
  int columnCount;

  Sheet({
    required this.name,
    Map<CellRef, Cell>? cells,
    this.rowCount = 5000,
    this.columnCount = 200,
  }) : _cells = cells ?? {};

  /// Read-only view of the stored cells. Mutating the returned map throws.
  Map<CellRef, Cell> get cells => Map.unmodifiable(_cells);

  Cell? cellAt(CellRef ref) => _cells[ref];

  String textAt(CellRef ref) => _cells[ref]?.value ?? '';

  void setText(CellRef ref, String text) {
    if (text.isEmpty) {
      _cells.remove(ref);
    } else {
      _cells[ref] = Cell(value: text);
    }
  }
}

/// The single source of truth for an open spreadsheet file.
class Workbook {
  List<Sheet> sheets;

  /// Index of the sheet that was active when the workbook was last saved.
  /// Restored by the reader (validated and clamped); adopted by
  /// [WorkbookController.loadWorkbook].
  int activeSheetIndex;

  Workbook({required this.sheets, this.activeSheetIndex = 0});

  factory Workbook.blank() => Workbook(sheets: [Sheet(name: 'Sheet1')]);
}
