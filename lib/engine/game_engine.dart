import '../models/game_models.dart';

class GameEngine {
  final GameBoard _board;
  Player _currentPlayer;
  bool _isGameOver;
  Player? _winner;
  final GameRule rule;

  GameEngine({int rows = 15, int columns = 15, this.rule = GameRule.standard})
      : _board = GameBoard(rows: rows, columns: columns),
        _currentPlayer = Player.x,
        _isGameOver = false,
        _winner = null;

  GameBoard get board => _board;
  Player get currentPlayer => _currentPlayer;
  bool get isGameOver => _isGameOver;
  Player? get winner => _winner;

  bool placePiece(Position position) {
    if (_isGameOver) return false;
    if (!_isValidPosition(position)) return false;
    if (!_board.cells[position.y][position.x].isEmpty) return false;

    // Place the piece
    _board.cells[position.y][position.x] = Cell(position: position, owner: _currentPlayer);
    
    // Check for win
    if (_checkWin(position)) {
      _isGameOver = true;
      _winner = _currentPlayer;
      return true; 
    }

    // Switch turn
    _currentPlayer = _currentPlayer == Player.x ? Player.o : Player.x;
    
    return true;
  }

  bool _isValidPosition(Position position) {
    return position.x >= 0 &&
        position.x < _board.columns &&
        position.y >= 0 &&
        position.y < _board.rows;
  }

  bool _checkWin(Position lastMove) {
    final player = _board.cells[lastMove.y][lastMove.x].owner!;
    final directions = [
      [1, 0], // Horizontal
      [0, 1], // Vertical
      [1, 1], // Diagonal \
      [1, -1] // Diagonal /
    ];

    for (final dir in directions) {
      int forwardCount = 0;
      // Check forward
      for (int i = 1; i < 6; i++) {
        final x = lastMove.x + dir[0] * i;
        final y = lastMove.y + dir[1] * i;
        if (!_isValidPosition(Position(x: x, y: y)) || _board.cells[y][x].owner != player) break;
        forwardCount++;
      }
      
      int backwardCount = 0;
      // Check backward
      for (int i = 1; i < 6; i++) {
        final x = lastMove.x - dir[0] * i;
        final y = lastMove.y - dir[1] * i;
        if (!_isValidPosition(Position(x: x, y: y)) || _board.cells[y][x].owner != player) break;
        backwardCount++;
      }
      
      int totalCount = 1 + forwardCount + backwardCount;

      if (rule == GameRule.standard) {
        if (totalCount == 5) return true;
      } else if (rule == GameRule.freeStyle) {
        if (totalCount >= 5) return true;
      } else if (rule == GameRule.caro) {
        if (totalCount == 5) {
           // Check blocked ends
           bool blockedForward = false;
           final fX = lastMove.x + dir[0] * (forwardCount + 1);
           final fY = lastMove.y + dir[1] * (forwardCount + 1);
           final fPos = Position(x: fX, y: fY);
           if (!_isValidPosition(fPos)) {
             blockedForward = true;
           } else if (_board.cells[fY][fX].owner != null && _board.cells[fY][fX].owner != player) {
             blockedForward = true;
           }
           
           bool blockedBackward = false;
           final bX = lastMove.x - dir[0] * (backwardCount + 1);
           final bY = lastMove.y - dir[1] * (backwardCount + 1);
           final bPos = Position(x: bX, y: bY);
           if (!_isValidPosition(bPos)) {
             blockedBackward = true;
           } else if (_board.cells[bY][bX].owner != null && _board.cells[bY][bX].owner != player) {
             blockedBackward = true;
           }
           
           if (!(blockedForward && blockedBackward)) return true;
        }
      }
    }
    return false;
  }
}
