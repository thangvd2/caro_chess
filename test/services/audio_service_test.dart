import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:caro_chess/services/audio_service.dart';

class MockAudioPlayer extends Mock implements AudioPlayer {}
class FakeSource extends Fake implements Source {}

void main() {
  group('AudioService', () {
    late AudioService service;
    late AudioPlayer mockPlayer;

    setUp(() {
      mockPlayer = MockAudioPlayer();
      service = AudioService(player: mockPlayer);
      registerFallbackValue(FakeSource());
      
      when(() => mockPlayer.play(any())).thenAnswer((_) async {});
      when(() => mockPlayer.stop()).thenAnswer((_) async {});
      when(() => mockPlayer.setSource(any())).thenAnswer((_) async {});
    });

    test('plays move sound', () async {
      await service.playMove();
      final captured = verify(() => mockPlayer.play(captureAny())).captured;
      expect(captured.last, isA<AssetSource>().having((s) => s.path, 'path', 'audio/move.mp3'));
    });

    test('plays win sound', () async {
      await service.playWin();
      final captured = verify(() => mockPlayer.play(captureAny())).captured;
      expect(captured.last, isA<AssetSource>().having((s) => s.path, 'path', 'audio/win.mp3'));
    });

    test('plays lose sound', () async {
      await service.playLose();
      final captured = verify(() => mockPlayer.play(captureAny())).captured;
      expect(captured.last, isA<AssetSource>().having((s) => s.path, 'path', 'audio/lose.mp3'));
    });
  });
}
