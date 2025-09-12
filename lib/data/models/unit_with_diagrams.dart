import 'package:anatomy_quiz_app/data/models/models.dart';

class UnitWithDiagrams {
  final Unit unit;
  final List<DiagramWithProgress> diagrams;

  UnitWithDiagrams({
    required this.unit,
    this.diagrams = const [],
  });
}