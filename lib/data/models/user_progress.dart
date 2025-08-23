import 'package:anatomy_quiz_app/data/models/level_stat.dart';
enum Gender { male, female }


class UserProgress {
  final String? userName;
  final String? gender;
  final int currentLevelId;
  final int currentStepInLevel;
  final Map<int, LevelStat> levelStats;

  // Initial state when the app is first launched
  const UserProgress.initial()
      : userName = null,
        gender = "",
        currentLevelId = 1,
        currentStepInLevel = 1,
        levelStats = const {};
  
  UserProgress({
    this.userName,
    this.gender,
    required this.currentLevelId,
    required this.currentStepInLevel,
    required this.levelStats,
  });

  UserProgress copyWith({
    String? userName,
    String? gender,
    int? currentLevelId,
    int? currentStepInLevel,
    Map<int, LevelStat>? levelStats,
  }) {
    return UserProgress(
      userName: userName ?? this.userName,
      gender: gender ?? this.gender,
      currentLevelId: currentLevelId ?? this.currentLevelId,
      currentStepInLevel: currentStepInLevel ?? this.currentStepInLevel,
      levelStats: levelStats ?? this.levelStats,
    );
  }
}