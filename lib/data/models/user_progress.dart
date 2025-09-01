import 'package:anatomy_quiz_app/data/models/level_stat.dart';
enum Gender { male, female }

class UserProgress {
  final String? userName;
  final String? gender;
  final Map<int, LevelStat> levelStats;
  final int lastActiveLevelId;
  final String? lastActiveLevelTitle;

  const UserProgress.initial()
      : userName = null,
        gender = null,
        levelStats = const {},
        lastActiveLevelId = 1,
        lastActiveLevelTitle = null; 

  UserProgress({
    this.userName,
    this.gender,
    required this.levelStats,
    this.lastActiveLevelId = 1,
    this.lastActiveLevelTitle,
  });

  UserProgress copyWith({
    String? userName,
    String? gender,
    Map<int, LevelStat>? levelStats,
    int? lastActiveLevelId,
    String? lastActiveLevelTitle,
  }) {
    return UserProgress(
      userName: userName ?? this.userName,
      gender: gender ?? this.gender,
      levelStats: levelStats ?? this.levelStats,
      lastActiveLevelId: lastActiveLevelId ?? this.lastActiveLevelId,
      lastActiveLevelTitle: lastActiveLevelTitle ?? this.lastActiveLevelTitle,
    );
  }
}