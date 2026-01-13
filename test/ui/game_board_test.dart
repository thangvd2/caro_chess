import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/models/cosmetics.dart';
import 'package:caro_chess/ui/game_board_widget.dart';
import 'package:caro_chess/ai/ai_service.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  setUpAll(() {
    registerFallbackValue(GameInitial());
    registerFallbackValue(const PlacePiece(Position(x: 0, y: 0)));
  });

  group('GameBoardWidget Themes', () {
    late GameBloc gameBloc;

    setUp(() {
      gameBloc = MockGameBloc();
    });

    testWidgets('renders with default white theme', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.standard,
        mode: GameMode.localPvP,
        difficulty: AIDifficulty.medium,
        inventory: const Inventory(),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const GameBoardWidget(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, equals(Colors.white));
    });

    testWidgets('renders with dark theme', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.standard,
        mode: GameMode.localPvP,
        difficulty: AIDifficulty.medium,
        inventory: const Inventory(equippedBoardSkinId: 'dark_board'),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const GameBoardWidget(),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, equals(Colors.black87));
    });
  });
}