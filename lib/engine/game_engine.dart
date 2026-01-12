import '../models/game_models.dart';

class GameEngine {
  final GameBoard _board;
  Player _currentPlayer;
  bool _isGameOver;
  Player? _winner;
  final GameRule rule;
  final List<Position> _history = [];
  final List<Position> _redoStack = [];

  GameEngine({int rows = 15, int columns = 15, this.rule = GameRule.standard})
      : _board = GameBoard(rows: rows, columns: columns),
        _currentPlayer = Player.x,
        _isGameOver = false,
        _winner = null;

  GameBoard get board => _board;
  Player get currentPlayer => _currentPlayer;
  bool get isGameOver => _isGameOver;
  Player? get winner => _winner;
  bool get canUndo => _history.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

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
    
    if (_checkWin(position)) {
      _isGameOver = true;
      _winner = _currentPlayer;
    } else {
      _currentPlayer = _currentPlayer == Player.x ? Player.o : Player.x;
    }
  }

  bool undo() {
    if (!canUndo) return false;
    
    final lastMove = _history.removeLast();
    _redoStack.add(lastMove);
    
    // Revert board cell
    _board.cells[lastMove.y][lastMove.x] = Cell(position: lastMove);
    
    // If game was over, we are reverting the winning move.
    // So turn was NOT switched. We assume the player who made the move is the current player (winner).
    // If game was NOT over, turn WAS switched. So we need to switch back.
    
    if (_isGameOver) {
       // Turn is effectively the winner's turn (since it didn't switch).
       // So we don't need to toggle turn? 
       // Wait. 
       // Start: X turn.
       // X places. Win. _currentPlayer stays X.
       // Undo: Remove X. Game Not Over. _currentPlayer should be X (ready to play again).
       // So if `_isGameOver` was true, we DO NOT toggle turn.
       // But we MUST reset _isGameOver.
       _isGameOver = false;
       _winner = null;
    } else {
       // Start: X turn.
       // X places. No win. Turn becomes O.
       // Undo: Remove X. Turn should become X.
       // So we toggle back.
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
      for (int i = 1; i < 6; i++) {
        final x = lastMove.x + dir[0] * i;
        final y = lastMove.y + dir[1] * i;
        if (!_isValidPosition(Position(x: x, y: y)) || _board.cells[y][x].owner != player) break;
        forwardCount++;
      }
      
      int backwardCount = 0;
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