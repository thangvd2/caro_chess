import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/engine/game_engine.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('Win Detection - Standard Gomoku', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Horizontal win (5 in a row)', () {
      // X(0,0), O(0,1), X(1,0), O(1,1), X(2,0), O(2,1), X(3,0), O(3,1), X(4,0)
      for (int i = 0; i < 5; i++) {
        engine.placePiece(Position(x: i, y: 0)); // X places at (i, 0)
        if (i < 4) engine.placePiece(Position(x: i, y: 1)); // O places at (i, 1)
      }
      
      expect(engine.isGameOver, isTrue, reason: 'X should win with 5 horizontal');
      expect(engine.winner, equals(Player.x));
    });

    test('Vertical win (5 in a row)', () {
       for (int i = 0; i < 5; i++) {
         engine.placePiece(Position(x: 0, y: i)); // X
         if (i < 4) engine.placePiece(Position(x: 1, y: i)); // O
       }
       expect(engine.isGameOver, isTrue, reason: 'X should win with 5 vertical');
       expect(engine.winner, equals(Player.x));
    });

    test('Diagonal win (Top-Left to Bottom-Right)', () {
        for (int i = 0; i < 5; i++) {
          engine.placePiece(Position(x: i, y: i)); // X
          if (i < 4) engine.placePiece(Position(x: i + 1, y: i)); // O
        }
        expect(engine.isGameOver, isTrue, reason: 'X should win with 5 diagonal \\');
        expect(engine.winner, equals(Player.x));
    });

    test('Diagonal win (Bottom-Left to Top-Right)', () {
        // (0, 4), (1, 3), (2, 2), (3, 1), (4, 0)
        for (int i = 0; i < 5; i++) {
          engine.placePiece(Position(x: i, y: 4 - i)); // X
          if (i < 4) engine.placePiece(Position(x: i, y: 5)); // O
        }
        expect(engine.isGameOver, isTrue, reason: 'X should win with 5 diagonal /');
        expect(engine.winner, equals(Player.x));
    });
    
    test('4 in a row is NOT a win', () {
       for (int i = 0; i < 4; i++) {
         engine.placePiece(Position(x: i, y: 0)); // X
         if (i < 3) engine.placePiece(Position(x: i, y: 1)); // O
       }
       expect(engine.isGameOver, isFalse);
       expect(engine.winner, isNull);
    });
  });
}
