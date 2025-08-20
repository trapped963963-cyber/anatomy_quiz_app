import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/diagram_widget.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/question_widget.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

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
    // Use a post-frame callback to safely interact with the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizProvider.notifier).generateQuizForStep(widget.levelId, widget.stepNumber);
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

    ref.listen<QuizState>(quizProvider, (previous, next) {
      if (next.isFinished) {
        // Navigate to the end screen with results
        final totalQuestions = next.questions.length;
        final totalWrong = next.wronglyAnswered.length;
        final totalCorrect = totalQuestions - totalWrong;

        // Use context.pushReplacement to prevent going back to the quiz
        context.pushReplacement(
          '/step-end',
          extra: {
            'levelId': widget.levelId,
            'stepNumber': widget.stepNumber,
            'totalCorrect': totalCorrect,
            'totalWrong': totalWrong,
            'wronglyAnswered': next.wronglyAnswered,
          },
        );
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Center(child: Text('لا يمكن تحميل الرسم')),
              ),
            ),
            Expanded(
              flex: 1,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: QuestionWidget(
                  key: ValueKey(currentQuestion.correctLabel.id), // Important to force widget rebuild
                  question: currentQuestion,
                  onAnswered: (isCorrect) {
                    quizNotifier.answerQuestion(isCorrect);
                  },
                ),
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
                context.pop();
              },
            ),
          ],
        );
      },
    );
  }
}