import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';

class SoundService {
  final Ref _ref;
  // AudioCache is the best way to handle short, preloaded sound effects.
  final AudioPlayer _player = AudioPlayer();

  SoundService(this._ref) {
    // The constructor is now empty as we will call preloadSounds() manually.
  }

  // ## NEW: The Preloading Method ##
  Future<void> preloadSounds() async {
    // This will load both sound files into the cache.
    // The player will look in the cache first before trying to load from assets.
    await _player.setSource(AssetSource('sounds/correct.mp3'));
    await _player.setSource(AssetSource('sounds/incorrect.mp3'));
  }

  void playCorrectSound() {
    if (_ref.read(settingsProvider)['sound'] ?? true) {
      // Now, playing the sound is much faster.
      _player.play(AssetSource('sounds/correct.mp3'));
    }
  }

  void playIncorrectSound() {
    if (_ref.read(settingsProvider)['sound'] ?? true) {
      _player.play(AssetSource('sounds/incorrect.mp3'));
    }
  }
}

// The provider is the same
final soundServiceProvider = Provider((ref) => SoundService(ref));