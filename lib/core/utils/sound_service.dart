import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';

class SoundService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Ref _ref;

  SoundService(this._ref) {
    // Preload sounds for faster playback if needed
  }

  Future<void> playCorrectSound() async {
    await _playSound('sounds/correct.mp3');
  }

  Future<void> playIncorrectSound() async {
    await _playSound('sounds/incorrect.mp3');
  }

  Future<void> _playSound(String assetPath) async {
    final settings = _ref.read(settingsProvider);
    if (settings['sound'] == true) {
      await _audioPlayer.play(AssetSource(assetPath));
    }
  }
}

final soundServiceProvider = Provider((ref) => SoundService(ref));