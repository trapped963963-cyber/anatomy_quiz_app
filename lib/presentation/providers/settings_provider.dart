import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsNotifier extends StateNotifier<Map<String, bool>> {
  SettingsNotifier() : super({'sound': true, 'haptics': true}) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    state = {
      'sound': prefs.getBool('sound') ?? true,
      'haptics': prefs.getBool('haptics') ?? true,
    };
  }

  Future<void> toggleSound() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state['sound']!;
    await prefs.setBool('sound', newValue);
    state = {...state, 'sound': newValue};
  }

  Future<void> toggleHaptics() async {
    final prefs = await SharedPreferences.getInstance();
    final newValue = !state['haptics']!;
    await prefs.setBool('haptics', newValue);
    state = {...state, 'haptics': newValue};
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, Map<String, bool>>((ref) {
  return SettingsNotifier();
});