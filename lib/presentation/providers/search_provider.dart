import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';

// This provider holds the user's current search text.
final searchQueryProvider = StateProvider<String>((ref) => '');

// This provider performs the search and returns the results.
final searchResultsProvider = FutureProvider<List<AnatomicalDiagram>>((ref) async {
  // It watches the search query. If the query is empty, it returns an empty list.
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) {
    return [];
  }

  final dbHelper = ref.watch(databaseHelperProvider);

  // Step 1: Get the list of matching IDs from the FTS search.
  final diagramIds = await dbHelper.searchDiagramIds(query);

  // Step 2: Use those IDs to batch-fetch the full diagram data.
  return dbHelper.getDiagramsByIds(diagramIds);
});