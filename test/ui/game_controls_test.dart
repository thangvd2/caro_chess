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
  });
}
