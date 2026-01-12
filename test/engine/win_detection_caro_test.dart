import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/engine/game_engine.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('Win Detection - Vietnamese Caro (Blocked Ends)', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine(rule: GameRule.caro);
    });

    test('5 in a row unblocked is a win', () {
      // . X X X X X .
      for (int i = 1; i <= 5; i++) {
        engine.placePiece(Position(x: i, y: 0)); // X
        if (i < 5) engine.placePiece(Position(x: i, y: 1)); // O dummy
      }
      expect(engine.isGameOver, isTrue);
      expect(engine.winner, equals(Player.x));
    });

    test('5 in a row blocked at ONE end is a win', () {
      // O X X X X X .
      
      // Turn 1: X (dummy)
      engine.placePiece(Position(x: 0, y: 10)); 
      // Turn 2: O at (0, 0) (BLOCKER)
      engine.placePiece(Position(x: 0, y: 0));
      
      // Now X places 5 in a row at (1,0) to (5,0)
      engine.placePiece(Position(x: 1, y: 0)); // X
      engine.placePiece(Position(x: 0, y: 11)); // O
      
      engine.placePiece(Position(x: 2, y: 0)); // X
      engine.placePiece(Position(x: 0, y: 12)); // O
      
      engine.placePiece(Position(x: 3, y: 0)); // X
      engine.placePiece(Position(x: 0, y: 13)); // O
      
      engine.placePiece(Position(x: 4, y: 0)); // X
      engine.placePiece(Position(x: 0, y: 14)); // O
      
      engine.placePiece(Position(x: 5, y: 0)); // X
      
      // Check: O X X X X X .
      expect(engine.isGameOver, isTrue);
      expect(engine.winner, equals(Player.x));
    });

    test('5 in a row blocked at BOTH ends is NOT a win', () {
      // O X X X X X O
      
      // Turn 1: X (dummy)
      engine.placePiece(Position(x: 0, y: 10));
      // Turn 2: O at (0,0) -> Left Blocker
      engine.placePiece(Position(x: 0, y: 0));
      
      // Turn 3: X (dummy)
      engine.placePiece(Position(x: 1, y: 10));
      // Turn 4: O at (6,0) -> Right Blocker
      engine.placePiece(Position(x: 6, y: 0));
      
      // Now X forms 5 in between: (1,0) to (5,0)
      
      engine.placePiece(Position(x: 1, y: 0)); // X
      engine.placePiece(Position(x: 2, y: 10)); // O dummy
      
      engine.placePiece(Position(x: 2, y: 0)); // X
      engine.placePiece(Position(x: 3, y: 10)); // O
      
      engine.placePiece(Position(x: 3, y: 0)); // X
      engine.placePiece(Position(x: 4, y: 10)); // O
      
      engine.placePiece(Position(x: 4, y: 0)); // X
      engine.placePiece(Position(x: 5, y: 10)); // O
      
      // Place 5th X
      engine.placePiece(Position(x: 5, y: 0)); // X
      
      // Check: O X X X X X O
      expect(engine.isGameOver, isFalse, reason: 'Blocked at both ends should not win in Caro');
      
      // Verify that if we unblock one end (impossible here as O is there), but if X plays again... 
      // Wait, if X places a 6th stone, does it win? Not in Caro usually (strict 5).
    });
  });
}
