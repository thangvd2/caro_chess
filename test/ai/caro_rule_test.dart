import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/ai/evaluation_service.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  late EvaluationService evaluator;
  late GameBoard board;

  setUp(() {
    evaluator = EvaluationService();
    board = GameBoard(rows: 15, columns: 15);
  });

  group('EvaluationService Rule Tests', () {
    test('Standard Gomoku: 5 in a row blocked at ends is a WIN', () {
      // O X X X X X O
      board.cells[7][2] = Cell(position: const Position(x: 2, y: 7), owner: Player.o);
      board.cells[7][3] = Cell(position: const Position(x: 3, y: 7), owner: Player.x);
      board.cells[7][4] = Cell(position: const Position(x: 4, y: 7), owner: Player.x);
      board.cells[7][5] = Cell(position: const Position(x: 5, y: 7), owner: Player.x);
      board.cells[7][6] = Cell(position: const Position(x: 6, y: 7), owner: Player.x);
      board.cells[7][7] = Cell(position: const Position(x: 7, y: 7), owner: Player.x);
      board.cells[7][8] = Cell(position: const Position(x: 8, y: 7), owner: Player.o);

      int score = evaluator.evaluate(board, Player.x, GameRule.standard);
      expect(score, greaterThan(90000), reason: "Should be a win in Standard Gomoku");
    });

    test('Caro Rule: 5 in a row blocked at both ends is NOT a win', () {
      // O X X X X X O
      board.cells[7][2] = Cell(position: const Position(x: 2, y: 7), owner: Player.o);
      board.cells[7][3] = Cell(position: const Position(x: 3, y: 7), owner: Player.x);
      board.cells[7][4] = Cell(position: const Position(x: 4, y: 7), owner: Player.x);
      board.cells[7][5] = Cell(position: const Position(x: 5, y: 7), owner: Player.x);
      board.cells[7][6] = Cell(position: const Position(x: 6, y: 7), owner: Player.x);
      board.cells[7][7] = Cell(position: const Position(x: 7, y: 7), owner: Player.x);
      board.cells[7][8] = Cell(position: const Position(x: 8, y: 7), owner: Player.o);

      int score = evaluator.evaluate(board, Player.x, GameRule.caro);
      expect(score, lessThan(90000), reason: "Should NOT be a win in Caro if blocked at both ends");
    });

    test('Caro Rule: 5 in a row blocked at one end IS a win', () {
      // _ X X X X X O
      board.cells[7][3] = Cell(position: const Position(x: 3, y: 7), owner: Player.x);
      board.cells[7][4] = Cell(position: const Position(x: 4, y: 7), owner: Player.x);
      board.cells[7][5] = Cell(position: const Position(x: 5, y: 7), owner: Player.x);
      board.cells[7][6] = Cell(position: const Position(x: 6, y: 7), owner: Player.x);
      board.cells[7][7] = Cell(position: const Position(x: 7, y: 7), owner: Player.x);
      board.cells[7][8] = Cell(position: const Position(x: 8, y: 7), owner: Player.o);

      int score = evaluator.evaluate(board, Player.x, GameRule.caro);
      expect(score, greaterThan(90000), reason: "Should be a win if only blocked at one end");
    });

    test('Caro Rule: 5 in a row blocked by Wall and Opponent is NOT a win', () {
      // Wall (x=-1) X X X X X O
      // X at x=0 to x=4.
      // O at x=5.
      board.cells[7][0] = Cell(position: const Position(x: 0, y: 7), owner: Player.x);
      board.cells[7][1] = Cell(position: const Position(x: 1, y: 7), owner: Player.x);
      board.cells[7][2] = Cell(position: const Position(x: 2, y: 7), owner: Player.x);
      board.cells[7][3] = Cell(position: const Position(x: 3, y: 7), owner: Player.x);
      board.cells[7][4] = Cell(position: const Position(x: 4, y: 7), owner: Player.x);
      board.cells[7][5] = Cell(position: const Position(x: 5, y: 7), owner: Player.o);

      int score = evaluator.evaluate(board, Player.x, GameRule.caro);
      expect(score, lessThan(90000), reason: "Should NOT be a win if blocked by Wall and Opponent");
    });

    test('Caro Rule: 5 in a row blocked by Wall is OK if other end free', () {
      // Wall X X X X X _
      board.cells[7][0] = Cell(position: const Position(x: 0, y: 7), owner: Player.x);
      board.cells[7][1] = Cell(position: const Position(x: 1, y: 7), owner: Player.x);
      board.cells[7][2] = Cell(position: const Position(x: 2, y: 7), owner: Player.x);
      board.cells[7][3] = Cell(position: const Position(x: 3, y: 7), owner: Player.x);
      board.cells[7][4] = Cell(position: const Position(x: 4, y: 7), owner: Player.x);
      // x=5 is empty

      int score = evaluator.evaluate(board, Player.x, GameRule.caro);
      expect(score, greaterThan(90000), reason: "Should be a win if blocked by Wall but other end free");
    });
  });
}
