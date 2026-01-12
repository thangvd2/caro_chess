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

  group('GameBloc', () {
    blocTest<GameBloc, GameState>(
      'plays move sound on PlacePiece success',
      build: () => GameBloc(
          repository: repository, 
          aiService: aiService, 
          socketService: socketService,
          audioService: audioService
      ),
      act: (bloc) {
        bloc.add(const StartGame());
        bloc.add(const PlacePiece(Position(x: 0, y: 0)));
      },
      verify: (_) {
        verify(() => audioService.playMove()).called(1);
      },
    );
  });
}