import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/core/utils/activation_service.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';

final activationServiceProvider = Provider((ref) => ActivationService());
final apiServiceProvider = Provider((ref) => ApiService());