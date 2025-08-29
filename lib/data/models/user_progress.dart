import 'package:anatomy_quiz_app/data/models/level_stat.dart';
enum Gender { male, female }

class UserProgress {
  final String? userName;
  final String? gender;
  final Map<int, LevelStat> levelStats;

  const UserProgress.initial()
      : userName = null,
        gender = null,
        levelStats = const {};

  UserProgress({
    this.userName,
    this.gender,
    required this.levelStats,
  });

  UserProgress copyWith({
    String? userName,
    String? gender,
    Map<int, LevelStat>? levelStats,
  }) {
    return UserProgress(
      userName: userName ?? this.userName,
      gender: gender ?? this.gender,
      levelStats: levelStats ?? this.levelStats,
    );
  }
}