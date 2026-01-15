import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/game_models.dart';
import '../models/user_profile.dart';
import '../models/cosmetics.dart';
import '../models/chat_message.dart';
import '../engine/game_engine.dart';
import '../repositories/game_repository.dart';
import '../ai/ai_service.dart';
import '../services/web_socket_service.dart';
import '../services/audio_service.dart';

// Events
abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

class StartGame extends GameEvent {
  final GameRule rule;
  final GameMode mode;
  final AIDifficulty difficulty;
  const StartGame({
    this.rule = GameRule.standard, 
    this.mode = GameMode.localPvP,
    this.difficulty = AIDifficulty.medium,
  });
  @override
  List<Object?> get props => [rule, mode, difficulty];
}

class StartRoomCreation extends GameEvent {}
class JoinRoomRequested extends GameEvent {
  final String code;
  const JoinRoomRequested(this.code);
  @override
  List<Object?> get props => [code];
}

class LoginAsGuest extends GameEvent {}
class LogoutRequested extends GameEvent {}

class LoadSavedGame extends GameEvent {}

class PlacePiece extends GameEvent {
  final Position position;
  const PlacePiece(this.position);
  @override
  List<Object?> get props => [position];
}

class ResetGame extends GameEvent {}

class ChangeRules extends GameEvent {
  final GameRule rule;
  const ChangeRules(this.rule);
  @override
  List<Object?> get props => [rule];
}

class UndoMove extends GameEvent {}
class RedoMove extends GameEvent {}
class AIMoveRequested extends GameEvent {}
class SocketMessageReceived extends GameEvent {
  final dynamic message;
  const SocketMessageReceived(this.message);
  @override
  List<Object?> get props => [message];
}

class PurchaseItemRequested extends GameEvent {
  final SkinItem item;
  const PurchaseItemRequested(this.item);
  @override
  List<Object?> get props => [item];
}

class EquipItemRequested extends GameEvent {
  final String itemId;
  final SkinType type;
  const EquipItemRequested(this.itemId, this.type);
  @override
  List<Object?> get props => [itemId, type];
}

class UnlockItem extends GameEvent {
  final String itemId;
  const UnlockItem(this.itemId);
  @override
  List<Object?> get props => [itemId];
}

class SendChatMessage extends GameEvent {
  final String text;
  const SendChatMessage(this.text);
  @override
  List<Object?> get props => [text];
}

// States
abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}
class GameAuthLoading extends GameState {
  @override
  List<Object?> get props => [];
}
class GameAuthRequired extends GameState {}
class GameFindingMatch extends GameState {}
class GameAIThinking extends GameState {}
class GameWaitingInRoom extends GameState {
  final String code;
  const GameWaitingInRoom(this.code);
  @override
  List<Object?> get props => [code];
}

class GameInProgress extends GameState {
  final GameBoard board;
  final Player currentPlayer;
  final GameRule rule;
  final GameMode mode;
  final AIDifficulty difficulty;
  final Player? myPlayer;
  final UserProfile? userProfile;
  final Inventory inventory;
  final List<ChatMessage> messages;
  final bool canUndo;
  final bool canRedo;

  const GameInProgress({
    required this.board,
    required this.currentPlayer,
    required this.rule,
    required this.mode,
    required this.difficulty,
    required this.inventory,
    required this.messages,
    this.myPlayer,
    this.userProfile,
    this.canUndo = false,
    this.canRedo = false,
    this.isSpectating = false,
  });

  final bool isSpectating;

  @override
  List<Object?> get props => [board, currentPlayer, rule, mode, difficulty, myPlayer, userProfile, inventory, messages, canUndo, canRedo, isSpectating];
}

class GameOver extends GameState {
  final GameBoard board;
  final Player? winner;
  final GameRule rule;
  final Inventory inventory;
  final List<Position>? winningLine;
  final UserProfile? userProfile;

  const GameOver({required this.board, this.winner, required this.rule, required this.inventory, this.winningLine, this.userProfile});

  @override
  List<Object?> get props => [board, winner, rule, inventory, winningLine, userProfile];
}

// Bloc
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository _repository;
  final AIService _aiService;
  final WebSocketService _socketService;
  final AudioService _audioService;
  StreamSubscription? _socketSubscription;

  GameEngine? _engine;
  GameMode _mode = GameMode.localPvP;
  AIDifficulty _difficulty = AIDifficulty.medium;
  Player? _myPlayer;
  UserProfile? _userProfile;
  Inventory _inventory = const Inventory();
  String? _currentRoomCode;
  final List<ChatMessage> _messages = [];

  GameBloc({GameRepository? repository, AIService? aiService, WebSocketService? socketService, AudioService? audioService}) 
      : _repository = repository ?? GameRepository(),
        _aiService = aiService ?? AIService(),
        _socketService = socketService ?? WebSocketService(),
        _audioService = audioService ?? AudioService(),
        super(GameInitial()) {
    on<StartGame>(_onStartGame);
    on<StartRoomCreation>(_onStartRoomCreation);
    on<JoinRoomRequested>(_onJoinRoomRequested);
    on<LoginAsGuest>(_onLoginAsGuest);
    on<LogoutRequested>(_onLogoutRequested);
    on<LoadSavedGame>(_onLoadSavedGame);
    on<PlacePiece>(_onPlacePiece);
    on<ResetGame>(_onResetGame);
    on<UndoMove>(_onUndoMove);
    on<RedoMove>(_onRedoMove);
    on<AIMoveRequested>(_onAIMoveRequested);
    on<SocketMessageReceived>(_onSocketMessageReceived);
    on<PurchaseItemRequested>(_onPurchaseItemRequested);
    on<EquipItemRequested>(_onEquipItemRequested);
    on<UnlockItem>(_onUnlockItem);
    on<SendChatMessage>(_onSendChatMessage);
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }

  Future<void> _onStartGame(StartGame event, Emitter<GameState> emit) async {
    _mode = event.mode;
    _difficulty = event.difficulty;
    _myPlayer = null;
    _currentRoomCode = null;
    _messages.clear();
    _inventory = await _repository.loadInventory();

    if (_mode == GameMode.online) {
      emit(GameFindingMatch());
      final token = await _repository.ensureAuthenticated();
      _socketService.connect(token: token);
      _socketSubscription?.cancel();
      _socketSubscription = _socketService.stream.listen((msg) {
        add(SocketMessageReceived(msg));
      });
      _socketService.send({'type': 'FIND_MATCH'});
    } else {
      _engine = GameEngine(rule: event.rule);
      _saveState();
      emit(_buildInProgressState());
    }
  }

  Future<void> _onStartRoomCreation(StartRoomCreation event, Emitter<GameState> emit) async {
    _mode = GameMode.online;
    _messages.clear();
    emit(GameFindingMatch());
    final token = await _repository.ensureAuthenticated();
    _socketService.connect(token: token);
    _socketSubscription?.cancel();
    _socketSubscription = _socketService.stream.listen((msg) {
      add(SocketMessageReceived(msg));
    });
    _socketService.send({'type': 'CREATE_ROOM'});
  }

  Future<void> _onJoinRoomRequested(JoinRoomRequested event, Emitter<GameState> emit) async {
    _mode = GameMode.online;
    _currentRoomCode = event.code;
    _messages.clear();
    emit(GameFindingMatch());
    final token = await _repository.ensureAuthenticated();
    _socketService.connect(token: token);
    _socketSubscription?.cancel();
    _socketSubscription = _socketService.stream.listen((msg) {
      add(SocketMessageReceived(msg));
    });
    _socketService.send({'type': 'JOIN_ROOM', 'code': event.code});
  }

  void _onSocketMessageReceived(SocketMessageReceived event, Emitter<GameState> emit) {
    final dynamic msgRaw = event.message;
    final msg = jsonDecode(msgRaw is String ? msgRaw : utf8.decode(msgRaw));

    if (msg['type'] == 'ROOM_CREATED') {
      _currentRoomCode = msg['code'];
      emit(GameWaitingInRoom(msg['code']));
    } else if (msg['type'] == 'MATCH_FOUND') {
      _myPlayer = msg['color'] == 'X' ? Player.x : Player.o;
      _engine = GameEngine(rule: GameRule.standard);
      emit(_buildInProgressState());
    } else if (msg['type'] == 'SPECTATOR_JOINED') {
      _myPlayer = null; // Spectator
      _engine = GameEngine(rule: GameRule.standard);
      
      // Replay history
      final List<dynamic> history = msg['history'] ?? [];
      for (final move in history) {
          // Check if move is map ({"x":..., "y":...}) or just array/other format
          // Server sends []Position, so likely list of objects
          if (move is Map) {
              _engine!.placePiece(Position(x: move['X'] ?? move['x'], y: move['Y'] ?? move['y']));
          }
      }
      
      emit(_buildInProgressState(isSpectating: true));
    } else if (msg['type'] == 'MOVE_MADE') {
      final pos = Position(x: msg['x'], y: msg['y']);
      // Should we check currentPlayer? 
      // If we are spectator, myPlayer is null, so currentPlayer != myPlayer is always true (unless null == null, but currentPlayer is enum/object)
      // Actually currentPlayer is Player.x or Player.o. myPlayer is stored as Player?. 
      // If myPlayer is null, we always update.
      
      if (_engine != null) {
        _engine!.placePiece(pos);
        _audioService.playMove();
        if (_engine!.isGameOver) {
          _playWinLoseSound();
          if (_myPlayer != null) _awardCoins(); 
        }
        // Preserve isSpectating from current state if possible, or infer
        bool isSpec = false;
        if (state is GameInProgress) {
            isSpec = (state as GameInProgress).isSpectating;
        }
        emit(_buildInProgressState(isSpectating: isSpec));
      }
    } else if (msg['type'] == 'UPDATE_RANK') {
      _userProfile = UserProfile(id: _userProfile?.id ?? "Player", elo: msg['elo']);
      if (state is GameInProgress || state is GameOver) {
        bool isSpec = false;
        if (state is GameInProgress) isSpec = (state as GameInProgress).isSpectating;
        emit(_buildInProgressState(isSpectating: isSpec));
      }
    } else if (msg['type'] == 'CHAT_MESSAGE') {
      _messages.add(ChatMessage(
        senderId: msg['sender_id'],
        text: msg['text'],
        timestamp: DateTime.now(),
      ));
      bool isSpec = false;
      if (state is GameInProgress) isSpec = (state as GameInProgress).isSpectating;
      emit(_buildInProgressState(isSpectating: isSpec));
    }
    else if (msg['type'] == 'GAME_OVER') {
      final winnerStr = msg['winner'];
      Player? winner;
      if (winnerStr == 'X') winner = Player.x;
      else if (winnerStr == 'O') winner = Player.o;
      
      List<Position>? winningLine;
      if (msg['winningLine'] != null) {
        winningLine = (msg['winningLine'] as List).map((e) => Position(x: e['X'] ?? e['x'], y: e['Y'] ?? e['y'])).toList();
      }

      // Play sound based on server winner result
      if (winner != null) {
          final isWin = winner == (_myPlayer ?? Player.x);
          if (isWin) _audioService.playWin();
          else _audioService.playLose();
      } else {
          // Draw or other
      }
      
      // Ensure we explicitly emit GameOver even if local engine didn't catch it logic-wise (e.g. timeout)
      emit(GameOver(
        board: _engine!.board,
        winner: winner,
        rule: _engine!.rule,
        inventory: _inventory,
        winningLine: winningLine,
        userProfile: _userProfile,
      ));
    }
  }


  Future<void> _onLoginAsGuest(LoginAsGuest event, Emitter<GameState> emit) async {
    emit(GameAuthLoading());
    try {
      final token = await _repository.ensureAuthenticated();
      if (token == null) {
        emit(GameAuthRequired());
        return;
      }
      add(LoadSavedGame());
    } catch (e) {
      emit(GameAuthRequired());
    }
  }
  
  Future<void> _onLogoutRequested(LogoutRequested event, Emitter<GameState> emit) async {
    await _repository.logout();
    _currentRoomCode = null;
    _messages.clear();
    _engine = null;
    _myPlayer = null;
    _userProfile = null;
    emit(GameAuthRequired());
  }

  Future<void> _onLoadSavedGame(LoadSavedGame event, Emitter<GameState> emit) async {
    print("GameBloc: Loading saved game...");
    final storedUserId = await _repository.getUserId();
    if (storedUserId == null) {
        print("GameBloc: No stored user ID found. Emitting GameAuthRequired.");
        emit(GameAuthRequired());
        return;
    }

    try {
      await _repository.ensureAuthenticated();
    } catch (e) {
      print("GameBloc: EnsureAuthenticated failed: $e");
    }
    
    _inventory = await _repository.loadInventory();
    final savedData = await _repository.loadGame();
    
    final userId = await _repository.getUserId(); 
    if (userId != null) {
         _userProfile = UserProfile(id: userId, elo: 1000); 
    }

    if (savedData != null) {
      print("GameBloc: Saved game found. Resuming...");
      _mode = savedData['mode'] as GameMode;
      _difficulty = savedData['difficulty'] as AIDifficulty;
      final rule = savedData['rule'] as GameRule;
      final history = savedData['history'] as List<Position>;
      
      _engine = GameEngine(rule: rule);
      for (final pos in history) {
        _engine!.placePiece(pos);
      }
      
      emit(_buildInProgressState());
    } else {
      print("GameBloc: No saved game. Emitting GameInitial (Home Screen).");
      emit(GameInitial());
    }
  }

  void _onPlacePiece(PlacePiece event, Emitter<GameState> emit) {
    if (_engine == null) return;
    if (_mode == GameMode.online && _engine!.currentPlayer != _myPlayer) return;

    final success = _engine!.placePiece(event.position);
    if (success) {
      _audioService.playMove();
      if (_mode == GameMode.online) {
        _socketService.send({'type': 'MOVE', 'x': event.position.x, 'y': event.position.y});
      }

      _saveState();
      if (_engine!.isGameOver) {
        _playWinLoseSound();
        _awardCoins();
      }
      emit(_buildInProgressState());
      
      if (!_engine!.isGameOver && _mode == GameMode.vsAI && _engine!.currentPlayer == Player.o) {
        add(AIMoveRequested());
      }
    }
  }

  Future<void> _onAIMoveRequested(AIMoveRequested event, Emitter<GameState> emit) async {
    emit(GameAIThinking());
    final move = await _aiService.getBestMove(_engine!.board, Player.o, difficulty: _difficulty);
    add(PlacePiece(move));
  }

  void _onPurchaseItemRequested(PurchaseItemRequested event, Emitter<GameState> emit) {
    if (_inventory.coins >= event.item.price && !_inventory.ownedItemIds.contains(event.item.id)) {
      _inventory = _inventory.removeCoins(event.item.price).addItem(event.item.id);
      _repository.saveInventory(_inventory);
      emit(_buildInProgressState());
    }
  }

  void _onEquipItemRequested(EquipItemRequested event, Emitter<GameState> emit) {
    if (_inventory.ownedItemIds.contains(event.itemId)) {
      _inventory = _inventory.equipItem(event.itemId, event.type);
      _repository.saveInventory(_inventory);
      emit(_buildInProgressState());
    }
  }

  void _onUnlockItem(UnlockItem event, Emitter<GameState> emit) {
    if (!_inventory.ownedItemIds.contains(event.itemId)) {
      _inventory = _inventory.addItem(event.itemId);
      _repository.saveInventory(_inventory);
      emit(_buildInProgressState());
    }
  }

  void _onSendChatMessage(SendChatMessage event, Emitter<GameState> emit) {
    final senderId = _userProfile?.id ?? "Player";
    _socketService.send({
      'type': 'CHAT_MESSAGE',
      'text': event.text,
      'sender_id': senderId,
      'room_id': _currentRoomCode,
    });
  }

  void _onResetGame(ResetGame event, Emitter<GameState> emit) {
    _engine = null;
    _repository.clearGame();
    _socketService.disconnect();
    _messages.clear();
    _currentRoomCode = null;
    emit(GameInitial());
  }
  
  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    if (_engine == null || _mode == GameMode.online) return;
    
    if (_engine!.undo()) {
       if (_mode == GameMode.vsAI && _engine!.currentPlayer == Player.o && _engine!.canUndo) {
         _engine!.undo();
       }
       _saveState();
       emit(_buildInProgressState());
    }
  }
  
  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    if (_engine == null || _mode == GameMode.online) return;
    
    if (_engine!.redo()) {
       if (_mode == GameMode.vsAI && _engine!.currentPlayer == Player.o && _engine!.canRedo) {
           _engine!.redo();
       }
       _saveState();
       emit(_buildInProgressState());
    }
  }

  void _saveState() {
    if (_engine != null && _mode != GameMode.online) {
      _repository.saveGame(_engine!.rule, _engine!.history, mode: _mode, difficulty: _difficulty);
    }
  }
  
  void _playWinLoseSound() {
    if (_engine!.winner == null) return;
    if (_mode == GameMode.localPvP) {
      _audioService.playWin();
    } else {
      final isWin = _engine!.winner == (_myPlayer ?? Player.x);
      if (isWin) {
        _audioService.playWin();
      } else {
        _audioService.playLose();
      }
    }
  }
  
  void _awardCoins() {
    int reward = (_engine!.winner == null) ? 10 : ((_engine!.winner == (_myPlayer ?? Player.x)) ? 50 : 10);
    _inventory = _inventory.addCoins(reward);
    _repository.saveInventory(_inventory);
  }

  GameState _buildInProgressState({bool isSpectating = false}) {
    if (_engine == null) return GameInitial();
    if (_engine!.isGameOver) {
       return GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
          inventory: _inventory,
          winningLine: _engine!.winningLine,
          userProfile: _userProfile,
        );
    }
    return GameInProgress(
      board: _engine!.board,
      currentPlayer: _engine!.currentPlayer,
      rule: _engine!.rule,
      mode: _mode,
      difficulty: _difficulty,
      inventory: _inventory,
      messages: List.from(_messages),
      myPlayer: _myPlayer,
      userProfile: _userProfile,
      canUndo: _mode != GameMode.online && _engine!.canUndo,
      canRedo: _mode != GameMode.online && _engine!.canRedo,
      isSpectating: isSpectating,
    );
  }
}