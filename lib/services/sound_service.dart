import 'package:audioplayers/audioplayers.dart';

/// Phát các tín hiệu âm thanh ngắn cho cuộc đua (tính năng bonus).
///
/// Cues là tài sản WAV được đóng gói. Playback là best-effort: mọi lỗi (ví dụ
/// hạn chế autoplay của trình duyệt) được bắt để âm thanh không bao giờ làm hỏng gameplay.
class SoundService {
  SoundService._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> _play(String asset) async {
    try {
      await _player.stop();
      await _player.play(AssetSource(asset));
    } catch (_) {
      // ignore: sound là tính năng bonus, không bao giờ chặn game trên nó.
    }
  }

  static Future<void> playStart() => _play('sounds/start.wav');
  static Future<void> playWin() => _play('sounds/win.wav');
  static Future<void> playLose() => _play('sounds/lose.wav');
}
