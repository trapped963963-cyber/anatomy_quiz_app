import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/core/utils/activation_service.dart';
import 'package:anatomy_quiz_app/core/utils/api_service.dart';
import 'package:anatomy_quiz_app/data/models/user_progress.dart';

class OnboardingState {
  final String name;
  final String phoneNumber;
  final Gender? gender; 
  final String? promoCode;

  OnboardingState({
    this.name = '', 
    this.phoneNumber = '',
    this.gender,
    this.promoCode, 
    });

  OnboardingState copyWith({String? name, String? phoneNumber, Gender? gender , String? promoCode }) {
    return OnboardingState(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      promoCode: promoCode ?? this.promoCode,
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

  void setPromoCode(String code) {
    state = state.copyWith(promoCode: code);
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier();
});

// Provider for our activation service
final activationServiceProvider = Provider((ref) => ActivationService());
// Add this provider with the others
final apiServiceProvider = Provider((ref) => ApiService());