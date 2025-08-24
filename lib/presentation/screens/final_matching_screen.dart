import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/question_widget.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart'; // For diagramWithLabelsProvider
import 'package:anatomy_quiz_app/presentation/widgets/quiz/diagram_widget.dart';

// This provider generates the single, comprehensive matching question.
final finalMatchingQuestionProvider = FutureProvider.autoDispose
    .family<Question, ({int levelId, int stepNumber})>((ref, ids) async {
  final db = ref.watch(databaseHelperProvider);
  final allLabelsForLevel = await db.getLabelsForDiagram(ids.levelId);
  
  final learnedLabels = allLabelsForLevel
      .where((label) => label.labelNumber <= ids.stepNumber)
      .toList();

  return Question(
    questionType: QuestionType.matching,
    diagramId: ids.levelId,
    correctLabel: learnedLabels.first,
    questionText: 'للإتقان، قم بمطابقة جميع الأجزاء التي درستها.',
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
    final asyncQuestion = ref.watch(finalMatchingQuestionProvider((levelId: levelId, stepNumber: stepNumber)));
    final asyncDiagram = ref.watch(diagramWithLabelsProvider(levelId)); // Provider for the diagram

    return Scaffold(
      appBar: AppBar(
        title: const Text('التحدي النهائي'),
        automaticallyImplyLeading: false,
      ),
      // ## NEW LAYOUT: Column with two Expanded widgets ##
      body: Column(
        children: [
          // Top 1/3 of the screen for the diagram
          Expanded(
            flex: 1,
            child: asyncDiagram.when(
              data: (diagram) => DiagramWidget(imageAssetPath: diagram.imageAssetPath),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(child: Text('لا يمكن تحميل الرسم')),
            ),
          ),
          // Bottom 2/3 of the screen for the question
          Expanded(
            flex: 2,
            child: asyncQuestion.when(
              data: (question) => QuestionWidget(
                question: question,
                onAnswered: (isCorrect) async {
                  if (isCorrect) {
                    await ref.read(userProgressProvider.notifier).completeStep(levelId, stepNumber);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('أحسنت! تم إتقان الخطوة.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      context.pop();//('/level/$levelId');
                    }
                  }
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}