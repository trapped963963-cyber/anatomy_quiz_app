import 'package:flutter_riverpod/flutter_riverpod.dart';

// This simple provider will just hold the ID of the level that was just completed.
final completedLevelCelebrationProvider = StateProvider<int?>((ref) => null);