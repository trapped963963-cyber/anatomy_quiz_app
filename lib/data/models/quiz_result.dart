import 'package:anatomy_quiz_app/data/models/models.dart';

class QuizResult {
  final List<Question> correctAnswers;
  final List<Question> incorrectAnswers;
  final int totalQuestions;

  const QuizResult({
    this.correctAnswers = const [],
    this.incorrectAnswers = const [],
    this.totalQuestions = 0,
  });
}