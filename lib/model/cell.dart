/// A single spreadsheet cell's content. Kept as raw text for now — no
/// formulas, no type coercion, no formatting.
class Cell {
  String value;

  Cell({this.value = ''});

  bool get isEmpty => value.isEmpty;
}
