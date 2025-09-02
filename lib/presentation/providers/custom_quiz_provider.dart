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

// This is the final, complete provider.

// This is the final, intelligent quiz generation engine.
final customQuizQuestionsProvider = FutureProvider.autoDispose<List<Question>>((ref) async {
  // 1. Get the user's config and the database helper.
  final config = ref.watch(customQuizConfigProvider);
  final dbHelper = ref.watch(databaseHelperProvider);
  
  if (config.selectedDiagramIds.isEmpty) return [];

  // 2. Pre-flight Check: Accurately calculate the max questions and adjust if needed.
  final counts = await dbHelper.getLabelCounts(config.selectedDiagramIds.toList());
  final totalLabels = counts['total'] ?? 0;
  final labelsWithDef = counts['withDef'] ?? 0;

  List<QuestionType> baseAllowedTypes = [
    QuestionType.askForTitle,
    QuestionType.askForNumber,
    QuestionType.askToWriteTitle
  ];
  
  final maxPossibleQuestions = (totalLabels * baseAllowedTypes.length) + labelsWithDef;
  final finalQuestionCount = min(config.questionCount, maxPossibleQuestions);

  if (finalQuestionCount == 0) return [];
  
  // 3. Fetch all labels and group them by diagram for smart choice generation.
  final allPossibleLabels = await dbHelper.getLabelsForDiagrams(config.selectedDiagramIds.toList());
  final Map<int, List<Label>> labelsByDiagram = {};
  for (var label in allPossibleLabels) {
    (labelsByDiagram[label.diagramId] ??= []).add(label);
  }
  
  // 4. GENERATION LOOP: Build the quiz while guaranteeing no repeats.
  final List<Question> questions = [];
  final Set<String> usedQuestionIds = {};
  
  final shuffledLabels = List<Label>.from(allPossibleLabels)..shuffle();
  int labelIndex = 0;

  while (questions.length < finalQuestionCount) {
    // Cycle through labels to ensure variety.
    final currentLabel = shuffledLabels[labelIndex % shuffledLabels.length];
    labelIndex++;

    // Build the list of valid question types for THIS specific label.
    List<QuestionType> possibleTypesForThisLabel = List.from(baseAllowedTypes);
    if (currentLabel.definition.trim().isNotEmpty) {
      possibleTypesForThisLabel.add(QuestionType.askFromDef);
    }
    
    final shuffledTypes = possibleTypesForThisLabel..shuffle();

    for (var type in shuffledTypes) {
      final questionId = '${currentLabel.diagramId}_${currentLabel.labelNumber}_$type';

      if (usedQuestionIds.add(questionId)) { // If the question is new...
        String questionText = '';
        List<Label> choices = [];
        
        // --- SMART CHOICE GENERATION LOGIC ---
        if (type == QuestionType.askForTitle) {
          questionText = 'ما هو اسم الجزء رقم ${currentLabel.labelNumber}؟';
          final Set<String> usedTitles = {currentLabel.title};
          choices = [currentLabel];
          final decoys = allPossibleLabels.where((l) => l.id != currentLabel.id).toList()..shuffle();
          for (var decoy in decoys) {
            if (choices.length >= 4) break;
            if (usedTitles.add(decoy.title)) {
              choices.add(decoy);
            }
          }
        } else if (type == QuestionType.askToWriteTitle) {
          questionText = 'اكتب اسم الجزء رقم ${currentLabel.labelNumber}';
        } else { // For 'askForNumber' and 'askFromDef'
          final diagramSpecificLabels = labelsByDiagram[currentLabel.diagramId]!;
          choices = (diagramSpecificLabels.where((l) => l.id != currentLabel.id).toList()..shuffle())
              .take(min(3, diagramSpecificLabels.length - 1)) 
              .toList();
          
          if (type == QuestionType.askForNumber) {
            questionText = 'ما هو رقم الجزء "${currentLabel.title}"؟';
          } else { // askFromDef
            questionText = 'أي رقم يشير إلى الجزء الذي تعريفه: "${currentLabel.definition}"؟';
          }
        }

        if (type != QuestionType.askToWriteTitle) {
          if (!choices.any((c) => c.id == currentLabel.id)) {
            choices.add(currentLabel);
          }
          choices.shuffle();
        }

        questions.add(Question(
          questionType: type,
          diagramId: currentLabel.diagramId,
          correctLabel: currentLabel,
          questionText: questionText,
          choices: choices,
          randomIndex: Random().nextInt(100),
        ));
        
        break; // Found a unique question, move to the next in the while loop.
      }
    }
  }

  return questions;
});

final maxQuestionsProvider = FutureProvider.autoDispose<int>((ref) async {
  final config = ref.watch(customQuizConfigProvider);
  final dbHelper = ref.watch(databaseHelperProvider);

  if (config.selectedDiagramIds.isEmpty) {
    return 0;
  }

  final counts = await dbHelper.getLabelCounts(config.selectedDiagramIds.toList());
  final totalLabels = counts['total'] ?? 0;
  final labelsWithDef = counts['withDef'] ?? 0;

  // Calculate the max questions. Each label has 3 base question types.
  // An additional question type is available only for labels with definitions.
  final maxQuestions = (totalLabels * 3) + labelsWithDef;

  return maxQuestions;
});