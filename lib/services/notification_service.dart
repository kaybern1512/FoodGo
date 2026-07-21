import 'package:audioplayers/audioplayers.dart';

class NotificationService {
  NotificationService._();

  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playNewOrderSound() async {
    await _player.play(
      AssetSource('audio/notification.mp3'),
    );
  }
}
