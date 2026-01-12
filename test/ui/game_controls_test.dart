import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/ui/game_controls_widget.dart';
import 'package:caro_chess/ai/ai_service.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(GameInitial());
    registerFallbackValue(ResetGame());
    registerFallbackValue(UndoMove());
    registerFallbackValue(RedoMove());
    registerFallbackValue(const StartGame());
  });

  group('GameControlsWidget', () {
    late GameBloc gameBloc;

    setUp(() {
      gameBloc = MockGameBloc();
    });

    testWidgets('shows vs AI options in Initial state', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInitial());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: gameBloc,
              child: const GameControlsWidget(),
            ),
          ),
        ),
      );

      expect(find.text('Play vs AI'), findsOneWidget);
      expect(find.byType(DropdownButton<AIDifficulty>), findsOneWidget);
    });

    testWidgets('shows thinking indicator', (tester) async {
      when(() => gameBloc.state).thenReturn(GameAIThinking());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: gameBloc,
              child: const GameControlsWidget(),
            ),
          ),
        ),
      );

      expect(find.textContaining('AI is thinking'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('reset button triggers ResetGame', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.standard,
        mode: GameMode.localPvP,
        difficulty: AIDifficulty.medium,
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BlocProvider.value(
              value: gameBloc,
              child: const GameControlsWidget(),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Reset Game'));
      verify(() => gameBloc.add(ResetGame())).called(1);
    });
  });
}