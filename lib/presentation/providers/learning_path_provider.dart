import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/data/models/unit_with_diagrams.dart'; // Import the new model

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

// This single provider now fetches all the data needed for the UnitsScreen.
final learningPathProvider = FutureProvider<List<UnitWithDiagrams>>((ref) async {
  final dbHelper = ref.watch(databaseHelperProvider);
  final userProgress = ref.watch(userProgressProvider);

  // 1. Fetch all units
  final units = await dbHelper.getUnits();

  // 2. For each unit, fetch its diagrams and progress in parallel
  final List<UnitWithDiagrams> result = await Future.wait(units.map((unit) async {
    final diagrams = await dbHelper.getDiagramsForUnit(unit.id);

    final diagramsWithProgress = diagrams.map((diagram) {
      final progress = userProgress.levelStats[diagram.id];
      return DiagramWithProgress(diagram: diagram, progress: progress);
    }).toList();

    return UnitWithDiagrams(unit: unit, diagrams: diagramsWithProgress);
  }));

  return result;
});