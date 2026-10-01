/// A 0-based (row, column) address into a [Sheet]'s cell storage.
class CellRef {
  final int row;
  final int col;

  const CellRef(this.row, this.col);

  /// "A1"-style label, e.g. (0,0) -> "A1", (0,26) -> "AA1".
  String get a1 => '${columnLetters(col)}${row + 1}';

  @override
  bool operator ==(Object other) =>
      other is CellRef && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => a1;
}

/// Converts a 0-based column index to its spreadsheet column letters.
/// 0 -> "A", 25 -> "Z", 26 -> "AA", 27 -> "AB", 701 -> "ZZ", 702 -> "AAA".
String columnLetters(int col) {
  var n = col + 1;
  final buffer = StringBuffer();
  while (n > 0) {
    final rem = (n - 1) % 26;
    buffer.write(String.fromCharCode(65 + rem));
    n = (n - 1) ~/ 26;
  }
  return buffer.toString().split('').reversed.join();
}
