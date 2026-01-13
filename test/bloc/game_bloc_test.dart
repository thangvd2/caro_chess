import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:caro_chess/bloc/game_bloc.dart';
import 'package:caro_chess/models/game_models.dart';
import 'package:caro_chess/models/user_profile.dart';
import 'package:caro_chess/models/cosmetics.dart';
import 'package:caro_chess/repositories/game_repository.dart';
import 'package:caro_chess/ai/ai_service.dart';
import 'package:caro_chess/services/web_socket_service.dart';
import 'package:caro_chess/services/audio_service.dart';
import 'package:caro_chess/ui/store_screen.dart'; // For allSkins

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

  group('GameBloc Room Features', () {
    blocTest<GameBloc, GameState>(
      'emits [GameWaitingInRoom] when ROOM_CREATED received',
      build: () => GameBloc(
        repository: repository, 
        socketService: socketService,
        audioService: audioService,
        aiService: aiService,
      ),
      act: (bloc) async {
        bloc.add(StartRoomCreation()); 
        await Future.delayed(const Duration(milliseconds: 10));
        socketController.add('{"type": "ROOM_CREATED", "code": "ABCD"}');
      },
      expect: () => [
        isA<GameFindingMatch>(),
        isA<GameWaitingInRoom>().having((s) => s.code, 'code', 'ABCD'),
      ],
    );
  });

  group('GameBloc Cosmetics', () {
    blocTest<GameBloc, GameState>(
      'awards 50 coins on win',
      build: () => GameBloc(
        repository: repository,
        audioService: audioService,
      ),
      act: (bloc) async {
        bloc.add(const StartGame());
        await Future.delayed(Duration.zero);
        for(int i=0; i<5; i++) {
           bloc.add(PlacePiece(Position(x: i, y: 0))); // X
           if (i < 4) bloc.add(PlacePiece(Position(x: i, y: 1))); // O
        }
      },
      verify: (_) {
        verify(() => repository.saveInventory(
          any(that: isA<Inventory>().having((i) => i.coins, 'coins', 50))
        )).called(1);
      },
    );

    blocTest<GameBloc, GameState>(
      'purchasing item deducts coins and adds to inventory',
      build: () {
        when(() => repository.loadInventory()).thenAnswer((_) async => const Inventory(coins: 200));
        return GameBloc(repository: repository, audioService: audioService);
      },
      act: (bloc) async {
        bloc.add(const StartGame());
        await Future.delayed(Duration.zero);
        bloc.add(PurchaseItemRequested(allSkins[0])); // Price 100
      },
      skip: 1, 
      expect: () => [
        isA<GameInProgress>()
            .having((s) => s.inventory.coins, 'coins', 100)
            .having((s) => s.inventory.ownedItemIds, 'owned', contains(allSkins[0].id)),
      ],
    );
  });
}
