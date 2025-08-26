import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/custom_quiz_provider.dart';

class ReviewEndScreen extends ConsumerWidget {
  const ReviewEndScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.lightbulb_outline_rounded,
                size: 80.r,
                color: Theme.of(context).primaryColor,
              ),
              SizedBox(height: 20.h),
              Text(
                'الخطأ هو ببساطة فرصة لبدء من جديد، وهذه المرة بذكاء أكبر.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                ),
              ),
              SizedBox(height: 40.h),
              ElevatedButton(
                onPressed: () {
                  // Reset the quiz config and go back to the selection screen
                  ref.read(customQuizConfigProvider.notifier).reset();
                  context.go('/quiz/select-content');
                },
                child: const Text('بدء اختبار جديد'),
              ),
              SizedBox(height: 10.h),
              OutlinedButton(
                onPressed: () {
                  context.go('/home');
                },
                child: const Text('العودة للصفحة الرئيسية'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}