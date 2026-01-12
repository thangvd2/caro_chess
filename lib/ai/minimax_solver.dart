import 'dart:math';
import '../models/game_models.dart';
import 'evaluation_service.dart';
import 'move_generator.dart';

class MinimaxSolver {
  final EvaluationService evaluator;
  final MoveGenerator moveGenerator;

  MinimaxSolver({required this.evaluator, required this.moveGenerator});

  Position getBestMove(GameBoard board, Player player, {int depth = 2}) {
    List<Position> possibleMoves = moveGenerator.generateMoves(board);
    
    if (possibleMoves.isEmpty) return const Position(x: 7, y: 7);
    if (possibleMoves.length == 1) return possibleMoves.first;
    
    int bestScore = -999999999;
    Position bestMove = possibleMoves.first;
    
    possibleMoves.shuffle();

    for (final move in possibleMoves) {
      board.cells[move.y][move.x] = Cell(position: move, owner: player);
      
      int score = _minimax(board, depth - 1, false, -999999999, 999999999, player);
      
      board.cells[move.y][move.x] = Cell(position: move); // Revert
      
      if (score > bestScore) {
        bestScore = score;
        bestMove = move;
      }
    }
    
    return bestMove;
  }

  int _minimax(GameBoard board, int depth, bool isMaximizing, int alpha, int beta, Player player) {
    if (depth == 0) {
      return evaluator.evaluate(board, player);
    }
    
    final opponent = player == Player.x ? Player.o : Player.x;
    final currentPlayer = isMaximizing ? player : opponent;

    List<Position> possibleMoves = moveGenerator.generateMoves(board);
    if (possibleMoves.isEmpty) return evaluator.evaluate(board, player);

    if (isMaximizing) {
      int maxEval = -999999999;
      for (final move in possibleMoves) {
        board.cells[move.y][move.x] = Cell(position: move, owner: currentPlayer);
        int eval = _minimax(board, depth - 1, false, alpha, beta, player);
        board.cells[move.y][move.x] = Cell(position: move);
        
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 999999999;
      for (final move in possibleMoves) {
        board.cells[move.y][move.x] = Cell(position: move, owner: currentPlayer);
        int eval = _minimax(board, depth - 1, true, alpha, beta, player);
        board.cells[move.y][move.x] = Cell(position: move);
        
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }
}
