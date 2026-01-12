import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/engine/game_engine.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('GameEngine', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Initializes with empty board and Player X turn', () {
      expect(engine.board.rows, equals(15));
      expect(engine.board.columns, equals(15));
      expect(engine.currentPlayer, equals(Player.x));
      expect(engine.isGameOver, isFalse);
    });

    test('placePiece places a piece and switches turn', () {
      const pos = Position(x: 7, y: 7);
      final result = engine.placePiece(pos);

      expect(result, isTrue);
      expect(engine.board.cells[7][7].owner, equals(Player.x));
      expect(engine.currentPlayer, equals(Player.o));
    });

    test('placePiece fails if cell is occupied', () {
      const pos = Position(x: 7, y: 7);
      engine.placePiece(pos);
      final result = engine.placePiece(pos); // Try to place again

      expect(result, isFalse);
      expect(engine.board.cells[7][7].owner, equals(Player.x)); // Still X
      expect(engine.currentPlayer, equals(Player.o)); // Turn shouldn't change on invalid move? 
      // Wait, if result is false, turn shouldn't have changed? 
      // Actually, if the first move succeeded, turn is O. Second move fails. Turn stays O.
      expect(engine.currentPlayer, equals(Player.o)); 
    });
    
    test('placePiece fails if position is out of bounds', () {
       const pos = Position(x: -1, y: 0);
       final result = engine.placePiece(pos);
       expect(result, isFalse);
       expect(engine.currentPlayer, equals(Player.x)); // Turn should not change
       
       const pos2 = Position(x: 15, y: 15);
       final result2 = engine.placePiece(pos2);
       expect(result2, isFalse);
    });
  });
}
