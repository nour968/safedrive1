import 'package:audioplayers/audioplayers.dart';

class AlertSoundService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> playAlert() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/alert.wav'));
    } catch (e) {
      print("Sound error: $e");
    }
  }
}