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

// Provider 3: The main provider our UI will use.
// It takes the diagrams from Provider 2, gets the user's progress,
// and combines them into the `DiagramWithProgress` model we created.
final diagramsWithProgressProvider = Provider.family<List<DiagramWithProgress>, int>((ref, unitId) {
  // Watch for the list of diagrams for the given unit.
  final diagramsAsyncValue = ref.watch(diagramsForUnitProvider(unitId));
  // Watch for the user's overall progress.
  final userProgress = ref.watch(userProgressProvider);

  return diagramsAsyncValue.when(
    data: (diagrams) {
      // When we have the diagrams, map over them.
      return diagrams.map((diagram) {
        // For each diagram, look up its progress in the user's progress map.
        final progress = userProgress.levelStats[diagram.id];
        // Return our combined model.
        return DiagramWithProgress(diagram: diagram, progress: progress);
      }).toList();
    },
    // While loading or if there's an error, return an empty list.
    loading: () => [],
    error: (e, st) => [],
  );
});