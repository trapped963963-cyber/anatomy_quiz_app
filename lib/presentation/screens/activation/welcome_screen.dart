import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter/services.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          // ## THE FIX: Use a Stack to layer the logo and the content ##
          child: Stack(
            children: [
              // --- 1. The Background Watermark ---
              Center(
                child: Opacity(
                  opacity: 0.1, // Make it very subtle
                  child: Image.asset(
                    'assets/images/loading_logo.png', // The path to your logo
                    width: 500.r,
                    height: 500.r,
                  ),
                ),
              ),
              // --- 2. The Foreground Content ---
              Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'أهلاً بك في علوم لايت',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'استعد لرحلة ممتعة لتعلم وحفظ جميع رسمات العلوم.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18.sp, color: AppColors.textSecondary),
                    ),
                    SizedBox(height: 60.h),
                    ElevatedButton(
                      onPressed: () => context.push('/name'),
                      child: const Text('ابدأ الآن'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}