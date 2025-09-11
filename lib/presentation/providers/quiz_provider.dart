import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'dart:math';
import 'package:anatomy_quiz_app/core/constants/app_strings.dart';

// This class will hold the state of a single quiz session
class QuizState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final List<Question> wronglyAnswered;
  final bool isFinished;

  QuizState({
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.wronglyAnswered = const [],
    this.isFinished = false,
  });

  QuizState copyWith({
    List<Question>? questions,
    int? currentQuestionIndex,
    List<Question>? wronglyAnswered,
    bool? isFinished,
  }) {
    return QuizState(
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      wronglyAnswered: wronglyAnswered ?? this.wronglyAnswered,
      isFinished: isFinished ?? this.isFinished,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  final Ref _ref;
  QuizNotifier(this._ref) : super(QuizState());

  void reset() {
    // Resets the quiz back to its initial, empty state.
    state = QuizState();
  }

  Future<void> generateFinalChallengeQuiz(int levelId) async {
    final dbHelper = _ref.read(databaseHelperProvider);
    final allLabelsForLevel = await dbHelper.getLabelsForDiagram(levelId);
    if (allLabelsForLevel.isEmpty) {
      state = QuizState(questions: []);
      return;
    }

    // 1. Create one question for each label in the diagram.
    List<Question> challengeQuestions = [];
    for (var label in allLabelsForLevel) {
      final types = [
        QuestionType.askForTitle,
        QuestionType.askForNumber,
        QuestionType.askFromDef,
        QuestionType.askToWriteTitle
      ];
      for(var type in types){
        if (type == QuestionType.askFromDef && label.definition.trim().isEmpty) {
          continue;
        }
        else if(type == QuestionType.askToWriteTitle){
             challengeQuestions.add(Question(
            questionType: type,
            diagramId: levelId,
            correctLabel: label,
            questionText:AppStrings.askToWriteTitle(label.labelNumber),
            choices: [],
            randomIndex: Random().nextInt(100),
          ));
        }
         else {
          challengeQuestions.add(_createMcq(label, allLabelsForLevel, type, levelId));
        }
      }
    }
    challengeQuestions.shuffle();

    // 2. Add the final, comprehensive matching question at the end.
    final matchingQuestion = Question(
      questionType: QuestionType.matching,
      diagramId: levelId,
      correctLabel: allLabelsForLevel.first,
      questionText: AppStrings.matchingChallenge(),
      choices: allLabelsForLevel,
    );
    challengeQuestions.add(matchingQuestion);

    state = QuizState(questions: challengeQuestions);
  }

  Future<void> generateQuizForStep(int levelId, int stepNumber) async {
    final dbHelper = _ref.read(databaseHelperProvider);
    final allLabelsForLevel = await dbHelper.getLabelsForDiagram(levelId);
    allLabelsForLevel.sort((a, b) => a.labelNumber.compareTo(b.labelNumber));
    
    if (stepNumber > allLabelsForLevel.length) return; // Should not happen

    final newLabel = allLabelsForLevel[stepNumber - 1];
    final previousLabels = allLabelsForLevel.sublist(0, stepNumber - 1);
    final allLearnedLabels = allLabelsForLevel.sublist(0, stepNumber);

    List<Question> initialQuestions = _generateInitialQuestions(newLabel, levelId, allLearnedLabels);
    List<Question> reinforcementQuestions = _generateReinforcementQuestions(previousLabels, levelId, allLearnedLabels);
    
    for (var question in initialQuestions) {
      if (question.questionType == QuestionType.askToWriteTitle || question.questionType == QuestionType.askFromDef) {
        continue;
      } else {
        reinforcementQuestions.add(question);
      }
    }

    reinforcementQuestions.shuffle();
    List<Question> finalQuestions = [...initialQuestions, ...reinforcementQuestions];
    

    // Question Cap Logic
    if (finalQuestions.length > 50) {
      finalQuestions = [...initialQuestions, ...reinforcementQuestions.sublist(0, 36)];
    }

    final matchingQuestion = Question(
      questionType: QuestionType.matching,
      diagramId: levelId,
      correctLabel: allLearnedLabels.first, // Placeholder
      questionText: AppStrings.matchingChallenge(),
      choices: allLearnedLabels,
    );
    finalQuestions.add(matchingQuestion);

    state = QuizState(questions: finalQuestions);
  }

  void answerQuestion(bool isCorrect) {
    if (!isCorrect) {
      final wrongQuestion = state.questions[state.currentQuestionIndex];
      state = state.copyWith(
        wronglyAnswered: [...state.wronglyAnswered, wrongQuestion],
      );
    }
    
    if (state.currentQuestionIndex < state.questions.length - 1) {
      state = state.copyWith(currentQuestionIndex: state.currentQuestionIndex + 1);
    } else {
      state = state.copyWith(isFinished: true);
    }
  }

  // --- Helper Methods for Question Generation ---

  Question _createMcq(Label correctLabel, List<Label> allChoices, QuestionType type, int diagramId) {
    String questionText = '';
    switch (type) {
      case QuestionType.askForTitle:
        questionText = AppStrings.askForTitle(correctLabel.labelNumber);
        break;
      case QuestionType.askForNumber:
        questionText = AppStrings.askForNumber(correctLabel.title);
        break;
      case QuestionType.askFromDef:
        questionText = AppStrings.askFromDef(correctLabel.definition);
        break;
      default:
        questionText = '';
    }    
    // Create a list of 3 wrong choices + the correct one
    List<Label> choices = (allChoices.where((l) => l.id != correctLabel.id).toList()..shuffle()).take(3).toList();
    choices.add(correctLabel);
    choices.shuffle();

    return Question(
      questionType: type,
      diagramId: diagramId,
      correctLabel: correctLabel,
      questionText: questionText,
      choices: choices,
    );
  }

 List<Question> _generateInitialQuestions(Label newLabel, int diagramId, List<Label> allLearnedLabels) {
  // Start with the three guaranteed question types.
  List<Question> questions = [
    _createMcq(newLabel, allLearnedLabels, QuestionType.askForTitle, diagramId),
    _createMcq(newLabel, allLearnedLabels, QuestionType.askForNumber, diagramId),
    Question(
      questionType: QuestionType.askToWriteTitle,
      diagramId: diagramId,
      correctLabel: newLabel,
      questionText: AppStrings.askToWriteTitle(newLabel.labelNumber),
      choices: [],
      randomIndex: Random().nextInt(100),
    ),
  ];

  // ## THE FIX ##
  // Only add the "ask from definition" question if the definition is not empty.
  if (newLabel.definition.trim().isNotEmpty) {
    questions.add(_createMcq(newLabel, allLearnedLabels, QuestionType.askFromDef, diagramId));
  }

  return questions;
}

  List<Question> _generateReinforcementQuestions(List<Label> previousLabels, int diagramId, List<Label> allLearnedLabels) {
    if (previousLabels.isEmpty) return [];

    List<Question> questions = [];

    for (var label in previousLabels) {
      final List<QuestionType> possibleTypes = [
        QuestionType.askForTitle,
        QuestionType.askForNumber,
        QuestionType.askToWriteTitle,
      ];

      // 2. Only add 'askFromDef' if the label has a valid definition.
      if (label.definition.trim().isNotEmpty) {
        possibleTypes.add(QuestionType.askFromDef);
      }

      // 3. Shuffle the valid types and pick two.
      final chosenTypes = (possibleTypes..shuffle()).sublist(0, 2);

      // The rest of the logic is the same.
      for (var type in chosenTypes) {
        if (type == QuestionType.askToWriteTitle) {
          questions.add(Question(
            questionType: type,
            diagramId: diagramId,
            correctLabel: label,
            questionText:AppStrings.askToWriteTitle(label.labelNumber),
            choices: [],
            randomIndex: Random().nextInt(100),
          ));
        } else {
          questions.add(_createMcq(label, allLearnedLabels, type, diagramId));
        }
      }
    }
    return questions;
  }
}

final quizProvider = StateNotifierProvider.autoDispose<QuizNotifier, QuizState>((ref) {
  return QuizNotifier(ref);
});

final diagramWithLabelsProvider = FutureProvider.autoDispose.family<AnatomicalDiagram, int>((ref, levelId) async {
  final db = ref.watch(databaseHelperProvider);

  // ## THE FIX: Call the new, more efficient method ##
  final diagramData = await db.getDiagramById(levelId);

  if (diagramData == null) {
    throw Exception('Diagram with ID $levelId not found.');
  }

  final labels = await db.getLabelsForDiagram(levelId);
  return diagramData.copyWith(labels: labels);
});