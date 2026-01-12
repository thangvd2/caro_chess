import '../models/game_models.dart';

class GameEngine {
  final GameBoard _board;
  Player _currentPlayer;
  bool _isGameOver;

  GameEngine({int rows = 15, int columns = 15})
      : _board = GameBoard(rows: rows, columns: columns),
        _currentPlayer = Player.x,
        _isGameOver = false;

  GameBoard get board => _board;
  Player get currentPlayer => _currentPlayer;
  bool get isGameOver => _isGameOver;

  bool placePiece(Position position) {
    if (_isGameOver) return false;
    if (!_isValidPosition(position)) return false;
    if (!_board.cells[position.y][position.x].isEmpty) return false;

    // Place the piece
    _board.cells[position.y][position.x] = Cell(position: position, owner: _currentPlayer);
    
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
}
