import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';

class CustomQuizConfigNotifier extends StateNotifier<CustomQuizConfig> {
  CustomQuizConfigNotifier() : super(const CustomQuizConfig());

  void setDiagrams(Set<int> diagramIds) {
    state = state.copyWith(selectedDiagramIds: diagramIds);
  }

  void setDifficulty(QuizDifficulty difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }

  void reset() {
    state = const CustomQuizConfig();
  }
}

final customQuizConfigProvider =
    StateNotifierProvider<CustomQuizConfigNotifier, CustomQuizConfig>((ref) {
  return CustomQuizConfigNotifier();
});
// At the top of custom_quiz_provider.dart

final customQuizQuestionsProvider = FutureProvider.autoDispose<List<Question>>((ref) async {
  // 1. Get the user's config and the database helper.
  final config = ref.watch(customQuizConfigProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  
  if (config.selectedDiagramIds.isEmpty) return [];

  // 2. Fetch all possible labels and group them by diagram for smart choice generation.
  final allPossibleLabels = await dbHelper.getLabelsForDiagrams(config.selectedDiagramIds.toList());
  if (allPossibleLabels.isEmpty) return [];

  final Map<int, List<Label>> labelsByDiagram = {};
  for (var label in allPossibleLabels) {
    (labelsByDiagram[label.diagramId] ??= []).add(label);
  }
  
  // 3. Determine the pool of allowed question types (excluding matching).
  List<QuestionType> allowedTypes = 
    [ QuestionType.askForTitle, 
      QuestionType.askForNumber, 
      QuestionType.askFromDef,
      QuestionType.askToWriteTitle];
      
  // 4. PRE-FLIGHT CHECK: Calculate the max possible questions and adjust if needed.
  final maxPossibleQuestions = allPossibleLabels.length * allowedTypes.length;
  final finalQuestionCount = min(config.questionCount, maxPossibleQuestions);

  // 5. GENERATION LOOP: Build the quiz while guaranteeing no repeats.
  final List<Question> questions = [];
  final Set<String> usedQuestionIds = {};
  
  // Shuffle the master list of labels once to ensure variety.
  final shuffledLabels = List<Label>.from(allPossibleLabels)..shuffle();
  int labelIndex = 0;

  while (questions.length < finalQuestionCount) {
    // Get the next label, cycling through the list if we run out.
    final currentLabel = shuffledLabels[labelIndex % shuffledLabels.length];
    labelIndex++;

    // Shuffle the allowed types to try them in a random order.
    final shuffledTypes = List<QuestionType>.from(allowedTypes)..shuffle();

    for (var type in shuffledTypes) {
      final questionId = '${currentLabel.diagramId}_${currentLabel.labelNumber}_$type';

      // If we haven't used this exact question yet...
      if (!usedQuestionIds.contains(questionId)) {
        usedQuestionIds.add(questionId); // Mark it as used.

        String questionText = '';
        List<Label> choices = [];
        
        // --- SMART CHOICE GENERATION LOGIC ---
        if (type == QuestionType.askForTitle) {
          // For 'askForTitle', decoys can come from ANY selected diagram.
          questionText = 'ما هو اسم الجزء رقم ${currentLabel.labelNumber}؟';
          choices = (allPossibleLabels.where((l) => l.id != currentLabel.id).toList()..shuffle()).take(3).toList();
        } else if (type == QuestionType.askToWriteTitle) {
          questionText = 'اكتب اسم الجزء رقم ${currentLabel.labelNumber}';
        } else { // For 'askForNumber' and 'askFromDef'
          // Decoys must come ONLY from the same diagram.
          final diagramSpecificLabels = labelsByDiagram[currentLabel.diagramId]!;
          choices = (diagramSpecificLabels.where((l) => l.id != currentLabel.id).toList()..shuffle())
              // Handle diagrams with less than 4 labels gracefully.
              .take(min(3, diagramSpecificLabels.length - 1)) 
              .toList();
          
          if (type == QuestionType.askForNumber) {
            questionText = 'ما هو رقم الجزء "${currentLabel.title}"؟';
          } else { // askFromDef
            questionText = 'أي رقم يشير إلى الجزء الذي تعريفه: "${currentLabel.definition}"؟';
          }
        }

        if (type != QuestionType.askToWriteTitle) {
          choices.add(currentLabel);
          choices.shuffle();
        }

        questions.add(Question(
          questionType: type,
          diagramId: currentLabel.diagramId,
          correctLabel: currentLabel,
          questionText: questionText,
          choices: choices,
        ));
        
        break; // Move to the next question in the main while loop.
      }
    }
  }

  return questions;
});

// This provider calculates the maximum number of unique questions possible
// based on the user's current diagram selection.
final maxQuestionsProvider = FutureProvider.autoDispose<int>((ref) async {
  final config = ref.watch(customQuizConfigProvider);
  final dbHelper = ref.watch(databaseHelperProvider);

  if (config.selectedDiagramIds.isEmpty) {
    return 0;
  }

  final allPossibleLabels = await dbHelper.getLabelsForDiagrams(config.selectedDiagramIds.toList());

  // For this calculation, we assume the hardest difficulty, which allows all 4 question types.
  // The number of unique questions is simply the number of labels times 4.
  return allPossibleLabels.length * 4;
});