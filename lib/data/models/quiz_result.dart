import 'package:anatomy_quiz_app/data/models/models.dart';

enum QuizEndReason { completed, timeUp }

class QuizResult {
  final List<Question> correctAnswers;
  final List<Question> incorrectAnswers;
  final int totalQuestions;
  final List<Question> reviewableIncorrectAnswers;
  final QuizEndReason endReason;


  const QuizResult({
    this.correctAnswers = const [],
    this.incorrectAnswers = const [],
    this.totalQuestions = 0,
    this.reviewableIncorrectAnswers = const [],
    this.endReason = QuizEndReason.completed,
  }); 
}