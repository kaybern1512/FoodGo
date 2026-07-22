import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  NotificationService._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playNewOrderSound() async {
    try {
      await _player.stop();
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.release);
      await _player.play(
        AssetSource('audio/notification.mp3'),
      );
    } catch (e) {
      debugPrint('Không thể phát âm thanh đơn hàng mới: $e');
    }
  }
}
