import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';

class ChallengeEndScreen extends ConsumerWidget {
  final int levelId;
  final List<Question> incorrectAnswers;
  final int totalQuestions;

  const ChallengeEndScreen({
    super.key,
    required this.levelId,
    required this.incorrectAnswers,
    required this.totalQuestions,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int correctAnswers = totalQuestions - incorrectAnswers.length;
    final bool isPerfectScore = incorrectAnswers.isEmpty;
    // Automatically mark the level as mastered if the score is perfect.
    if (isPerfectScore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(userProgressProvider.notifier).masterLevel(levelId);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة التحدي'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'نتيجتك: $correctAnswers / $totalQuestions',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),
            Text(
              isPerfectScore
                  ? 'أداء مذهل! لقد أتقنت هذا الدرس.'
                  : 'أحسنت! استمر في المراجعة لتصل للإتقان.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18.sp),
            ),
            SizedBox(height: 40.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: ElevatedButton(
                onPressed: () {
                  context.go('/home');
                  context.push('/level/$levelId');
                },
                child: const Text('العودة للدرس'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}