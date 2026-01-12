import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/repositories/game_repository.dart';
import 'package:caro_chess/ai/ai_service.dart';

class MockGameRepository extends Mock implements GameRepository {}
class MockAIService extends Mock implements AIService {}

void main() {
  late GameRepository repository;
  late AIService aiService;

  setUp(() {
    repository = MockGameRepository();
    aiService = MockAIService();
    when(() => repository.saveGame(any(), any(), mode: any(named: 'mode'), difficulty: any(named: 'difficulty')))
        .thenAnswer((_) async {});
    when(() => repository.clearGame()).thenAnswer((_) async {});
    when(() => repository.loadGame()).thenAnswer((_) async => null);
    when(() => aiService.getBestMove(any(), any(), difficulty: any(named: 'difficulty')))
        .thenAnswer((_) async => const Position(x: 1, y: 1));
  });

  setUpAll(() {
    registerFallbackValue(GameRule.standard);
    registerFallbackValue(<Position>[]);
    registerFallbackValue(AIDifficulty.medium);
    registerFallbackValue(GameMode.localPvP);
    registerFallbackValue(GameBoard(rows: 15, columns: 15));
    registerFallbackValue(Player.x);
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
    );

    group('AI Integration', () {
      blocTest<GameBloc, GameState>(
        'triggers AI move after human move in vsAI mode',
        build: () => GameBloc(repository: repository, aiService: aiService),
        act: (bloc) {
          bloc.add(const StartGame(mode: GameMode.vsAI));
          bloc.add(const PlacePiece(Position(x: 0, y: 0)));
        },
        skip: 1, 
        expect: () => [
          isA<GameInProgress>().having((s) => s.currentPlayer, 'currentPlayer', Player.o),
          isA<GameAIThinking>(),
          isA<GameInProgress>().having((s) => s.currentPlayer, 'currentPlayer', Player.x),
        ],
      );
    });
  });
}