import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_result_provider.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:anatomy_quiz_app/presentation/providers/custom_quiz_provider.dart';

class QuizEndScreen extends ConsumerWidget {
  const QuizEndScreen({super.key});

  // Helper to get a message based on the score
  String _getFeedbackMessage(double percentage) {
    if (percentage == 1.0) {
      return 'علامة كاملة! أنت مذهل!';
    } else if (percentage >= 0.8) {
      return 'نتيجة ممتازة! عمل رائع.';
    } else if (percentage >= 0.6) {
      return 'نتيجة جيدة! استمر في المراجعة.';
    } else if (percentage >= 0.4) {
      return 'يمكنك فعل ما هو أفضل. المراجعة هي مفتاح النجاح.';
    } else {
      return 'لا بأس، كل خبير كان مبتدئاً. المراجعة ستساعدك.';
    }
  }
  LinearGradient _getProgressGradient(double percentage) {
    if (percentage >= 0.8) {
      // High score: Yellow to Green
      return const LinearGradient(colors: [AppColors.correct,Color.fromARGB(255, 169, 239, 171)]);
    } else if (percentage >= 0.4) {
      // Medium score: Orange to Yellow
      return const LinearGradient(colors: [Colors.orange, AppColors.accent]);
    } else {
      // Low score: Red to Orange
      return LinearGradient(colors: [AppColors.incorrect, Colors.orange.shade700]);
    }
  }
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = ref.watch(quizResultProvider);
    final score = results.correctAnswers.length;
    final total = results.totalQuestions;
    final percentage = total > 0 ? score / total : 0.0;
    final message = _getFeedbackMessage(percentage);
    final hasIncorrectAnswers = results.incorrectAnswers.isNotEmpty;
    final progressGradient = _getProgressGradient(percentage);

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتيجة الاختبار'),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CircularPercentIndicator(
                radius: 100.r, // Half of the desired diameter
                lineWidth: 20.0, // The thickness of the progress ring
                percent: percentage, // The progress value (0.0 to 1.0)
                center: Text(
                  '$score / $total',
                  style: TextStyle(
                    fontSize: 40.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                linearGradient: progressGradient,
                backgroundColor: Colors.grey.shade200,
                circularStrokeCap: CircularStrokeCap.round, // Makes the ends of the progress line rounded
                animation: true, // Animate the progress ring filling up
                animationDuration: 1200, // Duration of the animation
              ),
              SizedBox(height: 30.h),
              // Feedback Message
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              // Action Buttons
              if (hasIncorrectAnswers)
                ElevatedButton(
                  onPressed: () {
                    // Pass the list of incorrect answers to the review screen
                    context.push('/quiz/review', extra: results.incorrectAnswers);
                  },
                  child: const Text('بدء المراجعة'),
                ),
              
              SizedBox(height: 10.h),
              OutlinedButton(
                onPressed: () {
                  // Reset the old quiz configuration
                  ref.read(customQuizConfigProvider.notifier).reset();
                  // Go back to the beginning of the quiz creation flow
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