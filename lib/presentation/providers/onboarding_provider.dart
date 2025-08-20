import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/core/utils/activation_service.dart';
class OnboardingState {
  final String name;
  final String phoneNumber;

  OnboardingState({this.name = '', this.phoneNumber = ''});

  OnboardingState copyWith({String? name, String? phoneNumber}) {
    return OnboardingState(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier() : super(OnboardingState());

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void setPhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

// Provider for our activation service
final activationServiceProvider = Provider((ref) => ActivationService());