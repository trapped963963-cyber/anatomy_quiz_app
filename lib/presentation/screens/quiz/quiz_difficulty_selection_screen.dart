import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/custom_quiz_provider.dart';

class QuizDifficultySelectionScreen extends ConsumerStatefulWidget {
  const QuizDifficultySelectionScreen({super.key});

  @override
  ConsumerState<QuizDifficultySelectionScreen> createState() =>
      _QuizDifficultySelectionScreenState();
}

class _QuizDifficultySelectionScreenState extends ConsumerState<QuizDifficultySelectionScreen> {
  // Start the slider at "Medium" (index 2)
  double _currentSliderValue = 2;

  // Helper map to get display names for each difficulty
  final Map<QuizDifficulty, String> _difficultyLabels = {
    QuizDifficulty.veryEasy: 'سهل جداً',
    QuizDifficulty.easy: 'سهل',
    QuizDifficulty.medium: 'متوسط',
    QuizDifficulty.difficult: 'صعب',
    QuizDifficulty.veryDifficult: 'صعب جداً',
  };

  @override
  Widget build(BuildContext context) {
    // Get the enum value from the slider's double value
    final selectedDifficulty = QuizDifficulty.values[_currentSliderValue.toInt()];

    // Create a temporary config object to get the details for the selected difficulty
    final tempConfig = CustomQuizConfig(difficulty: selectedDifficulty);
    final questionCount = tempConfig.questionCount;
    final timeInMinutes = tempConfig.timeInMinutes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الصعوبة'),
      ),
      body: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'حدد مستوى الصعوبة',
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            // Display the name of the selected difficulty
            Text(
              _difficultyLabels[selectedDifficulty]!,
              style: TextStyle(fontSize: 22.sp, color: Theme.of(context).primaryColor, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10.h),
            // Display the details for the selected difficulty
            Text(
              '$questionCount سؤال في $timeInMinutes دقائق',
              style: TextStyle(fontSize: 18.sp, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            Slider(
              value: _currentSliderValue,
              min: 0,
              max: 4,
              divisions: 4, // 4 divisions create 5 steps
              label: _difficultyLabels[selectedDifficulty]!,
              onChanged: (double value) {
                setState(() {
                  _currentSliderValue = value;
                });
              },
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // Save the final difficulty choice to the provider
                ref.read(customQuizConfigProvider.notifier).setDifficulty(selectedDifficulty);
                // Navigate to the next screen (which we will build next)
                context.push('/quiz/in-progress');
              },
              child: const Text('ابدأ الاختبار'),
            ),
            TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
          ],
        ),
      ),
    );
  }
}