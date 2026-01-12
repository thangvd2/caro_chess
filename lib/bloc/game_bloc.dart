import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/game_models.dart';
import '../models/user_profile.dart';
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

// States
abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}
class GameFindingMatch extends GameState {}
class GameAIThinking extends GameState {}

class GameInProgress extends GameState {
  final GameBoard board;
  final Player currentPlayer;
  final GameRule rule;
  final GameMode mode;
  final AIDifficulty difficulty;
  final Player? myPlayer;
  final UserProfile? userProfile;
  final bool canUndo;
  final bool canRedo;

  const GameInProgress({
    required this.board,
    required this.currentPlayer,
    required this.rule,
    required this.mode,
    required this.difficulty,
    this.myPlayer,
    this.userProfile,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  List<Object?> get props => [board, currentPlayer, rule, mode, difficulty, myPlayer, userProfile, canUndo, canRedo];
}

class GameOver extends GameState {
  final GameBoard board;
  final Player? winner;
  final GameRule rule;
  final List<Position>? winningLine;

  const GameOver({required this.board, this.winner, required this.rule, this.winningLine});

  @override
  List<Object?> get props => [board, winner, rule, winningLine];
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

  GameBloc({GameRepository? repository, AIService? aiService, WebSocketService? socketService, AudioService? audioService}) 
      : _repository = repository ?? GameRepository(),
        _aiService = aiService ?? AIService(),
        _socketService = socketService ?? WebSocketService(),
        _audioService = audioService ?? AudioService(),
        super(GameInitial()) {
    on<StartGame>(_onStartGame);
    on<LoadSavedGame>(_onLoadSavedGame);
    on<PlacePiece>(_onPlacePiece);
    on<ResetGame>(_onResetGame);
    on<UndoMove>(_onUndoMove);
    on<RedoMove>(_onRedoMove);
    on<AIMoveRequested>(_onAIMoveRequested);
    on<SocketMessageReceived>(_onSocketMessageReceived);
  }

  @override
  Future<void> close() {
    _socketSubscription?.cancel();
    return super.close();
  }

  void _onStartGame(StartGame event, Emitter<GameState> emit) {
    _mode = event.mode;
    _difficulty = event.difficulty;
    _myPlayer = null;

    if (_mode == GameMode.online) {
      emit(GameFindingMatch());
      _socketService.connect();
      _socketSubscription?.cancel();
      _socketSubscription = _socketService.stream.listen((msg) {
        add(SocketMessageReceived(msg));
      });
    } else {
      _engine = GameEngine(rule: event.rule);
      _saveState();
      emit(_buildInProgressState());
    }
  }

  void _onSocketMessageReceived(SocketMessageReceived event, Emitter<GameState> emit) {
    final dynamic msgRaw = event.message;
    final msg = jsonDecode(msgRaw is String ? msgRaw : utf8.decode(msgRaw));

    if (msg['type'] == 'MATCH_FOUND') {
      _myPlayer = msg['color'] == 'X' ? Player.x : Player.o;
      _engine = GameEngine(rule: GameRule.standard);
      emit(_buildInProgressState());
    } else if (msg['type'] == 'MOVE_MADE') {
      final pos = Position(x: msg['x'], y: msg['y']);
      if (_engine != null && _engine!.currentPlayer != _myPlayer) {
        _engine!.placePiece(pos);
        _audioService.playMove();
        if (_engine!.isGameOver) {
          _playWinLoseSound();
          emit(GameOver(board: _engine!.board, winner: _engine!.winner, rule: _engine!.rule, winningLine: _engine!.winningLine));
        } else {
          emit(_buildInProgressState());
        }
      }
    } else if (msg['type'] == 'UPDATE_RANK') {
      _userProfile = UserProfile(id: _userProfile?.id ?? "Player", elo: msg['elo']);
      if (state is GameInProgress || state is GameOver) {
        emit(_buildInProgressState());
      }
    }
  }

  Future<void> _onLoadSavedGame(LoadSavedGame event, Emitter<GameState> emit) async {
    final savedData = await _repository.loadGame();
    if (savedData != null) {
      _mode = savedData['mode'] as GameMode;
      _difficulty = savedData['difficulty'] as AIDifficulty;
      final rule = savedData['rule'] as GameRule;
      final history = savedData['history'] as List<Position>;
      
      _engine = GameEngine(rule: rule);
      for (final pos in history) {
        _engine!.placePiece(pos);
      }
      
      if (_engine!.isGameOver) {
        emit(GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
          winningLine: _engine!.winningLine,
        ));
      } else {
        emit(_buildInProgressState());
      }
    } else {
      add(const StartGame());
    }
  }

  void _onPlacePiece(PlacePiece event, Emitter<GameState> emit) {
    if (_engine == null) return;
    if (_mode == GameMode.online && _engine!.currentPlayer != _myPlayer) return;

    final success = _engine!.placePiece(event.position);
    if (success) {
      _audioService.playMove();
      if (_mode == GameMode.online) {
        _socketService.send({
          'type': 'MOVE',
          'x': event.position.x,
          'y': event.position.y,
        });
      }

      _saveState();
      if (_engine!.isGameOver) {
        _playWinLoseSound();
        emit(GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
          winningLine: _engine!.winningLine,
        ));
      } else {
        emit(_buildInProgressState());
        
        if (_mode == GameMode.vsAI && _engine!.currentPlayer == Player.o) {
          add(AIMoveRequested());
        }
      }
    }
  }

  Future<void> _onAIMoveRequested(AIMoveRequested event, Emitter<GameState> emit) async {
    emit(GameAIThinking());
    final move = await _aiService.getBestMove(_engine!.board, Player.o, difficulty: _difficulty);
    add(PlacePiece(move));
  }

  void _onResetGame(ResetGame event, Emitter<GameState> emit) {
    _engine = null;
    _repository.clearGame();
    _socketService.disconnect();
    emit(GameInitial());
  }
  
  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    if (_engine == null || _mode == GameMode.online) return;
    if (_engine!.undo()) {
       _saveState();
       emit(_buildInProgressState());
    }
  }
  
  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    if (_engine == null || _mode == GameMode.online) return;
    if (_engine!.redo()) {
       _saveState();
       if (_engine!.isGameOver) {
        emit(GameOver(board: _engine!.board, winner: _engine!.winner, rule: _engine!.rule, winningLine: _engine!.winningLine));
      } else {
        emit(_buildInProgressState());
      }
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

  GameState _buildInProgressState() {
    if (_engine!.isGameOver) {
       return GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
          winningLine: _engine!.winningLine,
        );
    }
    return GameInProgress(
      board: _engine!.board,
      currentPlayer: _engine!.currentPlayer,
      rule: _engine!.rule,
      mode: _mode,
      difficulty: _difficulty,
      myPlayer: _myPlayer,
      userProfile: _userProfile,
      canUndo: _engine!.canUndo,
      canRedo: _engine!.canRedo,
    );
  }
}