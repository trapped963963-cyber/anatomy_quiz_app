
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:anatomy_quiz_app/core/constants/app_strings.dart';
import 'package:anatomy_quiz_app/core/utils/sound_service.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  Future<void> _checkActivationAndNavigate(BuildContext context, WidgetRef ref) async {
    ref.read(soundServiceProvider).preloadSounds();

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

    if (!context.mounted) return;

       if (isStillValid) {
      // ## THE FIX: Initialize the EncryptionService here ##
      // This happens only for a valid, activated user.

      // 1. Get the secure storage service.
      final secureStorage = ref.read(secureStorageServiceProvider);
      // 2. Get the saved database decryption key.
      final dbKey = await secureStorage.getDbKey();

      // 3. Check if the key exists. If not, the activation is corrupt.
      if (dbKey == null) {
        // Clear the bad activation data and send the user back to the start.
        await prefs.clear();
        await secureStorage.deleteAll();
        if (context.mounted) context.go('/welcome');
        return;
      }
      
      // 4. If the key exists, initialize the encryption service with it.
      ref.read(encryptionServiceProvider).initialize(dbKey);
      
      // Now, with all services ready, load the user's progress.
      await ref.read(userProgressProvider.notifier).loadInitialData();
      if (context.mounted) context.go('/home');
    } else {
      // If the user is not activated, go to the welcome screen.
      context.go('/welcome');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseInitializationProvider);

    return Scaffold(
      body: dbAsync.when(
        loading: () => const AppLoadingIndicator(),
        error: (err, stack) => Center(
          child: Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 60.r),
                 SizedBox(height: 20.h),
                 const Text(
                  AppStrings.unAbleToFindDbMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18),
                ),
               ],
            ),
          ),
        ),
        // If the database is ready, proceed with the activation check.
        data: (_) {
          // We use a post-frame callback to ensure the navigation happens
          // after the build is complete.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkActivationAndNavigate(context, ref);
          });

          // We still show the splash UI while the activation check runs.
          return const AppLoadingIndicator();
        },
      ),
    );
  }
}