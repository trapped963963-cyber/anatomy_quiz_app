import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';

// This is the controller that will manage the state of our quiz results.
class QuizResultNotifier extends StateNotifier<QuizResult> {
  QuizResultNotifier() : super(const QuizResult());

  void setResults({
    required List<Question> allQuestions,
    required List<Question> incorrectAnswers,
  }) {
    // ## THE FIX: We now compare the question objects directly. ##

    // 1. Create a Set of the incorrect question objects for efficient lookup.
    final Set<Question> incorrectSet = incorrectAnswers.toSet();

    // 2. A question is correct if it's not found in the 'incorrectSet'.
    final List<Question> correctAnswers = allQuestions
        .where((q) => !incorrectSet.contains(q))
        .toList();

    state = QuizResult(
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      totalQuestions: allQuestions.length,
    );
  }
}

// This is the provider that our UI will interact with.
final quizResultProvider =
    StateNotifierProvider<QuizResultNotifier, QuizResult>((ref) {
  return QuizResultNotifier();
});