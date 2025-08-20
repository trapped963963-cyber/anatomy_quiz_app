enum QuizType { general, levelSpecific }
enum QuestionScope { completedLevels, allLevels }

class QuizConfig {
  final QuizType quizType;
  final int difficulty; // e.g., number of questions
  final QuestionScope questionScope;
  final int? levelId; // Only for levelSpecific quizzes

  QuizConfig({
    required this.quizType,
    required this.difficulty,
    required this.questionScope,
    this.levelId,
  });
}