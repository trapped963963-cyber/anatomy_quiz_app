import 'package:anatomy_quiz_app/data/models/level_stat.dart';

class UserProgress {
  final String? userName;
  final int currentLevelId;
  final int currentStepInLevel;
  final Map<int, LevelStat> levelStats;

  // Initial state when the app is first launched
  const UserProgress.initial()
      : userName = null,
        currentLevelId = 1,
        currentStepInLevel = 1,
        levelStats = const {};
  
  UserProgress({
    this.userName,
    required this.currentLevelId,
    required this.currentStepInLevel,
    required this.levelStats,
  });

  UserProgress copyWith({
    String? userName,
    int? currentLevelId,
    int? currentStepInLevel,
    Map<int, LevelStat>? levelStats,
  }) {
    return UserProgress(
      userName: userName ?? this.userName,
      currentLevelId: currentLevelId ?? this.currentLevelId,
      currentStepInLevel: currentStepInLevel ?? this.currentStepInLevel,
      levelStats: levelStats ?? this.levelStats,
    );
  }
}