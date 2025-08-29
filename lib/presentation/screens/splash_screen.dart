import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/core/constants/app_strings.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';

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
    
    final activationCheckFuture = _performValidation();

    await Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      activationCheckFuture,
    ]);

    final bool isStillValid = await activationCheckFuture;

    if (mounted) {
      if (isStillValid) {
        await ref.read(userProgressProvider.notifier).loadInitialData();
        if (mounted) context.go('/home');
      } else {
        context.go('/welcome');
      }
    }
  }

  Future<bool> _performValidation() async {
    final prefs = await SharedPreferences.getInstance();
    final activationCode = prefs.getString('activationCode');
    final phoneNumber = prefs.getString('phoneNumberForValidation');
    final activationService = ref.read(activationServiceProvider);
    bool isStillValid = false;

    if (activationCode != null && phoneNumber != null) {
      isStillValid = await activationService.verifyActivationCode(
        phoneNumber: phoneNumber,
        activationCode: activationCode,
      );
    }

    if (!isStillValid) {
      await prefs.remove('activationCode');
      await prefs.remove('phoneNumberForValidation');
    }
    return isStillValid;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.science_outlined,
              size: 100.r,
              color: Theme.of(context).primaryColor,
            ).animate().fade(duration: 1500.ms).scale(delay: 500.ms),
            
            SizedBox(height: 30.h),
            
            Text(
              AppStrings.loadingMessage,
              style: TextStyle(fontSize: 18.sp, color: Colors.grey.shade600),
            )
            // Animate the text to appear after the logo
            .animate().fadeIn(delay: 1000.ms),
          ],
        ),
      ),
    );
  }
}