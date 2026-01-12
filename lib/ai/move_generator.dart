import '../models/game_models.dart';

class MoveGenerator {
  List<Position> generateMoves(GameBoard board) {
    bool isEmpty = true;
    for (var row in board.cells) {
      for (var cell in row) {
        if (!cell.isEmpty) {
          isEmpty = false;
          break;
        }
      }
      if (!isEmpty) break;
    }

    if (isEmpty) {
      return [Position(x: board.columns ~/ 2, y: board.rows ~/ 2)];
    }

    final Set<Position> candidateMoves = {};
    final int rows = board.rows;
    final int cols = board.columns;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        if (!board.cells[y][x].isEmpty) {
          for (int dy = -1; dy <= 1; dy++) {
            for (int dx = -1; dx <= 1; dx++) {
              if (dx == 0 && dy == 0) continue;
              
              final nx = x + dx;
              final ny = y + dy;
              
              if (nx >= 0 && nx < cols && ny >= 0 && ny < rows) {
                if (board.cells[ny][nx].isEmpty) {
                  candidateMoves.add(Position(x: nx, y: ny));
                }
              }
            }
          }
        }
      }
    }

    return candidateMoves.toList();
  }
}
