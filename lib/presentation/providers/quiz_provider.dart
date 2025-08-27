import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';

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
    reinforcementQuestions.addAll(initialQuestions);
    reinforcementQuestions.shuffle();
    List<Question> finalQuestions = [...initialQuestions, ...reinforcementQuestions];
    
    // Question Cap Logic
    if (finalQuestions.length > 50) {
      finalQuestions = [...initialQuestions, ...reinforcementQuestions.sublist(0, 46)];
    }

    final matchingQuestion = Question(
      questionType: QuestionType.matching,
      diagramId: levelId,
      correctLabel: allLearnedLabels.first, // Placeholder
      questionText: 'للإتقان، قم بمطابقة جميع الأجزاء التي درستها حتى الآن.',
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
        questionText = 'ما هو اسم الجزء رقم ${correctLabel.labelNumber}؟';
        break;
      case QuestionType.askForNumber:
        questionText = 'ما هو رقم الجزء "${correctLabel.title}"؟';
        break;
      case QuestionType.askFromDef:
        questionText = 'أي رقم يشير إلى الجزء الذي تعريفه: "${correctLabel.definition}"؟';
        break;
      default:
        break;
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
    return [
      _createMcq(newLabel, allLearnedLabels, QuestionType.askForTitle, diagramId),
      _createMcq(newLabel, allLearnedLabels, QuestionType.askForNumber, diagramId),
      _createMcq(newLabel, allLearnedLabels, QuestionType.askFromDef, diagramId),
      Question( // askToWriteTitle
        questionType: QuestionType.askToWriteTitle,
        diagramId: diagramId,
        correctLabel: newLabel,
        questionText: 'اكتب اسم الجزء رقم ${newLabel.labelNumber}',
        choices: [],
      ),
    ];
  }

  List<Question> _generateReinforcementQuestions(List<Label> previousLabels, int diagramId, List<Label> allLearnedLabels) {
    if (previousLabels.isEmpty) return [];
    
    List<Question> questions = [];
      // Define the pool of all possible question types.
    final allQuestionTypes = [
      QuestionType.askForTitle,
      QuestionType.askForNumber,
      QuestionType.askFromDef,
      QuestionType.askToWriteTitle,
    ];
    
    // Loop through each previously learned label.
    for (var label in previousLabels) {
      // Shuffle the list of types and pick the first two.
      // This guarantees we get two different types for each label.
      final chosenTypes = (List.from(allQuestionTypes)..shuffle()).sublist(0, 2);

      // Now, create one question for each of the two chosen types.
      for (var type in chosenTypes) {
        if (type == QuestionType.askToWriteTitle) {
          questions.add(Question(
            questionType: type,
            diagramId: diagramId,
            correctLabel: label,
            questionText: 'اكتب اسم الجزء رقم ${label.labelNumber}',
            choices: [],
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

// A new provider to fetch a single diagram with its labels
final diagramWithLabelsProvider = FutureProvider.autoDispose.family<AnatomicalDiagram, int>((ref, levelId) async {
  final db = ref.watch(databaseHelperProvider);
  final diagramData = (await db.getDiagrams()).firstWhere((d) => d.id == levelId);
  final labels = await db.getLabelsForDiagram(levelId);
  return diagramData.copyWith(labels: labels);
});