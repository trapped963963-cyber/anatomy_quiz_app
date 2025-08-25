import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/presentation/providers/custom_quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/diagram_widget.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/question_widget.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';

class QuizInProgressScreen extends ConsumerStatefulWidget {
  const QuizInProgressScreen({super.key});

  @override
  ConsumerState<QuizInProgressScreen> createState() => _QuizInProgressScreenState();
}

class _QuizInProgressScreenState extends ConsumerState<QuizInProgressScreen> {
  int _currentQuestionIndex = 0;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(customQuizQuestionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('اختبار مخصص')),
      body: questionsAsync.when(
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('...يتم إعداد الاختبار الخاص بك'),
            ],
          ),
        ),
        error: (e, st) => Center(child: Text('Error building quiz: $e')),
        data: (questions) {
          if (questions.isEmpty) {
            return const Center(child: Text('لا توجد أسئلة متاحة للمحتوى الذي اخترته.'));
          }

          if (_currentQuestionIndex >= questions.length) {
            // Quiz is finished, we'll navigate to a results screen later.
            return const Center(child: Text('انتهى الاختبار!'));
          }

          final currentQuestion = questions[_currentQuestionIndex];
          final diagramAsync = ref.watch(diagramWithLabelsProvider(currentQuestion.diagramId));

          return Column(
            children: [
              Expanded(
                flex: 1,
                child: diagramAsync.when(
                  data: (diagram) => DiagramWidget(imageAssetPath: diagram.imageAssetPath),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => const Center(child: Text('لا يمكن تحميل الرسم')),
                ),
              ),
              Expanded(
                flex: 2,
                child: QuestionWidget(
                  key: ValueKey('${currentQuestion.correctLabel.id}_${currentQuestion.questionType.toString()}_$_currentQuestionIndex'),
                  question: currentQuestion,
                  onAnswered: (isCorrect) {
                    // For now, just move to the next question.
                    setState(() {
                      _currentQuestionIndex++;
                    });
                  },
                  mode: QuestionMode.test,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}