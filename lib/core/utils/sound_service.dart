import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';

class SoundService {
  final Ref _ref;
  // AudioCache is used to pre-load sounds for instant playback.
  final AudioCache _audioCache = AudioCache(prefix: 'assets/sounds/');

  SoundService(this._ref);

  // This method should be called on app startup to load the sounds into memory.
  Future<void> preloadSounds() async {
    // You can add a print statement here to confirm preloading in debug mode.
    print("Preloading sounds...");
    await _audioCache.loadAll(['correct.mp3', 'incorrect.mp3']);
    print("Sounds preloaded successfully.");
  }

  void _playSound(String soundFile) {
    if (_ref.read(settingsProvider)['sound'] ?? true) {
      // ## THE FIX: Create a new player for each sound ##
      // This is a "fire and forget" method. Each sound is independent.
      final player = AudioPlayer();
      // Tell the player to dispose of itself after it's done.
      player.setReleaseMode(ReleaseMode.release);
      // Play the sound from the cache.
      player.play(AssetSource('sounds/$soundFile'));
    }
  }

  void playCorrectSound() {
    _playSound('correct.mp3');
  }

  void playIncorrectSound() {
    _playSound('incorrect.mp3');
  }
}

final soundServiceProvider = Provider((ref) => SoundService(ref));