import 'package:anatomy_quiz_app/data/models/label.dart';

// Enum to define our 5 question types
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

  Question({
    required this.questionType,
    required this.diagramId,
    required this.correctLabel,
    required this.questionText,
    required this.choices,
  });
}