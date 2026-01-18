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

class StartRoomCreation extends GameEvent {
  final Duration totalTime;
  final Duration increment;
  final Duration turnLimit;
  final GameRule rule;
  
  const StartRoomCreation({
      this.totalTime = const Duration(minutes: 5),
      this.increment = const Duration(seconds: 5),
      this.turnLimit = const Duration(seconds: 30),
      this.rule = GameRule.standard,
  });

  @override
  List<Object?> get props => [totalTime, increment, turnLimit, rule];
}

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

class TimerTicked extends GameEvent {}

class SyncShopState extends GameEvent {
  final int? coins;
  final String? unlockedItemId;
  final bool purchasedDefaults;

  const SyncShopState({this.coins, this.unlockedItemId, this.purchasedDefaults = false});

  @override
  List<Object?> get props => [coins, unlockedItemId, purchasedDefaults];
}

// States
abstract class GameState extends Equatable {
  final UserProfile? userProfile;
  final Inventory? inventory;
  
  const GameState({this.userProfile, this.inventory});
  
  @override
  List<Object?> get props => [userProfile, inventory];
}

class GameInitial extends GameState {
  const GameInitial({super.userProfile, super.inventory});
}

class GameAuthLoading extends GameState {
  @override
  List<Object?> get props => [];
}

class GameAuthRequired extends GameState {}

class GameFindingMatch extends GameState {
  final bool isCreatingRoom;
  const GameFindingMatch({this.isCreatingRoom = false, super.userProfile, super.inventory});
  
  @override
  List<Object?> get props => [isCreatingRoom, userProfile, inventory];
}

class GameWaitingInRoom extends GameState {
  final String code;
  const GameWaitingInRoom(this.code, {super.userProfile, super.inventory});
  
  @override
  List<Object?> get props => [code, userProfile, inventory];
}

class GameInProgress extends GameState {
  final GameBoard board;
  final Player currentPlayer;
  final GameRule rule;
  final GameMode mode;
  final AIDifficulty difficulty;
  final Player? myPlayer;
  // UserProfile? userProfile; 
  // Inventory inventory; // Removed
  final List<ChatMessage> messages;
  final bool canUndo;
  final bool canRedo;
  final bool isSpectating;
  final bool isAIThinking;
  final Duration? timeRemainingX;
  final Duration? timeRemainingO;

  const GameInProgress({
    required this.board,
    required this.currentPlayer,
    required this.rule,
    required this.mode,
    required this.difficulty,
    required Inventory inventory, // Keep as required arg for clarity
    required this.messages,
    this.myPlayer,
    UserProfile? userProfile, 
    this.canUndo = false,
    this.canRedo = false,
    this.isSpectating = false,
    this.isAIThinking = false,
    this.timeRemainingX,
    this.timeRemainingO,
    this.turnLimit,
    this.currentTurnTimeRemaining,
  }) : super(userProfile: userProfile, inventory: inventory);

  // Getter to access inventory easily if needed, but super has it
  Inventory get inventory => super.inventory!;

  final Duration? turnLimit;
  final Duration? currentTurnTimeRemaining;


  @override
  List<Object?> get props => [board, currentPlayer, rule, mode, difficulty, myPlayer, userProfile, inventory, messages, canUndo, canRedo, isSpectating, isAIThinking, timeRemainingX, timeRemainingO, turnLimit, currentTurnTimeRemaining];

}

class GameOver extends GameState {
  final GameBoard board;
  final Player? winner;
  final GameRule rule;
  final GameMode mode;
  final AIDifficulty difficulty;
  // Inventory inventory;
  final List<Position>? winningLine;
  // UserProfile? userProfile; 
  final Player? myPlayer;
  final String? winReason;

  const GameOver({
    required this.board, 
    this.winner, 
    required this.rule, 
    required this.mode,
    required this.difficulty,
    required Inventory inventory, 
    this.winningLine, 
    UserProfile? userProfile,
    this.myPlayer,
    this.winReason,
  }) : super(userProfile: userProfile, inventory: inventory);
  
  Inventory get inventory => super.inventory!;

  @override
  List<Object?> get props => [board, winner, rule, mode, difficulty, inventory, winningLine, userProfile, myPlayer, winReason];
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
  Timer? _timer;
  Duration? _timeRemainingX;
  Duration? _timeRemainingO;
  Duration? _turnLimit;
  Duration? _currentTurnTimeRemaining;



  GameBloc({GameRepository? repository, AIService? aiService, WebSocketService? socketService, AudioService? audioService}) 
      : _repository = repository ?? GameRepository(),
        _aiService = aiService ?? AIService(),
        _socketService = socketService ?? WebSocketService(),
        _audioService = audioService ?? AudioService(),
        super(GameInitial(inventory: const Inventory())) {
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
    on<TimerTicked>(_onTimerTicked);
    on<SyncShopState>(_onSyncShopState);
  }

  void _onSyncShopState(SyncShopState event, Emitter<GameState> emit) {
      if (event.coins != null) {
          _inventory = _inventory.copyWith(coins: event.coins);
      }
      if (event.unlockedItemId != null) {
          _inventory = _inventory.addItem(event.unlockedItemId!);
      }
      if (event.purchasedDefaults) {
           // Reload inventory fully if needed, but for now just single item sync
      }
      _repository.saveInventory(_inventory);
      
      if (state is GameOver) {
          final s = state as GameOver;
          emit(GameOver(
             board: s.board,
             winner: s.winner,
             rule: s.rule,
             mode: s.mode,
             difficulty: s.difficulty,
             inventory: _inventory,
             winningLine: s.winningLine,
             userProfile: _userProfile ?? s.userProfile,
             myPlayer: s.myPlayer,
             winReason: s.winReason,
          ));
      } else if (state is GameInProgress) {
          bool isSpec = (state as GameInProgress).isSpectating;
          emit(_buildInProgressState(isSpectating: isSpec));
      } else if (state is GameInitial) {
          emit(GameInitial(userProfile: _userProfile, inventory: _inventory));
      }
  }


  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    _timer?.cancel();
    return super.close();
  }


  Future<void> _onStartGame(StartGame event, Emitter<GameState> emit) async {
    _mode = event.mode;
    _difficulty = event.difficulty;
    _myPlayer = null;
    _currentRoomCode = null;
    _messages.clear();
    _inventory = await _repository.loadInventory();
    _timer?.cancel();
    _timeRemainingX = null;
    _timeRemainingO = null;


    if (_mode == GameMode.online) {
    emit(GameFindingMatch(userProfile: _userProfile, inventory: _inventory));
      final token = await _repository.ensureAuthenticated();
      _socketService.connect(token: token);
      _socketSubscription?.cancel();
      _socketSubscription = _socketService.stream.listen((msg) {
        add(SocketMessageReceived(msg));
      }, onError: (error) {
        print("GameBloc: Socket Error: $error");
        // If error is authentication related (401), or connection failed, logout to clear stale token
        add(LogoutRequested()); 
      });

      _socketService.send({
        'type': 'FIND_MATCH',
        'rule': event.rule.name, // Send selected rule
      });
    } else {
      _engine = GameEngine(rule: event.rule);
      _saveState();
      emit(_buildInProgressState());
    }
  }

  Future<void> _onStartRoomCreation(StartRoomCreation event, Emitter<GameState> emit) async {
    _mode = GameMode.online;
    _messages.clear();
    emit(GameFindingMatch(isCreatingRoom: true, userProfile: _userProfile, inventory: _inventory));
    final token = await _repository.ensureAuthenticated();
    _socketService.connect(token: token);
    _socketSubscription?.cancel();
    _socketSubscription = _socketService.stream.listen((msg) {
      add(SocketMessageReceived(msg));
    }, onError: (error) {
        print("GameBloc: Socket Error (Room Creation): $error");
        add(LogoutRequested());
    });
    _socketService.send({
        'type': 'CREATE_ROOM',
        'total_time': event.totalTime.inSeconds.toDouble(),
        'increment': event.increment.inSeconds.toDouble(),
        'turn_limit': event.turnLimit.inSeconds.toDouble(),
        'rule': event.rule.name,
    });
  }


  Future<void> _onJoinRoomRequested(JoinRoomRequested event, Emitter<GameState> emit) async {
    _mode = GameMode.online;
    _currentRoomCode = event.code;
    _messages.clear();
    emit(GameFindingMatch(userProfile: _userProfile, inventory: _inventory));
    final token = await _repository.ensureAuthenticated();
    _socketService.connect(token: token);
    _socketSubscription?.cancel();
    _socketSubscription = _socketService.stream.listen((msg) {
      add(SocketMessageReceived(msg));
    }, onError: (error) {
        print("GameBloc: Socket Error (Join Room): $error");
        add(LogoutRequested());
    });
    _socketService.send({'type': 'JOIN_ROOM', 'code': event.code});
  }

  void _onSocketMessageReceived(SocketMessageReceived event, Emitter<GameState> emit) {
    final dynamic msgRaw = event.message;
    final msg = jsonDecode(msgRaw is String ? msgRaw : utf8.decode(msgRaw));

    if (msg['type'] == 'ROOM_CREATED') {
      _currentRoomCode = msg['code'];
      emit(GameWaitingInRoom(msg['code'], userProfile: _userProfile, inventory: _inventory));
    } else if (msg['type'] == 'MATCH_FOUND') {
       _audioService.playGameStart();

      _currentRoomCode = msg['code'];
      // Continue to initialization...
      _myPlayer = msg['color'] == 'X' ? Player.x : Player.o;
      _engine = GameEngine(rule: GameRule.standard);
      
      if (msg['total_time'] != null) {
          final totalSec = (msg['total_time'] as num).toDouble();
          final duration = Duration(milliseconds: (totalSec * 1000).toInt());
          _timeRemainingX = duration;
          _timeRemainingO = duration;
          
          if (msg['turn_limit'] != null) {
             _turnLimit = Duration(milliseconds: ((msg['turn_limit'] as num).toDouble() * 1000).toInt());
             _currentTurnTimeRemaining = _turnLimit;
          } else {
             _turnLimit = const Duration(seconds: 30); // Default
             _currentTurnTimeRemaining = _turnLimit;
          }
          _startTimer();
      } else {
          // Fallback if server doesn't send time
          const duration = Duration(minutes: 5);
           _timeRemainingX = duration;
           _timeRemainingO = duration;
           _turnLimit = const Duration(seconds: 30);
           _currentTurnTimeRemaining = _turnLimit;
           _startTimer();
      }



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

       if (msg['time_x'] != null) {
           _timeRemainingX = Duration(milliseconds: ((msg['time_x'] as num).toDouble() * 1000).toInt());
       }
       if (msg['time_o'] != null) {
           _timeRemainingO = Duration(milliseconds: ((msg['time_o'] as num).toDouble() * 1000).toInt());
       }
       
       if (_turnLimit != null) {
           _currentTurnTimeRemaining = _turnLimit;
       }


      // Should we check currentPlayer? 

      // If we are spectator, myPlayer is null, so currentPlayer != myPlayer is always true (unless null == null, but currentPlayer is enum/object)
      // Actually currentPlayer is Player.x or Player.o. myPlayer is stored as Player?. 
      // If myPlayer is null, we always update.
      
      if (_engine != null) {
        _engine!.placePiece(pos);
        try {
          _audioService.playMove();
          if (_engine!.isGameOver) {
            _playWinLoseSound();
            if (_myPlayer != null) _awardCoins(); 
          }
        } catch (e) {
          // Ignore generic audio errors (common on Web if auto-play policy blocks it
          // or if interactions happen too quickly)
          print("Audio Error: $e");
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
            
      if (msg['coins'] != null) {
          int newCoins = (msg['coins'] as num).toInt();
          _inventory = _inventory.copyWith(coins: newCoins);
          _repository.saveInventory(_inventory);
      }

      if (state is GameOver) {
          final s = state as GameOver;
          emit(GameOver(
             board: s.board,
             winner: s.winner,
             rule: s.rule,
             mode: s.mode,
             difficulty: s.difficulty,
             inventory: _inventory, // Use updated inventory
             winningLine: s.winningLine,
             userProfile: _userProfile,
             myPlayer: s.myPlayer,
             winReason: s.winReason,
          ));
      } else if (state is GameInProgress) {
        bool isSpec = (state as GameInProgress).isSpectating;
        emit(_buildInProgressState(isSpectating: isSpec));
      }
    } else if (msg['type'] == 'CHAT_MESSAGE') {
      _messages.add(ChatMessage(
        senderId: msg['sender_id'],
        text: msg['text'],
        timestamp: DateTime.now(),
      ));
      if (state is GameOver) {
          final s = state as GameOver;
          emit(GameOver(
             board: s.board,
             winner: s.winner,
             rule: s.rule,
             mode: s.mode,
             difficulty: s.difficulty,
             inventory: s.inventory,
             winningLine: s.winningLine,
             userProfile: s.userProfile,
             myPlayer: s.myPlayer,
             winReason: s.winReason,
          ));
      } else {
        bool isSpec = false;
        if (state is GameInProgress) isSpec = (state as GameInProgress).isSpectating;
        emit(_buildInProgressState(isSpectating: isSpec));
      }
    }
    else if (msg['type'] == 'GAME_OVER') {
      _timer?.cancel();
      final winnerStr = msg['winner'];

      Player? winner;
      if (winnerStr == 'X') winner = Player.x;
      else if (winnerStr == 'O') winner = Player.o;
      
      List<Position>? winningLine;
      if (msg['winningLine'] != null) {
        winningLine = (msg['winningLine'] as List).map((e) => Position(x: e['X'] ?? e['x'], y: e['Y'] ?? e['y'])).toList();
      }
      
      String? reason = msg['reason'];

      // VICTORY GUARD: If we already have a win condition, ignore redundant "opponent_left" messages
      if (state is GameOver) {
          final s = state as GameOver;
          if (s.winReason != null && reason == "opponent_left") {
              // Ignore this update, we already won/lost by a primary reason (e.g. timeout or checkmate)
              return;
          }
      }

      // Play sound based on server winner result
      if (winner != null) {
          final isWin = winner == (_myPlayer ?? Player.x);
          // Only play sound if we haven't played it yet (check state)
          if (state is! GameOver) { 
              if (isWin) {
                _audioService.playWin();
              } else {
                 _audioService.playLose();
              }
          }
      }
      
      // Ensure we explicitly emit GameOver even if local engine didn't catch it logic-wise (e.g. timeout)
      if (_engine != null) {
        emit(GameOver(
          board: _engine!.board,
        winner: winner,
        rule: _engine!.rule,
        mode: _mode,
        difficulty: _difficulty,
        inventory: _inventory,
        winningLine: winningLine,
        userProfile: _userProfile,
        myPlayer: _myPlayer,
        winReason: reason,
      ));
      }
    }
  }


  Future<void> _onLoginAsGuest(LoginAsGuest event, Emitter<GameState> emit) async {
    emit(GameAuthLoading());
    try {
      final token = await _repository.ensureAuthenticated();
      final savedGame = await _repository.loadGame(); // Define savedGame here
      if (savedGame != null) {
          add(LoadSavedGame()); // Call without argument, as LoadSavedGame event doesn't take one
      } else {
          emit(GameInitial(userProfile: _userProfile, inventory: _inventory));
      }
    } catch (e) {
      print("Error in startup auth: $e");
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
      emit(GameInitial(userProfile: _userProfile, inventory: _inventory));
    }
  }

  void _onPlacePiece(PlacePiece event, Emitter<GameState> emit) {
    if (_engine == null) return;
    if (state is GameOver) return;
    if (_mode == GameMode.online && _engine!.currentPlayer != _myPlayer) return;

    final success = _engine!.placePiece(event.position);
    if (success) {
      try {
        _audioService.playMove(); // Audio might fail on some platforms/configs
      } catch (e) {
        // Ignore audio errors to prevent game crash
      }
      
      if (_mode == GameMode.online) {
        _socketService.send({'type': 'MOVE', 'x': event.position.x, 'y': event.position.y});
      }

      _saveState();
      if (_engine!.isGameOver) {
        try {
            _playWinLoseSound();
            _awardCoins();
        } catch (e) {
            // Ignore
        }
      }
      emit(_buildInProgressState());
      
      if (!_engine!.isGameOver && _mode == GameMode.vsAI && _engine!.currentPlayer == Player.o) {
        add(AIMoveRequested());
      }
    }
  }

  Future<void> _onAIMoveRequested(AIMoveRequested event, Emitter<GameState> emit) async {
    emit(_buildInProgressState(isAIThinking: true));
    // Artificial delay to make AI feel more natural
    await Future.delayed(const Duration(milliseconds: 1000));
    try {
        final move = await _aiService.getBestMove(_engine!.board, Player.o, difficulty: _difficulty, rule: _engine!.rule);
        add(PlacePiece(move));
    } catch (e) {
        print("GameBloc: AI Error: $e"); // Keep AI error log as it's critical
        // Optionally emit an error state or toast, but for now just log
    }
  }

  void _onPurchaseItemRequested(PurchaseItemRequested event, Emitter<GameState> emit) {
    if (_inventory.coins >= event.item.price && !_inventory.ownedItemIds.contains(event.item.id)) {
      _inventory = _inventory.removeCoins(event.item.price).addItem(event.item.id);
      _repository.saveInventory(_inventory);
      
      if (state is GameOver) {
          final s = state as GameOver;
          emit(GameOver(
             board: s.board,
             winner: s.winner,
             rule: s.rule,
             mode: s.mode,
             difficulty: s.difficulty,
             inventory: _inventory,
             winningLine: s.winningLine,
             userProfile: _userProfile ?? s.userProfile,
             myPlayer: s.myPlayer,
             winReason: s.winReason,
          ));
      } else {
        bool isSpec = false;
        if (state is GameInProgress) isSpec = (state as GameInProgress).isSpectating;
        emit(_buildInProgressState(isSpectating: isSpec));
      }
    }
  }

  void _onEquipItemRequested(EquipItemRequested event, Emitter<GameState> emit) {
    if (_inventory.ownedItemIds.contains(event.itemId)) {
      _inventory = _inventory.equipItem(event.itemId, event.type);
      
      // Optimistic update: Emit new state first
      if (state is GameOver) {
          final s = state as GameOver;
          emit(GameOver(
             board: s.board,
             winner: s.winner,
             rule: s.rule,
             mode: s.mode,
             difficulty: s.difficulty,
             inventory: _inventory,
             winningLine: s.winningLine,
             userProfile: _userProfile ?? s.userProfile,
             myPlayer: s.myPlayer,
             winReason: s.winReason,
          ));
      } else {
         bool isSpec = false;
         if (state is GameInProgress) isSpec = (state as GameInProgress).isSpectating;
         emit(_buildInProgressState(isSpectating: isSpec));
      }

      // Then save to persistence
      _repository.saveInventory(_inventory);
    }
  }

  void _onUnlockItem(UnlockItem event, Emitter<GameState> emit) {
    if (!_inventory.ownedItemIds.contains(event.itemId)) {
      _inventory = _inventory.addItem(event.itemId);
      _repository.saveInventory(_inventory);

      if (state is GameOver) {
          final s = state as GameOver;
          emit(GameOver(
             board: s.board,
             winner: s.winner,
             rule: s.rule,
             mode: s.mode,
             difficulty: s.difficulty,
             inventory: _inventory,
             winningLine: s.winningLine,
             userProfile: _userProfile ?? s.userProfile,
             myPlayer: s.myPlayer,
             winReason: s.winReason,
          ));
      } else {
         bool isSpec = false;
         if (state is GameInProgress) isSpec = (state as GameInProgress).isSpectating;
         emit(_buildInProgressState(isSpectating: isSpec));
      }
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

  Future<void> _onResetGame(ResetGame event, Emitter<GameState> emit) async {
    if (_mode == GameMode.online) {
      _socketService.send({'type': 'LEAVE_ROOM'});
      // Small delay to ensure message is sent
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    _engine = null;
    _repository.clearGame();

    _socketService.disconnect();
    _messages.clear();
    _currentRoomCode = null;
    _timer?.cancel();
    emit(GameInitial(userProfile: _userProfile, inventory: _inventory));
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

  GameState _buildInProgressState({bool isSpectating = false, bool isAIThinking = false}) {
    if (_engine == null) return GameInitial(userProfile: _userProfile, inventory: _inventory);
    if (_engine!.isGameOver) {
       return GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
          mode: _mode,
          difficulty: _difficulty,
          inventory: _inventory,
          winningLine: _engine!.winningLine,
          userProfile: _userProfile,
          myPlayer: _myPlayer,
          winReason: null, // Local/AI logic doesn't set reason yet
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
      isAIThinking: isAIThinking,
      timeRemainingX: _timeRemainingX,
      timeRemainingO: _timeRemainingO,
      turnLimit: _turnLimit,
      currentTurnTimeRemaining: _currentTurnTimeRemaining,
    );

  }

  void _onTimerTicked(TimerTicked event, Emitter<GameState> emit) {
      if (state is GameOver) {
          _timer?.cancel();
          return;
      }
      if (_engine == null || _engine!.isGameOver) return;
      
      if (_engine!.currentPlayer == Player.x) {
          if (_timeRemainingX != null) {
              _timeRemainingX = _timeRemainingX! - const Duration(seconds: 1);
              if (_timeRemainingX!.isNegative) _timeRemainingX = Duration.zero;
          }
      } else {
           if (_timeRemainingO != null) {
              _timeRemainingO = _timeRemainingO! - const Duration(seconds: 1);
              if (_timeRemainingO!.isNegative) _timeRemainingO = Duration.zero;
          }
      }
      
      if (_currentTurnTimeRemaining != null) {
          _currentTurnTimeRemaining = _currentTurnTimeRemaining! - const Duration(seconds: 1);
          if (_currentTurnTimeRemaining!.isNegative) _currentTurnTimeRemaining = Duration.zero;
      }

      
      // Play tick sound if time is low (<= 10s)
      bool shouldTick = false;
      if (_engine!.currentPlayer == Player.x && _timeRemainingX != null && _timeRemainingX!.inSeconds <= 10 && _timeRemainingX!.inSeconds > 0) {
          shouldTick = true;
      } else if (_engine!.currentPlayer == Player.o && _timeRemainingO != null && _timeRemainingO!.inSeconds <= 10 && _timeRemainingO!.inSeconds > 0) {
          shouldTick = true;
      }

      if (shouldTick) {
          // Optimization: tick only if it's my turn OR I'm spectator
          if (_myPlayer == null || _myPlayer == _engine!.currentPlayer) {
             _audioService.playTimeTick();
          }
      }

      emit(_buildInProgressState());
  }

  void _startTimer() {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          add(TimerTicked());
      });
  }
}