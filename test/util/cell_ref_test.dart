import 'package:flutter_test/flutter_test.dart';
import 'package:ledger/util/cell_ref.dart';

void main() {
  group('columnLetters', () {
    test('single letters', () {
      expect(columnLetters(0), 'A');
      expect(columnLetters(25), 'Z');
    });

    test('double letters', () {
      expect(columnLetters(26), 'AA');
      expect(columnLetters(27), 'AB');
      expect(columnLetters(701), 'ZZ');
    });

    test('triple letters', () {
      expect(columnLetters(702), 'AAA');
    });
  });

  group('CellRef', () {
    test('a1 label', () {
      expect(const CellRef(0, 0).a1, 'A1');
      expect(const CellRef(0, 26).a1, 'AA1');
      expect(const CellRef(999, 0).a1, 'A1000');
    });

    test('equality and hashCode', () {
      expect(const CellRef(2, 3), const CellRef(2, 3));
      expect(const CellRef(2, 3).hashCode, const CellRef(2, 3).hashCode);
      expect(const CellRef(2, 3) == const CellRef(3, 2), isFalse);
    });
  });
}
