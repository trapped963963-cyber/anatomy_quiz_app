import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anatomy_quiz_app/presentation/providers/onboarding_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkActivationStatus();
  }

  Future<void> _checkActivationStatus() async {
    // Wait a bit to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final activationCode = prefs.getString('activationCode');
    final phoneNumber = prefs.getString('phoneNumberForValidation');

    // Get an instance of our activation service from the provider
    final activationService = ref.read(activationServiceProvider);

    bool isStillValid = false;

    // First, check if we have the necessary credentials to even attempt a validation
    if (activationCode != null && activationCode.isNotEmpty && phoneNumber != null && phoneNumber.isNotEmpty) {
      // --- THIS IS THE NEW LOGIC ---
      // Re-calculate the expected code based on the device fingerprint and
      // compare it to the one saved in storage.
      isStillValid = await activationService.verifyActivationCode(
        phoneNumber: phoneNumber,
        activationCode: activationCode,
      );
    }

    // To ensure a clean state, if validation fails, we should clear the old invalid keys.
    if (!isStillValid) {
      await prefs.remove('activationCode');
      await prefs.remove('phoneNumberForValidation');
    }

    // This is to prevent errors if the user navigates away while we're checking
    if (!mounted) return; 

    if (isStillValid) {
      // User is still activated, load their data and go to the main screen
      await ref.read(userProgressProvider.notifier).loadInitialData();
      context.go('/home');
    } else {
      // User is not activated or validation failed, go to the welcome screen
      context.go('/welcome');
    }
  }
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('جاري التحميل...'),
          ],
        ),
      ),
    );
  }
}