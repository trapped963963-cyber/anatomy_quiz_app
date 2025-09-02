import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/data/datasources/database_helper.dart';
import 'package:anatomy_quiz_app/presentation/providers/service_providers.dart'; // Import for the new provider

// This provider now gets the encryption service and passes it to the DatabaseHelper.
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  // ## THE FIX ##
  // 1. Get the encryption service.
  final encryptionService = ref.watch(encryptionServiceProvider);
  // 2. Pass it into the DatabaseHelper's constructor.
  return DatabaseHelper(encryptionService);
});

// This provider remains the same. Its only job is to trigger the initialization.
final databaseInitializationProvider = FutureProvider<void>((ref) async {
  await ref.read(databaseHelperProvider).database;
});