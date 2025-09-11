import 'dart:async'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/custom_quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_result_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/diagram_widget.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/question_widget.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/quiz_status_bar.dart';

class QuizInProgressScreen extends ConsumerStatefulWidget {
  const QuizInProgressScreen({super.key});

  @override
  ConsumerState<QuizInProgressScreen> createState() => _QuizInProgressScreenState();
}

class _QuizInProgressScreenState extends ConsumerState<QuizInProgressScreen> with WidgetsBindingObserver{
  int _currentQuestionIndex = 0;
  final List<Question> _incorrectAnswers = [];

  Timer? _timer;
  int _timeLeftInSeconds = 0;
  bool _isTimerInitialized = false;
  int _totalTime = 0;

  @override
  void initState() {
    super.initState();
    // Start listening to app lifecycle events (pause, resume)
    WidgetsBinding.instance.addObserver(this);
  }

  void _startOrResumeTimer() {
    _timer?.cancel(); // Stop any existing timer

    // If the timer hasn't been started yet, initialize it from the config.
    if (!_isTimerInitialized) {
       _totalTime = ref.read(customQuizConfigProvider).timeInMinutes * 60;
      _timeLeftInSeconds = _totalTime;
      _isTimerInitialized = true;
    }

    // Start a new periodic timer that uses the current _timeLeftInSeconds
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeftInSeconds > 0) {
        if (mounted) {
          setState(() {
            _timeLeftInSeconds--;
          });
        }
      } else {
        _endQuiz(isTimeUp: true);
      }
    });
  }

  void _endQuiz({bool isTimeUp = false}) {
    _timer?.cancel();
    final questions = ref.read(customQuizQuestionsProvider).asData?.value ?? [];
    List<Question> finalIncorrectAnswers = List.from(_incorrectAnswers);

    if (isTimeUp) {
        final unansweredQuestions = questions.sublist(_currentQuestionIndex);
        finalIncorrectAnswers.addAll(unansweredQuestions);
    }

    // Set the results for the score calculation
    ref.read(quizResultProvider.notifier).setResults(
      allQuestions: questions,
      // Pass the full list of incorrect + unanswered for an accurate score
      incorrectAnswers: finalIncorrectAnswers,
      // Crucially, pass ONLY the questions the user actively got wrong for the review
      reviewableIncorrectAnswers: _incorrectAnswers,
      endReason: isTimeUp ? QuizEndReason.timeUp : QuizEndReason.completed,

    );

    if (mounted) context.pushReplacement('/quiz/end');
  }
  void _showExitConfirmationDialog() {
    _timer?.cancel(); // Pause the timer when the dialog is open
    showDialog(
      context: context,
      barrierDismissible: false, // User must choose an option
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('هل أنت متأكد؟'),
          content: const Text('سيتم إلغاء هذا الاختبار ولن يتم حفظ تقدمك.'),
          actions: <Widget>[
            TextButton(
              child: const Text('البقاء في الاختبار'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                _startOrResumeTimer(); // Resume the timer
              },
            ),
            TextButton(
              child: const Text('الخروج'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); // Close the dialog
                context.pop(); // Go back to the difficulty screen
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // ## NEW: Handle app pausing and resuming ##
    switch (state) {
      case AppLifecycleState.resumed:
        // Restart the timer when the app is resumed
        _startOrResumeTimer();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Pause the timer when the app is in the background
        _timer?.cancel();
        break;
    }
  }

  @override
  void dispose() {
    // Clean up the timer and the lifecycle observer
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  void _onQuestionAnswered(bool isCorrect, Question question) {
    if (!isCorrect) {
      _incorrectAnswers.add(question);
    }

    final questions = ref.read(customQuizQuestionsProvider).asData!.value;
    if (_currentQuestionIndex >= questions.length - 1) {
      // If it's the last question, end the quiz
      _endQuiz();
    } else {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(customQuizQuestionsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmationDialog();
        }
      },
      child: Scaffold(
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
            if (_timer == null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                 _startOrResumeTimer();
              });
            }
            if (questions.isEmpty) {
              return const Center(child: Text('لا توجد أسئلة متاحة للمحتوى الذي اخترته.'));
            }
      
            final currentQuestion = questions[_currentQuestionIndex];
            final diagramAsync = ref.watch(diagramWithLabelsProvider(currentQuestion.diagramId));
      
            return SafeArea(
              child: Column(
                children: [
                  QuizStatusBar(
                    totalSeconds: _totalTime,
                    remainingSeconds: _timeLeftInSeconds,
                  ),
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
                      key: ValueKey('${currentQuestion.correctLabel.id}_${currentQuestion.questionType.toString()}_$_currentQuestionIndex'),
                      question: currentQuestion,
                      mode: QuestionMode.test,
                      onAnswered: (isCorrect) {
                        _onQuestionAnswered(isCorrect, currentQuestion);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}