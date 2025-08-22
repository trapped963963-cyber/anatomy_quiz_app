import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/core/utils/activation_service.dart';

enum Gender { male, female }
class OnboardingState {
  final String name;
  final String phoneNumber;
  final Gender? gender; 

  OnboardingState({
    this.name = '', 
    this.phoneNumber = '',
    this.gender,
    });

  OnboardingState copyWith({String? name, String? phoneNumber, Gender? gender}) {
    return OnboardingState(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
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

  void setGender(Gender gender) {
    state = state.copyWith(gender: gender);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

// Provider for our activation service
final activationServiceProvider = Provider((ref) => ActivationService());