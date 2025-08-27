import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/diagram_widget.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/question_widget.dart';



class ReviewQueueState {
  final List<Question> questions;
  final bool isInitialized;

  ReviewQueueState({this.questions = const [], this.isInitialized = false});

  ReviewQueueState copyWith({List<Question>? questions, bool? isInitialized}) {
    return ReviewQueueState(
      questions: questions ?? this.questions,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}
final reviewQueueProvider = StateNotifierProvider.autoDispose<ReviewQueueNotifier, ReviewQueueState>((ref) {
  return ReviewQueueNotifier();
});

class ReviewQueueNotifier extends StateNotifier<ReviewQueueState> {
  ReviewQueueNotifier() : super(ReviewQueueState());

  void startReview(List<Question> questions) {
    state = state.copyWith(
      questions: List.from(questions)..shuffle(),
      isInitialized: true,
    );
  }

  void answer(bool isCorrect) {
    final currentQuestion = state.questions.first;
    List<Question> newQueue = List.from(state.questions);
    newQueue.removeAt(0);

    if (!isCorrect) {
      newQueue.add(currentQuestion);
    }
    state = state.copyWith(questions: newQueue);
  }
}

class ReviewStepScreen extends ConsumerStatefulWidget {
  final List<Question> questionsToReview;
  final VoidCallback onReviewCompleted;
  final VoidCallback onExit;


  const ReviewStepScreen({super.key, 
    required this.questionsToReview,
    required this.onReviewCompleted,
    required this.onExit,
  });
   @override
  ConsumerState<ReviewStepScreen> createState() => _ReviewStepScreenState();
}

class _ReviewStepScreenState extends ConsumerState<ReviewStepScreen> {

  @override
  void initState() {
    super.initState();
    // Initialize the queue only once when the widget is first built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(reviewQueueProvider).isInitialized) {
        ref.read(reviewQueueProvider.notifier).startReview(widget.questionsToReview);
      }
    });
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('هل أنت متأكد؟'),
          content: const Text('لم تكمل المراجعة بعد. إذا خرجت الآن، فسيتم فقدان تقدمك.'),
          actions: <Widget>[
            TextButton(
              child: const Text('البقاء'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('الخروج'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onExit(); 
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final reviewState = ref.watch(reviewQueueProvider);
    final reviewQueue = reviewState.questions;

    if (reviewState.isInitialized && reviewQueue.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          widget.onReviewCompleted();
        }
      });
      return const Scaffold(body: Center(child: Text("المراجعة انتهت!")));
    }

    if (!reviewState.isInitialized || reviewQueue.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reviewNotifier = ref.read(reviewQueueProvider.notifier);
    final currentQuestion = reviewQueue.first;
    final diagramAsync = ref.watch(diagramWithLabelsProvider(currentQuestion.diagramId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmationDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text('مراجعة (${reviewQueue.length} متبقي)')),
        body: Column(
          children: [
            Expanded(
              flex: 1,
              child: diagramAsync.when(
                data: (diagram) => DiagramWidget(imageAssetPath: diagram.imageAssetPath),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => Center(child: Text('Error: $e')),
              ),
            ),
            Expanded(
              flex: 2,
              child: QuestionWidget(
                key: UniqueKey(),
                question: currentQuestion,
                mode: QuestionMode.learn,
                onAnswered: (isCorrect) => reviewNotifier.answer(isCorrect),
              ),
            ),
          ],
        ),
      ),
    );
  }
}