import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/models/cosmetics.dart';
import 'package:caro_chess/ui/rule_guidelines_widget.dart';
import 'package:caro_chess/ai/ai_service.dart';

class MockGameBloc extends MockBloc<GameEvent, GameState> implements GameBloc {}

void main() {
  group('RuleGuidelinesWidget', () {
    late GameBloc gameBloc;

    setUp(() {
      gameBloc = MockGameBloc();
    });

    testWidgets('shows standard rule details', (tester) async {
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
            child: const RuleGuidelinesWidget(),
          ),
        ),
      );

      expect(find.textContaining('Standard Gomoku'), findsOneWidget);
    });

    testWidgets('shows caro rule details', (tester) async {
      when(() => gameBloc.state).thenReturn(GameInProgress(
        board: GameBoard(rows: 15, columns: 15),
        currentPlayer: Player.x,
        rule: GameRule.caro,
        mode: GameMode.localPvP,
        difficulty: AIDifficulty.medium,
        inventory: const Inventory(),
      ));

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: gameBloc,
            child: const RuleGuidelinesWidget(),
          ),
        ),
      );

      expect(find.textContaining('Vietnamese Caro'), findsOneWidget);
      expect(find.textContaining('blocked at both ends'), findsOneWidget);
    });
  });
}
