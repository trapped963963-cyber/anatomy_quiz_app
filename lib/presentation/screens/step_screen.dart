import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/diagram_widget.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/question_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/question.dart';

import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';
class StepScreen extends ConsumerStatefulWidget {
  final int levelId;
  final int stepNumber;
  const StepScreen({super.key, required this.levelId, required this.stepNumber});

  @override
  ConsumerState<StepScreen> createState() => _StepScreenState();
}

class _StepScreenState extends ConsumerState<StepScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.stepNumber == -1) {
        ref.read(quizProvider.notifier).generateFinalChallengeQuiz(widget.levelId);
      } else {
        ref.read(quizProvider.notifier).generateQuizForStep(widget.levelId, widget.stepNumber);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);
    final quizNotifier = ref.read(quizProvider.notifier);
    final diagramAsync = ref.watch(diagramWithLabelsProvider(widget.levelId));

    // Inside your _StepScreenState's build method...

    ref.listen<QuizState>(quizProvider, (previous, next) {
      if (next.isFinished) {
        
        // De-duplicate the list of wrongly answered questions first.
        final seenKeys = <String>{};
        final uniqueWronglyAnswered = <Question>[];
        for (var question in next.wronglyAnswered) {
          final key = '${question.correctLabel.id}_${question.questionType.toString()}';
          if (seenKeys.add(key)) {
            uniqueWronglyAnswered.add(question);
          }
        }

        // ## THE FIX: Check which type of quiz just ended ##
        if (widget.stepNumber == -1) {
          // This was a Final Challenge. Navigate to the new ChallengeEndScreen.
          context.pushReplacement(
            '/challenge-end',
            extra: {
              'levelId': widget.levelId,
              'incorrectAnswers': uniqueWronglyAnswered,
              'totalQuestions': next.questions.length,
            },
          );
        } else {
          // This was a regular step. Navigate to the StepEndScreen as before.
          final totalQuestions = next.questions.length;
          final totalWrong = uniqueWronglyAnswered.length;
          // Note: The total correct should be based on the original wrong answers count for an accurate score.
          final totalCorrect = totalQuestions - next.wronglyAnswered.length; 

          context.pushReplacement(
            '/step-end',
            extra: {
              'levelId': widget.levelId,
              'stepNumber': widget.stepNumber,
              'totalCorrect': totalCorrect,
              'totalWrong': totalWrong,
              'wronglyAnswered': uniqueWronglyAnswered,
            },
          );
        }
      }
    });

    if (quizState.questions.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentQuestion = quizState.questions[quizState.currentQuestionIndex];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        // If the pop was prevented, show the confirmation dialog
        if (!didPop) {
          _showExitConfirmationDialog(context);
        }
      }, 
      child: Scaffold(
        appBar: AppBar(
          title: Text('الخطوة ${widget.stepNumber} - سؤال ${quizState.currentQuestionIndex + 1}/${quizState.questions.length}'),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(4.h),
            child: LinearProgressIndicator(
              value: (quizState.currentQuestionIndex + 1) / quizState.questions.length,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: diagramAsync.when(
                data: (diagram) => DiagramWidget(imageAssetPath: diagram.imageAssetPath),
                loading: () => const AppLoadingIndicator(),
                error: (e, s) => const Center(child: Text('لا يمكن تحميل الرسم')),
              ),
            ),
            Expanded(
              flex: 2,
              child: QuestionWidget(
                key: ValueKey(currentQuestion.correctLabel.id), // Important to force widget rebuild
                question: currentQuestion,
                onAnswered: (isCorrect) {
                  quizNotifier.answerQuestion(isCorrect);
                },
                mode: QuestionMode.learn, 
              ),
            ),
          ],
        ),
      ),
    );
  }


  // Add this helper method inside the _StepScreenState class
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('هل أنت متأكد؟'),
          content: const Text('سيتم فقدان تقدمك في هذا الاختبار إذا خرجت الآن.'),
          actions: <Widget>[
            TextButton(
              child: const Text('البقاء'),
              onPressed: () {
                // Just close the dialog
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('الخروج'),
              onPressed: () {
                // Close the dialog and then exit the screen
                // We use context.pop() here from go_router, which is aware of the navigation stack.
                Navigator.of(dialogContext).pop();
                context.go('/home');
                context.push('/units');
                context.push('/level/${widget.levelId}');
              },
            ),
          ],
        );
      },
    );
  }
}