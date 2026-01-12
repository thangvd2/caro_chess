import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/ui/game_controls_widget.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(GameInitial());
    registerFallbackValue(ResetGame());
    registerFallbackValue(UndoMove());
    registerFallbackValue(RedoMove());
  });

  group('GameControlsWidget', () {
    late GameBloc gameBloc;

    setUp(() {
      gameBloc = MockGameBloc();
    });

    testWidgets('shows current turn', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.standard,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const GameControlsWidget(),
          ),
        ),
      );

      expect(find.textContaining('Current Turn: X'), findsOneWidget);
    });

    testWidgets('shows winner when game over', (tester) async {
      when(() => gameBloc.state).thenReturn(GameOver(
        board: GameBoard(rows: 15, columns: 15),
        winner: Player.o,
        rule: GameRule.standard,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const GameControlsWidget(),
          ),
        ),
      );

      expect(find.textContaining('Winner: O'), findsOneWidget);
    });

    testWidgets('reset button triggers ResetGame', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.standard,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const GameControlsWidget(),
          ),
        ),
      );

      await tester.tap(find.text('Reset Game'));
      verify(() => gameBloc.add(ResetGame())).called(1);
    });

    testWidgets('shows Undo/Redo buttons and triggers events', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.standard,
        canUndo: true,
        canRedo: true,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const GameControlsWidget(),
          ),
        ),
      );

      expect(find.text('Undo'), findsOneWidget);
      expect(find.text('Redo'), findsOneWidget);
      
      await tester.tap(find.text('Undo'));
      verify(() => gameBloc.add(UndoMove())).called(1);
      
      await tester.tap(find.text('Redo'));
      verify(() => gameBloc.add(RedoMove())).called(1);
    });

    testWidgets('Undo/Redo buttons disabled when not allowed', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.standard,
        canUndo: false,
        canRedo: false,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const GameControlsWidget(),
          ),
        ),
      );
      
      await tester.tap(find.text('Undo'));
      verifyNever(() => gameBloc.add(UndoMove()));
      
      await tester.tap(find.text('Redo'));
      verifyNever(() => gameBloc.add(RedoMove()));
    });
  });
}