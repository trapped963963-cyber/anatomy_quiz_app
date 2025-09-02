import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';

// Provider 1: Fetches the list of all Units from the database.
final unitsProvider = FutureProvider<List<Unit>>((ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return dbHelper.getUnits();
});

// Provider 2: Fetches the list of Diagrams for a specific unitId.
// We use .family to pass in the unitId.
final diagramsForUnitProvider = FutureProvider.family<List<AnatomicalDiagram>, int>((ref, unitId) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  return dbHelper.getDiagramsForUnit(unitId);
});

final diagramsWithProgressProvider = FutureProvider.family<List<DiagramWithProgress>, int>((ref, unitId) async {
  // 1. We now 'await' the result of the database call.
  final diagrams = await ref.watch(diagramsForUnitProvider(unitId).future);

  // 2. We can then read the synchronous progress data.
  final userProgress = ref.watch(userProgressProvider);

  // 3. We map and combine them, same as before.
  return diagrams.map((diagram) {
    final progress = userProgress.levelStats[diagram.id];
    return DiagramWithProgress(diagram: diagram, progress: progress);
  }).toList();
});