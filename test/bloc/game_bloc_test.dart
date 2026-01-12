import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';

void main() {
  group('GameBloc', () {
    
    test('initial state is GameInitial', () {
      expect(GameBloc().state, equals(GameInitial()));
    });

    blocTest<GameBloc, GameState>(
      'emits [GameInProgress] when StartGame is added',
      build: () => GameBloc(),
      act: (bloc) => bloc.add(const StartGame(rule: GameRule.standard)),
      expect: () => [
        isA<GameInProgress>().having((state) => state.rule, 'rule', GameRule.standard),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits [GameInProgress] with updated board when PlacePiece is added',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const StartGame());
        bloc.add(const PlacePiece(Position(x: 0, y: 0)));
      },
      skip: 1, 
      expect: () => [
        isA<GameInProgress>()
            .having((state) => state.board.cells[0][0].owner, 'cell owner', Player.x)
            .having((state) => state.currentPlayer, 'currentPlayer', Player.o),
      ],
    );

    blocTest<GameBloc, GameState>(
      'emits [GameOver] when winning move is made',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const StartGame());
        // X wins horizontally
        for(int i=0; i<5; i++) {
           bloc.add(PlacePiece(Position(x: i, y: 0))); // X
           if (i < 4) bloc.add(PlacePiece(Position(x: i, y: 1))); // O
        }
      },
      skip: 9, // 1 Start + 8 moves
      expect: () => [
        isA<GameOver>().having((state) => state.winner, 'winner', Player.x),
      ],
    );
    
    blocTest<GameBloc, GameState>(
      'emits [GameInitial] when ResetGame is added',
      build: () => GameBloc(),
      act: (bloc) {
        bloc.add(const StartGame());
        bloc.add(ResetGame());
      },
      skip: 1,
      expect: () => [GameInitial()],
    );
  });
}
