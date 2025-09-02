
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anatomy_quiz_app/presentation/providers/providers.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:anatomy_quiz_app/core/constants/app_strings.dart';
import 'package:anatomy_quiz_app/core/utils/sound_service.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

Future<void> _checkActivationAndNavigate(BuildContext context, WidgetRef ref) async {
  print("--- Starting Activation Check ---");

  print("Step 1: Preloading sounds...");
  await ref.read(soundServiceProvider).preloadSounds();
  print("Step 2: Sounds preloaded. Getting SharedPreferences...");

  final prefs = await SharedPreferences.getInstance();
  print("Step 3: Got SharedPreferences. Reading values...");

  final activationCode = prefs.getString('activationCode');
  final phoneNumber = prefs.getString('phoneNumberForValidation');
  print("Step 4: Values read. Getting ActivationService...");

  final activationService = ref.read(activationServiceProvider);
  bool isStillValid = false;

  if (activationCode != null && phoneNumber != null) {
    print("Step 5: Found credentials. Verifying activation code...");
    isStillValid = await activationService.verifyActivationCode(
      phoneNumber: phoneNumber,
      activationCode: activationCode,
    );
    print("Step 6: Verification complete. Result: $isStillValid");
  } else {
    print("Step 5: No credentials found. User is not activated.");
    isStillValid = false;
  }

  if (!context.mounted) return;

  if (isStillValid) {
    print("Step 7: User is valid. Getting SecureStorageService...");
    final secureStorage = ref.read(secureStorageServiceProvider);

    print("Step 8: Getting DB Key from secure storage...");
    final dbKey = await secureStorage.getDbKey();
    print("Step 9: DB Key found. Value is null? ${dbKey == null}");

    if (dbKey == null) {
      print("Step 10a: DB Key is missing. Navigating to /welcome.");
      if (context.mounted) context.go('/welcome');
      return;
    }

    print("Step 10b: DB Key is present. Initializing EncryptionService...");
    ref.read(encryptionServiceProvider).initialize(dbKey);
    print("Step 11: EncryptionService initialized. Loading initial user data...");

    await ref.read(userProgressProvider.notifier).loadInitialData();
    print("Step 12: User data loaded. Navigating to /home.");

    if (context.mounted) context.go('/home');
  } else {
    print("Step 7: User is not valid. Navigating to /welcome.");
    if (context.mounted) context.go('/welcome');
  }
}
     

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dbAsync = ref.watch(databaseInitializationProvider);

    return Scaffold(
      body: dbAsync.when(
        loading: () => Center(
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
              ).animate().fadeIn(delay: 1000.ms),
            ],
          ),
        ),
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
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}