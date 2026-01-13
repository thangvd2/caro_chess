import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/models/user_profile.dart';
import 'package:caro_chess/models/cosmetics.dart';
import 'package:caro_chess/models/chat_message.dart';
import 'package:caro_chess/repositories/game_repository.dart';
import 'package:caro_chess/ai/ai_service.dart';
import 'package:caro_chess/services/web_socket_service.dart';
import 'package:caro_chess/services/audio_service.dart';
import 'package:caro_chess/ui/store_screen.dart';

class MockGameRepository extends Mock implements GameRepository {}
class MockAIService extends Mock implements AIService {}
class MockWebSocketService extends Mock implements WebSocketService {}
class MockAudioService extends Mock implements AudioService {}

void main() {
  late GameRepository repository;
  late AIService aiService;
  late WebSocketService socketService;
  late AudioService audioService;
  late StreamController<dynamic> socketController;

  setUp(() {
    repository = MockGameRepository();
    aiService = MockAIService();
    socketService = MockWebSocketService();
    audioService = MockAudioService();
    socketController = StreamController<dynamic>.broadcast();

    when(() => repository.saveGame(any(), any(), mode: any(named: 'mode'), difficulty: any(named: 'difficulty')))
        .thenAnswer((_) async {});
    when(() => repository.clearGame()).thenAnswer((_) async {});
    when(() => repository.loadGame()).thenAnswer((_) async => null);
    when(() => repository.loadInventory()).thenAnswer((_) async => const Inventory(coins: 0));
    when(() => repository.saveInventory(any())).thenAnswer((_) async {});
    
    when(() => socketService.stream).thenAnswer((_) => socketController.stream);
    when(() => socketService.connect()).thenAnswer((_) {});
    when(() => socketService.send(any())).thenAnswer((_) {});
    when(() => socketService.disconnect()).thenAnswer((_) {});

    when(() => audioService.playMove()).thenAnswer((_) async {});
    when(() => audioService.playWin()).thenAnswer((_) async {});
    when(() => audioService.playLose()).thenAnswer((_) async {});
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
    registerFallbackValue(const Inventory());
  });

  group('GameBloc Chat Integration', () {
    blocTest<GameBloc, GameState>(
      'emits state with new message when socket sends CHAT_MESSAGE',
      build: () => GameBloc(
        repository: repository, 
        socketService: socketService, 
        audioService: audioService,
        aiService: aiService,
      ),
      act: (bloc) async {
        bloc.add(const StartGame(mode: GameMode.online));
        await Future.delayed(const Duration(milliseconds: 20));
        // Match found first?
        socketController.add('{"type": "MATCH_FOUND", "color": "X"}');
        await Future.delayed(const Duration(milliseconds: 10));
        socketController.add('{"type": "CHAT_MESSAGE", "text": "Hello", "sender_id": "user2"}');
      },
      wait: const Duration(milliseconds: 100),
      skip: 2, // Skip FindingMatch and MatchFound
      expect: () => [
        isA<GameInProgress>().having((s) => s.messages.last.text, 'message text', 'Hello'),
      ],
    );
  });
}