import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/engine/game_engine.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('Undo/Redo Functionality', () {
    late GameEngine engine;

    setUp(() {
      engine = GameEngine();
    });

    test('Undo reverts the last move and toggles turn', () {
      const pos = Position(x: 7, y: 7);
      engine.placePiece(pos);
      
      expect(engine.board.cells[7][7].owner, equals(Player.x));
      expect(engine.currentPlayer, equals(Player.o));
      expect(engine.canUndo, isTrue); 
      
      final result = engine.undo();
      
      expect(result, isTrue);
      expect(engine.board.cells[7][7].isEmpty, isTrue);
      expect(engine.currentPlayer, equals(Player.x));
      expect(engine.canUndo, isFalse);
    });

    test('Redo reapplies the undone move', () {
      const pos = Position(x: 7, y: 7);
      engine.placePiece(pos);
      engine.undo();
      
      expect(engine.canRedo, isTrue);
      
      final result = engine.redo();
      
      expect(result, isTrue);
      expect(engine.board.cells[7][7].owner, equals(Player.x));
      expect(engine.currentPlayer, equals(Player.o));
      expect(engine.canRedo, isFalse);
    });

    test('Place piece clears redo stack', () {
      engine.placePiece(const Position(x: 0, y: 0));
      engine.undo();
      expect(engine.canRedo, isTrue);
      
      engine.placePiece(const Position(x: 1, y: 1));
      expect(engine.canRedo, isFalse);
    });
    
    test('Undo with no history returns false', () {
      expect(engine.undo(), isFalse);
    });
    
    test('Redo with no history returns false', () {
      expect(engine.redo(), isFalse);
    });

    test('Undo resets game over state if winning move is undone', () {
       // Create a win
       for (int i = 0; i < 5; i++) {
         engine.placePiece(Position(x: i, y: 0)); // X
         if (i < 4) engine.placePiece(Position(x: i, y: 1)); // O
       }
       expect(engine.isGameOver, isTrue);
       expect(engine.winner, isNotNull);
       
       engine.undo();
       
       expect(engine.isGameOver, isFalse);
       expect(engine.winner, isNull);
       // Last X at (4,0) should be removed
       expect(engine.board.cells[0][4].isEmpty, isTrue); 
       expect(engine.currentPlayer, equals(Player.x));
    });
  });
}
