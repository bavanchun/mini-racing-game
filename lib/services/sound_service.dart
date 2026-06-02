import 'package:audioplayers/audioplayers.dart';

/// Plays the short race sound cues (bonus feature).
///
/// Cues are bundled WAV assets. Playback is best-effort: any failure (e.g.
/// browser autoplay restrictions) is caught so audio never breaks gameplay.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // ignore: sound is a bonus, never block the game on it.
    }
  }

  static Future<void> playStart() => _play('sounds/start.wav');
  static Future<void> playWin() => _play('sounds/win.wav');
  static Future<void> playLose() => _play('sounds/lose.wav');
}
