/// A single spreadsheet cell's content. Kept as raw text for now — no
/// formulas, no type coercion, no formatting.
///
/// Immutable: the only way to change a cell's content is [Sheet.setText],
/// which must go through [WorkbookController] so edit-version tracking and
/// UI notifications stay in sync.
class Cell {
  final String value;

  const Cell({this.value = ''});

  bool get isEmpty => value.isEmpty;
}
