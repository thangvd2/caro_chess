import 'package:audioplayers/audioplayers.dart';

typedef AudioPlayerFactory = AudioPlayer Function();

class AudioService {
  final AudioPlayerFactory _playerFactory;

  AudioService({AudioPlayerFactory? playerFactory})
      : _playerFactory = playerFactory ?? (() => AudioPlayer());

  // Use a transient player for each sound to allow polyphony and avoid
  // "interrupted by a call to pause" errors on Web.
  // The player will automatically dispose resources after playback due to ReleaseMode.release
  Future<void> _playSound(String path) async {
    try {
      final player = _playerFactory();
      // Ensure the player releases resources once playback is complete
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource(path));
    } catch (e) {
      // Ignore generic audio errors (common on Web if auto-play policy blocks it
      // or if interactions happen too quickly)
      print("Audio Service Error: $e");
    }
  }

  Future<void> playMove() async {
    await _playSound('audio/move.mp3');
  }

  Future<void> playWin() async {
    await _playSound('audio/win.mp3');
  }

  Future<void> playLose() async {
    await _playSound('audio/lose.mp3');
  }

  Future<void> playGameStart() async {
    await _playSound('audio/start.wav');
  }

  Future<void> playTimeTick() async {
    await _playSound('audio/tick.wav');
  }
}
