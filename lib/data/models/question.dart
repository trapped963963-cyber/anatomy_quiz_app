import 'package:anatomy_quiz_app/data/models/label.dart';

enum QuestionMode { learn, test }

enum QuestionType {
  askForTitle,
  askForNumber,
  askFromDef,
  askToWriteTitle,
  matching,
}

class Question {
  final QuestionType questionType;
  final int diagramId;
  final Label correctLabel;
  final String questionText;
  final List<Label> choices;
  final int? randomIndex;

  Question({
    required this.questionType,
    required this.diagramId,
    required this.correctLabel,
    required this.questionText,
    required this.choices,
    this.randomIndex,
  });

  Question copyWith({
  int? randomIndex,
  }) {
  return Question(
    questionType: this.questionType,
    diagramId: this.diagramId,
    correctLabel: this.correctLabel,
    questionText: this.questionText,
    choices: this.choices,
    randomIndex: randomIndex ?? this.randomIndex,
  );
}
}