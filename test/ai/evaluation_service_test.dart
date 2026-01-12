import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/ai/evaluation_service.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('EvaluationService', () {
    late EvaluationService evaluator;

    setUp(() {
      evaluator = EvaluationService();
    });

    test('returns 0 for empty board', () {
      final board = GameBoard(rows: 15, columns: 15);
      final score = evaluator.evaluate(board, Player.x);
      expect(score, equals(0));
    });

    test('prefers winning position (5 in a row)', () {
      final board = GameBoard(rows: 15, columns: 15);
      // X X X X X
      for (int i = 0; i < 5; i++) {
        board.cells[0][i] = Cell(position: Position(x: i, y: 0), owner: Player.x);
      }
      final score = evaluator.evaluate(board, Player.x);
      expect(score, greaterThan(10000));
    });

    test('penalizes opponent winning position', () {
      final board = GameBoard(rows: 15, columns: 15);
      // O O O O O
      for (int i = 0; i < 5; i++) {
        board.cells[0][i] = Cell(position: Position(x: i, y: 0), owner: Player.o);
      }
      final score = evaluator.evaluate(board, Player.x);
      expect(score, lessThan(-10000));
    });

    test('prefers Open 4', () {
       // . X X X X .
       final board = GameBoard(rows: 15, columns: 15);
       for (int i = 1; i <= 4; i++) {
         board.cells[0][i] = Cell(position: Position(x: i, y: 0), owner: Player.x);
       }
       final score = evaluator.evaluate(board, Player.x);
       expect(score, greaterThan(1000)); 
    });
  });
}
