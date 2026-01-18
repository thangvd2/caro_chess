import '../models/game_models.dart';

class EvaluationService {
  static const int winScore = 100000;
  static const int live4 = 10000;
  static const int live3 = 1000;
  static const int live2 = 100;

  int evaluate(GameBoard board, Player player, [GameRule rule = GameRule.standard]) {
    int myScore = _evaluateForPlayer(board, player, rule);
    int opponentScore = _evaluateForPlayer(board, player == Player.x ? Player.o : Player.x, rule);
    return myScore - opponentScore;
  }

  int _evaluateForPlayer(GameBoard board, Player player, GameRule rule) {
    int score = 0;
    
    // Horizontal
    for (int y = 0; y < board.rows; y++) {
      for (int x = 0; x <= board.columns - 5; x++) {
        score += _evaluateWindow(board, x, y, 1, 0, player, rule);
      }
    }
    
    // Vertical
    for (int x = 0; x < board.columns; x++) {
      for (int y = 0; y <= board.rows - 5; y++) {
        score += _evaluateWindow(board, x, y, 0, 1, player, rule);
      }
    }
    
    // Diagonal \
    for (int y = 0; y <= board.rows - 5; y++) {
      for (int x = 0; x <= board.columns - 5; x++) {
        score += _evaluateWindow(board, x, y, 1, 1, player, rule);
      }
    }
    
    // Diagonal /
    for (int y = 4; y < board.rows; y++) {
      for (int x = 0; x <= board.columns - 5; x++) {
        score += _evaluateWindow(board, x, y, 1, -1, player, rule);
      }
    }
    
    return score;
  }

  int _evaluateWindow(GameBoard board, int startX, int startY, int dx, int dy, Player player, GameRule rule) {
    int myPieces = 0;
    int opponentPieces = 0;
    
    for (int i = 0; i < 5; i++) {
      final x = startX + dx * i;
      final y = startY + dy * i;
      final cell = board.cells[y][x];
      
      if (cell.owner == player) {
        myPieces++;
      } else if (!cell.isEmpty) {
        opponentPieces++;
      }
    }
    
    if (opponentPieces > 0) return 0;
    
    if (myPieces == 5) {
      if (rule == GameRule.caro) {
        bool blockedBefore = false;
        final bX = startX - dx;
        final bY = startY - dy;
        if (!_isValid(board, bX, bY) || (board.cells[bY][bX].owner != null && board.cells[bY][bX].owner != player)) {
          blockedBefore = true;
        }

        bool blockedAfter = false;
        final aX = startX + dx * 5;
        final aY = startY + dy * 5;
        if (!_isValid(board, aX, aY) || (board.cells[aY][aX].owner != null && board.cells[aY][aX].owner != player)) {
          blockedAfter = true;
        }

        if (blockedBefore && blockedAfter) return 0; // Blocked ends is not a win in Caro
      }
      return winScore;
    }
    if (myPieces == 4) return live4;
    if (myPieces == 3) return live3;
    if (myPieces == 2) return live2;
    
    return 0;
  }

  bool _isValid(GameBoard board, int x, int y) {
    return x >= 0 && x < board.columns && y >= 0 && y < board.rows;
  }
}
