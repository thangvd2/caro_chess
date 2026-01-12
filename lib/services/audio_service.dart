import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioPlayer _player;

  AudioService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  Future<void> playMove() async {
    await _player.play(AssetSource('audio/move.mp3'));
  }

  Future<void> playWin() async {
    await _player.play(AssetSource('audio/win.mp3'));
  }

  Future<void> playLose() async {
    await _player.play(AssetSource('audio/lose.mp3'));
  }
}
