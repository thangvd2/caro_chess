import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/game_models.dart';
import '../engine/game_engine.dart';
import '../repositories/game_repository.dart';

// Events
abstract class GameEvent extends Equatable {
  const GameEvent();
  @override
  List<Object?> get props => [];
}

class StartGame extends GameEvent {
  final GameRule rule;
  const StartGame({this.rule = GameRule.standard});
  @override
  List<Object?> get props => [rule];
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

// States
abstract class GameState extends Equatable {
  const GameState();
  @override
  List<Object?> get props => [];
}

class GameInitial extends GameState {}

class GameInProgress extends GameState {
  final GameBoard board;
  final Player currentPlayer;
  final GameRule rule;
  final bool canUndo;
  final bool canRedo;

  const GameInProgress({
    required this.board,
    required this.currentPlayer,
    required this.rule,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  List<Object?> get props => [board, currentPlayer, rule, canUndo, canRedo];
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
  GameEngine? _engine;

  GameBloc({GameRepository? repository}) 
      : _repository = repository ?? GameRepository(),
        super(GameInitial()) {
    on<StartGame>(_onStartGame);
    on<LoadSavedGame>(_onLoadSavedGame);
    on<PlacePiece>(_onPlacePiece);
    on<ResetGame>(_onResetGame);
    on<UndoMove>(_onUndoMove);
    on<RedoMove>(_onRedoMove);
  }

  void _onStartGame(StartGame event, Emitter<GameState> emit) {
    _engine = GameEngine(rule: event.rule);
    _repository.saveGame(_engine!.rule, _engine!.history);
    emit(GameInProgress(
      board: _engine!.board,
      currentPlayer: _engine!.currentPlayer,
      rule: event.rule,
      canUndo: _engine!.canUndo,
      canRedo: _engine!.canRedo,
    ));
  }

  Future<void> _onLoadSavedGame(LoadSavedGame event, Emitter<GameState> emit) async {
    final savedData = await _repository.loadGame();
    if (savedData != null) {
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
        emit(GameInProgress(
          board: _engine!.board,
          currentPlayer: _engine!.currentPlayer,
          rule: _engine!.rule,
          canUndo: _engine!.canUndo,
          canRedo: _engine!.canRedo,
        ));
      }
    } else {
      add(const StartGame());
    }
  }

  void _onPlacePiece(PlacePiece event, Emitter<GameState> emit) {
    if (_engine == null) return;
    
    final success = _engine!.placePiece(event.position);
    if (success) {
      _repository.saveGame(_engine!.rule, _engine!.history);
      if (_engine!.isGameOver) {
        emit(GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
        ));
      } else {
        emit(GameInProgress(
          board: _engine!.board,
          currentPlayer: _engine!.currentPlayer,
          rule: _engine!.rule,
          canUndo: _engine!.canUndo,
          canRedo: _engine!.canRedo,
        ));
      }
    }
  }

  void _onResetGame(ResetGame event, Emitter<GameState> emit) {
    _engine = null;
    _repository.clearGame();
    emit(GameInitial());
  }
  
  void _onUndoMove(UndoMove event, Emitter<GameState> emit) {
    if (_engine == null) return;
    if (_engine!.undo()) {
       _repository.saveGame(_engine!.rule, _engine!.history);
       emit(GameInProgress(
          board: _engine!.board,
          currentPlayer: _engine!.currentPlayer,
          rule: _engine!.rule,
          canUndo: _engine!.canUndo,
          canRedo: _engine!.canRedo,
        ));
    }
  }
  
  void _onRedoMove(RedoMove event, Emitter<GameState> emit) {
    if (_engine == null) return;
    if (_engine!.redo()) {
       _repository.saveGame(_engine!.rule, _engine!.history);
       if (_engine!.isGameOver) {
        emit(GameOver(
          board: _engine!.board,
          winner: _engine!.winner,
          rule: _engine!.rule,
        ));
      } else {
        emit(GameInProgress(
          board: _engine!.board,
          currentPlayer: _engine!.currentPlayer,
          rule: _engine!.rule,
          canUndo: _engine!.canUndo,
          canRedo: _engine!.canRedo,
        ));
      }
    }
  }
}