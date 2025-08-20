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
    final phoneNumber = prefs.getString('phoneNumberForValidation'); // We need to save this
    
    // We'll assume for now if the code exists, it's valid.
    // The spec's logic to re-validate on every launch can be added here.
    if (activationCode != null && activationCode.isNotEmpty) {
      // User is activated, load their data and go to the main screen
      await ref.read(userProgressProvider.notifier).loadInitialData();
      if (mounted) context.go('/home');
    } else {
      // User is not activated, go to the welcome screen
      if (mounted) context.go('/welcome');
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