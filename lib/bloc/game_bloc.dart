import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/game_models.dart';
import '../engine/game_engine.dart';
import '../repositories/game_repository.dart';
import '../ai/ai_service.dart';

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

// States
abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameAIThinking extends GameState {}

class GameInProgress extends GameState {
  final GameBoard board;
  final Player currentPlayer;
  final GameRule rule;
  final GameMode mode;
  final AIDifficulty difficulty;
  final bool canUndo;
  final bool canRedo;

  const GameInProgress({
    required this.board,
    required this.currentPlayer,
    required this.rule,
    required this.mode,
    required this.difficulty,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  List<Object?> get props => [board, currentPlayer, rule, mode, difficulty, canUndo, canRedo];
}

class GameOver extends GameState {
  final GameBoard board;
  final Player? winner;
  final GameRule rule;

  const GameOver({required this.board, this.winner, required this.rule});

  @override
  List<Object?> get props => [board, winner, rule];
}

// Bloc
class GameBloc extends Bloc<GameEvent, GameState> {
  final GameRepository _repository;
  final AIService _aiService;
  GameEngine? _engine;
  GameMode _mode = GameMode.localPvP;
  AIDifficulty _difficulty = AIDifficulty.medium;

  GameBloc({GameRepository? repository, AIService? aiService}) 
      : _repository = repository ?? GameRepository(),
        _aiService = aiService ?? AIService(),
        super(GameInitial()) {
    on<StartGame>(_onStartGame);
    on<LoadSavedGame>(_onLoadSavedGame);
    on<PlacePiece>(_onPlacePiece);
    on<ResetGame>(_onResetGame);
    on<UndoMove>(_onUndoMove);
    on<RedoMove>(_onRedoMove);
    on<AIMoveRequested>(_onAIMoveRequested);
  }

  void _onStartGame(StartGame event, Emitter<GameState> emit) {
    _mode = event.mode;
    _difficulty = event.difficulty;
    _engine = GameEngine(rule: event.rule);
    _saveState();
    emit(_buildInProgressState());
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
    
    final success = _engine!.placePiece(event.position);
    if (success) {
      _saveState();
      if (_engine!.isGameOver) {
        emit(GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
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
    
    final move = await _aiService.getBestMove(
      _engine!.board, 
      Player.o, 
      difficulty: _difficulty,
    );
    
    add(PlacePiece(move));
  }

  void _onResetGame(ResetGame event, Emitter<GameState> emit) {
    _engine = null;
    _repository.clearGame();
    emit(GameInitial());
  }
  
  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    if (_engine == null) return;
    if (_engine!.undo()) {
       _saveState();
       emit(_buildInProgressState());
    }
  }
  
  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    if (_engine == null) return;
    if (_engine!.redo()) {
       _saveState();
       if (_engine!.isGameOver) {
        emit(GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
        ));
      } else {
        emit(_buildInProgressState());
      }
    }
  }

  void _saveState() {
    if (_engine != null) {
      _repository.saveGame(_engine!.rule, _engine!.history, mode: _mode, difficulty: _difficulty);
    }
  }

  GameInProgress _buildInProgressState() {
    return GameInProgress(
      board: _engine!.board,
      currentPlayer: _engine!.currentPlayer,
      rule: _engine!.rule,
      mode: _mode,
      difficulty: _difficulty,
      canUndo: _engine!.canUndo,
      canRedo: _engine!.canRedo,
    );
  }
}