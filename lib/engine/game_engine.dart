import '../models/game_models.dart';

class GameEngine {
  final GameBoard _board;
  Player _currentPlayer;
  bool _isGameOver;
  Player? _winner;
  final GameRule rule;
  final List<Position> _history = [];
  final List<Position> _redoStack = [];
  List<Position>? _winningLine;

  GameEngine({int rows = 15, int columns = 15, this.rule = GameRule.standard})
      : _board = GameBoard(rows: rows, columns: columns),
        _currentPlayer = Player.x,
        _isGameOver = false,
        _winner = null,
        _winningLine = null;

  GameBoard get board => _board;
  Player get currentPlayer => _currentPlayer;
  bool get isGameOver => _isGameOver;
  Player? get winner => _winner;
  List<Position>? get winningLine => _winningLine;
  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;
  List<Position> get history => List.unmodifiable(_history);

  bool placePiece(Position position) {
    if (_isGameOver) return false;
    if (!_isValidPosition(position)) return false;
    if (!_board.cells[position.y][position.x].isEmpty) return false;

    _applyMove(position);
    
    _history.add(position);
    _redoStack.clear();
    
    return true;
  }
  
  void _applyMove(Position position) {
    _board.cells[position.y][position.x] = Cell(position: position, owner: _currentPlayer);
    
    final line = _checkWin(position);
    if (line != null) {
      _isGameOver = true;
      _winner = _currentPlayer;
      _winningLine = line;
    } else {
      _currentPlayer = _currentPlayer == Player.x ? Player.o : Player.x;
    }
  }

  bool undo() {
    if (!canUndo) return false;
    
    final lastMove = _history.removeLast();
    _redoStack.add(lastMove);
    
    _board.cells[lastMove.y][lastMove.x] = Cell(position: lastMove);
    
    if (_isGameOver) {
       _isGameOver = false;
       _winner = null;
       _winningLine = null;
    } else {
       _currentPlayer = _currentPlayer == Player.x ? Player.o : Player.x;
    }
    
    return true;
  }

  bool redo() {
    if (!canRedo) return false;
    
    final nextMove = _redoStack.removeLast();
    _history.add(nextMove);
    
    _applyMove(nextMove);
    
    return true;
  }

  bool _isValidPosition(Position position) {
    return position.x >= 0 &&
        position.x < _board.columns &&
        position.y >= 0 &&
        position.y < _board.rows;
  }

  List<Position>? _checkWin(Position lastMove) {
    final player = _board.cells[lastMove.y][lastMove.x].owner!;
    final directions = [
      [1, 0], // Horizontal
      [0, 1], // Vertical
      [1, 1], // Diagonal \
      [1, -1] // Diagonal /
    ];

    for (final dir in directions) {
      final line = <Position>[lastMove];
      
      int forwardCount = 0;
      for (int i = 1; i < 6; i++) {
        final x = lastMove.x + dir[0] * i;
        final y = lastMove.y + dir[1] * i;
        if (!_isValidPosition(Position(x: x, y: y)) || _board.cells[y][x].owner != player) break;
        forwardCount++;
        line.add(Position(x: x, y: y));
      }
      
      int backwardCount = 0;
      for (int i = 1; i < 6; i++) {
        final x = lastMove.x - dir[0] * i;
        final y = lastMove.y - dir[1] * i;
        if (!_isValidPosition(Position(x: x, y: y)) || _board.cells[y][x].owner != player) break;
        backwardCount++;
        line.add(Position(x: x, y: y));
      }
      
      int totalCount = 1 + forwardCount + backwardCount;

      if (rule == GameRule.standard) {
        if (totalCount == 5) return line;
      } else if (rule == GameRule.freeStyle) {
        if (totalCount >= 5) return line;
      } else if (rule == GameRule.caro) {
        if (totalCount == 5) {
           bool blockedForward = false;
           final fX = lastMove.x + dir[0] * (forwardCount + 1);
           final fY = lastMove.y + dir[1] * (forwardCount + 1);
           if (!_isValidPosition(Position(x: fX, y: fY))) {
             blockedForward = true;
           } else if (_board.cells[fY][fX].owner != null && _board.cells[fY][fX].owner != player) {
             blockedForward = true;
           }
           
           bool blockedBackward = false;
           final bX = lastMove.x - dir[0] * (backwardCount + 1);
           final bY = lastMove.y - dir[1] * (backwardCount + 1);
           if (!_isValidPosition(Position(x: bX, y: bY))) {
             blockedBackward = true;
           } else if (_board.cells[bY][bX].owner != null && _board.cells[bY][bX].owner != player) {
             blockedBackward = true;
           }
           
           if (!(blockedForward && blockedBackward)) return line;
        }
      }
    }
    return null;
  }
}
