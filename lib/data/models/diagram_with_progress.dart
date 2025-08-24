import 'package:anatomy_quiz_app/data/models/models.dart';

// This class is a simple container to bundle a diagram with its progress stats.
class DiagramWithProgress {
  final AnatomicalDiagram diagram;
  final LevelStat? progress; // Progress can be null if the user hasn't started it

  DiagramWithProgress({
    required this.diagram,
    this.progress,
  });
}