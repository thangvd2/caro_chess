import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/repositories/game_repository.dart';

class MockGameRepository extends Mock implements GameRepository {}

void main() {
  late GameRepository repository;

  setUp(() {
    repository = MockGameRepository();
    when(() => repository.saveGame(any(), any())).thenAnswer((_) async {});
    when(() => repository.clearGame()).thenAnswer((_) async {});
    when(() => repository.loadGame()).thenAnswer((_) async => null);
  });

  setUpAll(() {
    registerFallbackValue(GameRule.standard);
    registerFallbackValue(<Position>[]);
  });

  group('GameBloc', () {
    
    test('initial state is GameInitial', () {
      expect(GameBloc(repository: repository).state, equals(GameInitial()));
    });

    blocTest<GameBloc, GameState>(
      'emits [GameInProgress] when StartGame is added',
      build: () => GameBloc(repository: repository),
      act: (bloc) => bloc.add(const StartGame(rule: GameRule.standard)),
      expect: () => [
        isA<GameInProgress>().having((state) => state.rule, 'rule', GameRule.standard),
      ],
      verify: (_) {
        verify(() => repository.saveGame(GameRule.standard, any())).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameInProgress] with updated board when PlacePiece is added',
      build: () => GameBloc(repository: repository),
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
      verify: (_) {
        verify(() => repository.saveGame(any(), any())).called(2);
      },
    );

    blocTest<GameBloc, GameState>(
      'emits [GameOver] when winning move is made',
      build: () => GameBloc(repository: repository),
      act: (bloc) {
        bloc.add(const StartGame());
        for(int i=0; i<5; i++) {
           bloc.add(PlacePiece(Position(x: i, y: 0))); // X
           if (i < 4) bloc.add(PlacePiece(Position(x: i, y: 1))); // O
        }
      },
      skip: 9, 
      expect: () => [
        isA<GameOver>().having((state) => state.winner, 'winner', Player.x),
      ],
    );
    
    blocTest<GameBloc, GameState>(
      'emits [GameInitial] when ResetGame is added',
      build: () => GameBloc(repository: repository),
      act: (bloc) {
        bloc.add(const StartGame());
        bloc.add(ResetGame());
      },
      skip: 1,
      expect: () => [GameInitial()],
      verify: (_) {
        verify(() => repository.clearGame()).called(1);
      },
    );
  });
}