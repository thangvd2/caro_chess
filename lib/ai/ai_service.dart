import 'package:flutter/foundation.dart';
import '../models/game_models.dart';
import '../config/app_config.dart';
import 'evaluation_service.dart';
import 'minimax_solver.dart';
import 'move_generator.dart';

// Re-export AIDifficulty for backward compatibility
export '../config/app_config.dart' show AIDifficulty;

class AIService {
  Future<Position> getBestMove(GameBoard board, Player player, {AIDifficulty difficulty = AppConfig.defaultAIDifficulty}) async {
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

  final depth = AppConfig.aiDepths[difficulty] ?? 2;

  final solver = MinimaxSolver(
    evaluator: EvaluationService(),
    moveGenerator: MoveGenerator(),
  );

  return solver.getBestMove(board, player, depth: depth);
}
