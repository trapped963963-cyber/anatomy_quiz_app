import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/core/utils/activation_service.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';
import 'package:anatomy_quiz_app/core/utils/secure_storage_service.dart';
import 'package:anatomy_quiz_app/core/utils/user_activity_service.dart';

final activationServiceProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  // Pass the dependencies into the ActivationService
  return ActivationService(apiService, secureStorage);
});
final apiServiceProvider = Provider((ref) => ApiService());

final secureStorageServiceProvider = Provider((ref) => SecureStorageService());


// Add this to your service_providers.dart file

final userActivityServiceProvider = Provider((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final activationService = ref.watch(activationServiceProvider);
  return UserActivityService(apiService, activationService);
});