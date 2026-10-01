import '../util/cell_ref.dart';
import 'cell.dart';

/// One sheet's data. Cells are stored sparsely - only cells that have ever
/// held a value are present in [cells] - since [rowCount]/[columnCount]
/// describe a large virtual extent (Excel-like scale), not a dense matrix
/// to allocate up front.
class Sheet {
  String name;
  final Map<CellRef, Cell> cells;
  int rowCount;
  int columnCount;

  Sheet({
    required this.name,
    Map<CellRef, Cell>? cells,
    this.rowCount = 5000,
    this.columnCount = 200,
  }) : cells = cells ?? {};

  Cell? cellAt(CellRef ref) => cells[ref];

  String textAt(CellRef ref) => cells[ref]?.value ?? '';

  void setText(CellRef ref, String text) {
    if (text.isEmpty) {
      cells.remove(ref);
    } else {
      cells[ref] = Cell(value: text);
    }
  }
}

/// The single source of truth for an open spreadsheet file.
class Workbook {
  List<Sheet> sheets;

  Workbook({required this.sheets});

  factory Workbook.blank() => Workbook(sheets: [Sheet(name: 'Sheet1')]);
}
