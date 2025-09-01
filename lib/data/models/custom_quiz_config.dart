// This enum defines our five difficulty levels.
enum QuizDifficulty {
  veryEasy,
  easy,
  medium,
  difficult,
  veryDifficult,
}

// This class is a simple container for all the user's choices.
class CustomQuizConfig {
  final Set<int> selectedDiagramIds;
  final QuizDifficulty difficulty;

  // We can add getters to easily access the quiz parameters.
  int get questionCount {
    switch (difficulty) {
      case QuizDifficulty.veryEasy: return 10;
      case QuizDifficulty.easy: return 20;
      case QuizDifficulty.medium: return 30;
      case QuizDifficulty.difficult: return 40;
      case QuizDifficulty.veryDifficult: return 60;
    }
  }

  int get timeInMinutes {
     switch (difficulty) {
      case QuizDifficulty.veryEasy: return 1;
      case QuizDifficulty.easy: return 10;
      case QuizDifficulty.medium: return 15;
      case QuizDifficulty.difficult: return 20;
      case QuizDifficulty.veryDifficult: return 30;
    }
  }

  const CustomQuizConfig({
    this.selectedDiagramIds = const {},
    this.difficulty = QuizDifficulty.medium,
  });

  CustomQuizConfig copyWith({
    Set<int>? selectedDiagramIds,
    QuizDifficulty? difficulty,
  }) {
    return CustomQuizConfig(
      selectedDiagramIds: selectedDiagramIds ?? this.selectedDiagramIds,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}