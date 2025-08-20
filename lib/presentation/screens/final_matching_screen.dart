import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/question_widget.dart';

// A provider to generate the single, comprehensive matching question.
final finalMatchingQuestionProvider = FutureProvider.autoDispose
    .family<Question, ({int levelId, int stepNumber})>((ref, ids) async {
  final db = ref.watch(databaseHelperProvider);
  final allLabelsForLevel = await db.getLabelsForDiagram(ids.levelId);
  
  // Get all labels up to and including the current step.
  final learnedLabels = allLabelsForLevel
      .where((label) => label.labelNumber <= ids.stepNumber)
      .toList();

  return Question(
    questionType: QuestionType.matching,
    diagramId: ids.levelId,
    correctLabel: learnedLabels.first, // Placeholder, not used in matching
    questionText: 'للإتقان، قم بمطابقة جميع الأجزاء التي درستها في هذا المستوى.',
    choices: learnedLabels,
  );
});

class FinalMatchingScreen extends ConsumerWidget {
  final int levelId;
  final int stepNumber;

  const FinalMatchingScreen({
    super.key,
    required this.levelId,
    required this.stepNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncQuestion =
        ref.watch(finalMatchingQuestionProvider((levelId: levelId, stepNumber: stepNumber)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحدي النهائي'),
        automaticallyImplyLeading: false, // Prevents user from going back
      ),
      body: asyncQuestion.when(
        data: (question) => QuestionWidget(
          question: question,
          onAnswered: (isCorrect) async {
            if (isCorrect) {
              // This is now the ONLY place where completeStep is called.
              await ref
                  .read(userProgressProvider.notifier)
                  .completeStep(levelId, stepNumber);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('أحسنت! تم إتقان الخطوة.'),
                  backgroundColor: Colors.green,
                ),
              );
              // Navigate back to the level screen to see the progress.
              context.go('/level/$levelId');
            }
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}