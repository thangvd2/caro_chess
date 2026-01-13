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

  group('GameBoardWidget', () {
    late GameBloc gameBloc;

    setUp(() {
      gameBloc = MockGameBloc();
    });

    testWidgets('renders grid of cells', (tester) async {
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

      expect(find.byType(BoardCell), findsWidgets);
    });

    testWidgets('tapping a cell adds PlacePiece event', (tester) async {
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

      await tester.tap(find.byType(BoardCell).first);
      
      verify(() => gameBloc.add(any(that: isA<PlacePiece>()))).called(1);
    });
    
    testWidgets('renders X and O correctly', (tester) async {
        final board = GameBoard(rows: 15, columns: 15);
        board.cells[0][0] = const Cell(position: Position(x: 0, y: 0), owner: Player.x);
        board.cells[0][1] = const Cell(position: Position(x: 1, y: 0), owner: Player.o);
        
        when(() => gameBloc.state).thenReturn(GameInProgress(
            board: board,
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
        
        expect(find.text('X'), findsOneWidget);
        expect(find.text('O'), findsOneWidget);
    });
  });
}
