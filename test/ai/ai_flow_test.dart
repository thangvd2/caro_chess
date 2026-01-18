
import 'package:bloc_test/bloc_test.dart';
import 'package:caro_chess/ai/ai_service.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/models/cosmetics.dart';
import 'package:caro_chess/repositories/game_repository.dart';
import 'package:caro_chess/services/audio_service.dart';
import 'package:caro_chess/services/web_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGameRepository extends Mock implements GameRepository {}
class MockWebSocketService extends Mock implements WebSocketService {}
class MockAudioService extends Mock implements AudioService {}

void main() {
  late MockGameRepository mockRepository;
  late MockWebSocketService mockSocketService;
  late MockAudioService mockAudioService;
  late AIService aiService;

  setUpAll(() {
    registerFallbackValue(GameRule.standard);
    registerFallbackValue(GameMode.vsAI);
    registerFallbackValue(AIDifficulty.easy);
  });

  setUp(() {
    mockRepository = MockGameRepository();
    mockSocketService = MockWebSocketService();
    mockAudioService = MockAudioService();
    aiService = AIService();

    when(() => mockRepository.loadInventory()).thenAnswer((_) async => const Inventory());
    when(() => mockRepository.saveGame(any(), any(), mode: any(named: 'mode'), difficulty: any(named: 'difficulty')))
        .thenAnswer((_) async {});
    when(() => mockAudioService.playMove()).thenAnswer((_) async {});
  });

  group('GameBloc AI Flow Integration', () {
    blocTest<GameBloc, GameState>(
      'should start game vs AI and trigger AI move after player move',
      build: () => GameBloc(
        repository: mockRepository,
        socketService: mockSocketService,
        audioService: mockAudioService,
        aiService: aiService,
      ),
      act: (bloc) async {
        bloc.add(const StartGame(mode: GameMode.vsAI, difficulty: AIDifficulty.easy));
        await Future.delayed(const Duration(milliseconds: 100)); // Wait for init
        bloc.add(const PlacePiece(Position(x: 7, y: 7)));
      },
      wait: const Duration(seconds: 3), // Wait for AI thinking delay (1s) + computation
      expect: () => [
        // Start Game emits InProgress
        isA<GameInProgress>().having((s) => s.mode, 'mode', GameMode.vsAI),
        
        // Place Piece emits InProgress (Player O turn)
        isA<GameInProgress>()
            .having((s) => s.currentPlayer, 'currentPlayer', Player.o)
            .having((s) => s.board.cells[7][7].owner, 'owner at 7,7', Player.x),
        
        // AIMoveRequested emits InProgress (isAIThinking: true)
        isA<GameInProgress>()
            .having((s) => s.isAIThinking, 'isAIThinking', true),
            
        // AI Closes move emits InProgress (Player X turn, AI Move placed)
        isA<GameInProgress>()
             .having((s) => s.isAIThinking, 'isAIThinking', false)
             .having((s) => s.currentPlayer, 'currentPlayer', Player.x)
             .having((s) => s.board.cells.expand((r) => r).where((c) => c.owner == Player.o).length, 'AI piece count', 1),
      ],
    );
  });
}
