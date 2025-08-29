import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/datasources/database_helper.dart';

// This provider creates and exposes the singleton instance of our DatabaseHelper
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper();
});

final databaseInitializationProvider = FutureProvider<void>((ref) async {
  await ref.read(databaseHelperProvider).database;
});
