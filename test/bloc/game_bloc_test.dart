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
import 'package:caro_chess/services/audio_service.dart';

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
}
