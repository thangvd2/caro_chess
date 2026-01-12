import '../models/game_models.dart';

class EvaluationService {
  static const int winScore = 100000;
  static const int live4 = 10000;
  static const int live3 = 1000;
  static const int live2 = 100;

  int evaluate(GameBoard board, Player player) {
    int myScore = _evaluateForPlayer(board, player);
    int opponentScore = _evaluateForPlayer(board, player == Player.x ? Player.o : Player.x);
    return myScore - opponentScore;
  }

  int _evaluateForPlayer(GameBoard board, Player player) {
    int score = 0;
    
    // Horizontal
    for (int y = 0; y < board.rows; y++) {
      for (int x = 0; x <= board.columns - 5; x++) {
        score += _evaluateWindow(board, x, y, 1, 0, player);
      }
    }
    
    // Vertical
    for (int x = 0; x < board.columns; x++) {
      for (int y = 0; y <= board.rows - 5; y++) {
        score += _evaluateWindow(board, x, y, 0, 1, player);
      }
    }
    
    // Diagonal \
    for (int y = 0; y <= board.rows - 5; y++) {
      for (int x = 0; x <= board.columns - 5; x++) {
        score += _evaluateWindow(board, x, y, 1, 1, player);
      }
    }
    
    // Diagonal /
    for (int y = 4; y < board.rows; y++) {
      for (int x = 0; x <= board.columns - 5; x++) {
        score += _evaluateWindow(board, x, y, 1, -1, player);
      }
    }
    
    return score;
  }

  int _evaluateWindow(GameBoard board, int startX, int startY, int dx, int dy, Player player) {
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
    
    if (myPieces == 5) return winScore;
    if (myPieces == 4) return live4;
    if (myPieces == 3) return live3;
    if (myPieces == 2) return live2;
    
    return 0;
  }
}
