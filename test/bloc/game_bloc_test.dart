import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/models/user_profile.dart';
import 'package:caro_chess/repositories/game_repository.dart';
import 'package:caro_chess/ai/ai_service.dart';
import 'package:caro_chess/services/web_socket_service.dart';

class MockGameRepository extends Mock implements GameRepository {}
class MockAIService extends Mock implements AIService {}
class MockWebSocketService extends Mock implements WebSocketService {}

void main() {
  late GameRepository repository;
  late AIService aiService;
  late WebSocketService socketService;
  late StreamController<dynamic> socketController;

  setUp(() {
    repository = MockGameRepository();
    aiService = MockAIService();
    socketService = MockWebSocketService();
    socketController = StreamController<dynamic>.broadcast();

    when(() => repository.saveGame(any(), any(), mode: any(named: 'mode'), difficulty: any(named: 'difficulty')))
        .thenAnswer((_) async {});
    when(() => repository.clearGame()).thenAnswer((_) async {});
    when(() => repository.loadGame()).thenAnswer((_) async => null);
    
    when(() => socketService.stream).thenAnswer((_) => socketController.stream);
    when(() => socketService.connect()).thenAnswer((_) {});
    when(() => socketService.send(any())).thenAnswer((_) {});
    when(() => socketService.disconnect()).thenAnswer((_) {});
  });

  tearDown(() {
    socketController.close();
  });

  setUpAll(() {
    registerFallbackValue(GameRule.standard);
    registerFallbackValue(<Position>[]);
    registerFallbackValue(AIDifficulty.medium);
    registerFallbackValue(GameMode.localPvP);
    registerFallbackValue(GameBoard(rows: 15, columns: 15));
    registerFallbackValue(Player.x);
  });

  group('GameBloc Profile Sync', () {
    blocTest<GameBloc, GameState>(
      'updates profile when UPDATE_RANK received',
      build: () => GameBloc(repository: repository, aiService: aiService, socketService: socketService),
      act: (bloc) async {
        bloc.add(const StartGame(mode: GameMode.online));
        await Future.delayed(const Duration(milliseconds: 10));
        socketController.add('{"type": "MATCH_FOUND", "color": "X"}');
        await Future.delayed(const Duration(milliseconds: 10));
        socketController.add('{"type": "UPDATE_RANK", "elo": 1216}');
      },
      wait: const Duration(milliseconds: 100),
      skip: 2, // Skip FindingMatch and initial InProgress
      expect: () => [
        isA<GameInProgress>().having((s) => s.userProfile?.elo, 'elo', 1216),
      ],
    );
  });
}
