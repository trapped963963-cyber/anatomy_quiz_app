import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/mcq_question_view.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/word_game_view.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/matching_question_view.dart';
import 'package:anatomy_quiz_app/core/utils/ui_helpers.dart';

class QuestionWidget extends ConsumerWidget {
  final Question question;
  final QuestionMode mode;
  final Function(bool isCorrect) onAnswered;

  const QuestionWidget({
    super.key,
    required this.question,
    required this.onAnswered,
    this.mode = QuestionMode.learn,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: _buildQuestionBody(context, ref),
      ),
    );
  }

  Widget _buildQuestionBody(BuildContext context, WidgetRef ref) {
    switch (question.questionType) {
      case QuestionType.askForTitle:
      case QuestionType.askForNumber:
      case QuestionType.askFromDef:
        return McqQuestionView(
          question: question,
          mode: mode,
          onAnswered: (isCorrect) => onAnswered(isCorrect),
          showFeedbackBottomSheet: (isCorrect) =>
              showFeedbackBottomSheet(context: context, ref: ref, isCorrect: isCorrect, question: question),
          buildQuestionContainer: (text) =>
              buildQuestionContainer(context: context, text: text),
        );

      case QuestionType.askToWriteTitle:
        return WordGameView(
          question: question,
          mode: mode,
          onAnswered: (isCorrect) => onAnswered(isCorrect),
          showFeedbackBottomSheet: (isCorrect) =>
              showFeedbackBottomSheet(context: context, ref: ref, isCorrect: isCorrect, question: question),
          buildQuestionContainer: (text) =>
              buildQuestionContainer(context: context, text: text),
        );

      case QuestionType.matching:
        return MatchingQuestionView(
          question: question,
          onAnswered: onAnswered,
        );

      default:
        return const Center(child: Text('Unsupported Question Type'));
    }
  }
}