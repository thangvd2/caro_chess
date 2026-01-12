import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import 'evaluation_service.dart';
import 'minimax_solver.dart';
import 'move_generator.dart';

enum AIDifficulty { easy, medium, hard }

class AIService {
  Future<Position> getBestMove(GameBoard board, Player player, {AIDifficulty difficulty = AIDifficulty.medium}) async {
    return compute(_runMinimax, {
      'board': board,
      'player': player,
      'difficulty': difficulty,
    });
  }
}

Position _runMinimax(Map<String, dynamic> params) {
  final GameBoard board = params['board'];
  final Player player = params['player'];
  final AIDifficulty difficulty = params['difficulty'];

  int depth = 2;
  switch (difficulty) {
    case AIDifficulty.easy:
      depth = 1;
      break;
    case AIDifficulty.medium:
      depth = 2;
      break;
    case AIDifficulty.hard:
      depth = 4;
      break;
  }

  final solver = MinimaxSolver(
    evaluator: EvaluationService(),
    moveGenerator: MoveGenerator(),
  );

  return solver.getBestMove(board, player, depth: depth);
}
