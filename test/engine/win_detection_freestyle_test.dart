import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/engine/game_engine.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('Win Detection - Free-style Gomoku', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine(rule: GameRule.freeStyle);
    });

    test('5 in a row is a win', () {
      for (int i = 0; i < 5; i++) {
        engine.placePiece(Position(x: i, y: 0)); // X
        if (i < 4) engine.placePiece(Position(x: i, y: 1)); // O
      }
      expect(engine.isGameOver, isTrue);
      expect(engine.winner, equals(Player.x));
    });

    test('6 in a row (overline) is a win', () {
      // X X . X X X
      
      engine.placePiece(Position(x: 0, y: 0)); // X
      engine.placePiece(Position(x: 0, y: 1)); // O
      
      engine.placePiece(Position(x: 1, y: 0)); // X
      engine.placePiece(Position(x: 1, y: 1)); // O
      
      engine.placePiece(Position(x: 3, y: 0)); // X
      engine.placePiece(Position(x: 3, y: 1)); // O
      
      engine.placePiece(Position(x: 4, y: 0)); // X
      engine.placePiece(Position(x: 4, y: 1)); // O
      
      engine.placePiece(Position(x: 5, y: 0)); // X
      engine.placePiece(Position(x: 5, y: 1)); // O
      
      // Board Row 0: X X . X X X
      // Place X at (2,0)
      engine.placePiece(Position(x: 2, y: 0)); // X
      
      // Row 0 has 6 Xs.
      expect(engine.isGameOver, isTrue);
      expect(engine.winner, equals(Player.x));
    });

    test('Standard rule does NOT win on overline (Strict)', () {
        final standardEngine = GameEngine(rule: GameRule.standard);
        
        // X X . X X X
        standardEngine.placePiece(Position(x: 0, y: 0)); // X
        standardEngine.placePiece(Position(x: 0, y: 1)); // O
        
        standardEngine.placePiece(Position(x: 1, y: 0)); // X
        standardEngine.placePiece(Position(x: 1, y: 1)); // O
        
        standardEngine.placePiece(Position(x: 3, y: 0)); // X
        standardEngine.placePiece(Position(x: 3, y: 1)); // O
        
        standardEngine.placePiece(Position(x: 4, y: 0)); // X
        standardEngine.placePiece(Position(x: 4, y: 1)); // O
        
        standardEngine.placePiece(Position(x: 5, y: 0)); // X
        standardEngine.placePiece(Position(x: 5, y: 1)); // O
        
        standardEngine.placePiece(Position(x: 2, y: 0)); // X places the 6th stone
        
        expect(standardEngine.isGameOver, isFalse, reason: 'Standard Gomoku should not accept overline (6)');
    });
  });
}
