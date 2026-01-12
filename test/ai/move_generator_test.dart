import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/ai/move_generator.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('MoveGenerator', () {
    late MoveGenerator generator;

    setUp(() {
      generator = MoveGenerator();
    });

    test('returns center for empty board', () {
      final board = GameBoard(rows: 15, columns: 15);
      final moves = generator.generateMoves(board);
      
      expect(moves, contains(const Position(x: 7, y: 7)));
      expect(moves.length, equals(1));
    });

    test('returns neighbors of existing pieces', () {
      final board = GameBoard(rows: 15, columns: 15);
      // Place piece at 7,7 manually
      board.cells[7][7] = const Cell(position: Position(x: 7, y: 7), owner: Player.x);
      
      final moves = generator.generateMoves(board);
      
      // Radius 1 neighbors
      expect(moves, contains(const Position(x: 6, y: 6)));
      expect(moves, contains(const Position(x: 6, y: 7)));
      expect(moves, contains(const Position(x: 8, y: 8)));
      
      expect(moves, isNot(contains(const Position(x: 7, y: 7)))); // Occupied
      expect(moves, isNot(contains(const Position(x: 0, y: 0)))); // Too far
    });
  });
}
