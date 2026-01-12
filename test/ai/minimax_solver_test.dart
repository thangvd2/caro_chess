import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/ai/minimax_solver.dart';
import 'package:caro_chess/ai/evaluation_service.dart';
import 'package:caro_chess/ai/move_generator.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('MinimaxSolver', () {
    late MinimaxSolver solver;

    setUp(() {
      solver = MinimaxSolver(
        evaluator: EvaluationService(),
        moveGenerator: MoveGenerator(),
      );
    });

    test('finds winning move (1 step)', () {
      final board = GameBoard(rows: 15, columns: 15);
      // X X X X .
      for (int i = 0; i < 4; i++) {
        board.cells[0][i] = Cell(position: Position(x: i, y: 0), owner: Player.x);
      }
      
      final move = solver.getBestMove(board, Player.x, depth: 1);
      
      expect(move, equals(const Position(x: 4, y: 0)));
    });

    test('blocks opponent win (1 step)', () {
      final board = GameBoard(rows: 15, columns: 15);
      // O O O O .
      for (int i = 0; i < 4; i++) {
        board.cells[0][i] = Cell(position: Position(x: i, y: 0), owner: Player.o);
      }
      
      final move = solver.getBestMove(board, Player.x, depth: 1);
      expect(move, equals(const Position(x: 4, y: 0)));
    });
  });
}
