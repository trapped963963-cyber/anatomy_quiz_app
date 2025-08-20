class LevelStat {
  final int levelId;
  final int completedSteps;
  final bool isCompleted;
  final DateTime lastVisited;

  LevelStat({
    required this.levelId,
    this.completedSteps = 0,
    this.isCompleted = false,
    required this.lastVisited,
  });

  factory LevelStat.fromMap(Map<String, dynamic> map) {
    return LevelStat(
      levelId: map['level_id'],
      completedSteps: map['completed_steps'] ?? 0,
      isCompleted: (map['is_completed'] ?? 0) == 1,
      lastVisited: DateTime.parse(map['last_visited']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level_id': levelId,
      'completed_steps': completedSteps,
      'is_completed': isCompleted ? 1 : 0,
      'last_visited': lastVisited.toIso8601String(),
    };
  }
}