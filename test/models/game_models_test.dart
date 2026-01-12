import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('Game Models', () {
    test('Position supports equality', () {
      const pos1 = Position(x: 1, y: 1);
      const pos2 = Position(x: 1, y: 1);
      const pos3 = Position(x: 2, y: 2);

      expect(pos1, equals(pos2));
      expect(pos1, isNot(equals(pos3)));
    });

    test('Player enum has X and O', () {
      expect(Player.values, containsAll([Player.x, Player.o]));
    });

    test('Cell holds position and owner', () {
      const pos = Position(x: 5, y: 5);
      final cell = Cell(position: pos, owner: Player.x);

      expect(cell.position, equals(pos));
      expect(cell.owner, equals(Player.x));
      expect(cell.isEmpty, isFalse);

      final emptyCell = Cell(position: pos);
      expect(emptyCell.isEmpty, isTrue);
    });

    test('GameBoard initializes with correct dimensions and empty cells', () {
      final board = GameBoard(rows: 15, columns: 15);

      expect(board.rows, equals(15));
      expect(board.columns, equals(15));
      expect(board.cells.length, equals(15));
      expect(board.cells[0].length, equals(15));
      expect(board.cells[0][0].isEmpty, isTrue);
    });
  });
}
