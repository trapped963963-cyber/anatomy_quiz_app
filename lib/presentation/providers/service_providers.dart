import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/core/utils/activation_service.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';
import 'package:anatomy_quiz_app/core/utils/secure_storage_service.dart';

final activationServiceProvider = Provider((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ActivationService(secureStorage);
});

final apiServiceProvider = Provider((ref) => ApiService());

final secureStorageServiceProvider = Provider((ref) => SecureStorageService());