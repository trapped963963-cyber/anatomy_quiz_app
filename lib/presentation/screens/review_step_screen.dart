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

class ReviewStepScreen extends ConsumerWidget {
  final List<Question> questionsToReview;
  final int levelId;
  final int stepNumber;
  
  const ReviewStepScreen({super.key, 
  required this.questionsToReview,
  required this.levelId,
  required this.stepNumber  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize the queue only once
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(reviewQueueProvider).isInitialized) {
        ref.read(reviewQueueProvider.notifier).startReview(questionsToReview);
      }
    });

    final reviewState = ref.watch(reviewQueueProvider);
    final reviewQueue = reviewState.questions;

    // This new logic is safe and correct.
    if (reviewState.isInitialized && reviewQueue.isEmpty) {
      
       WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
            context.go('/final-matching/$levelId/$stepNumber');
          }
        });


      return const Scaffold(body: Center(child: Text("المراجعة انتهت!")));
    }

    // This prevents the crash.
    if (!reviewState.isInitialized || reviewQueue.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final reviewNotifier = ref.read(reviewQueueProvider.notifier);
    final currentQuestion = reviewQueue.first;
    final diagramAsync = ref.watch(diagramWithLabelsProvider(currentQuestion.diagramId));

    return Scaffold(
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
              onAnswered: (isCorrect) => reviewNotifier.answer(isCorrect),
            ),
          ),
        ],
      ),
    );
  }
}





