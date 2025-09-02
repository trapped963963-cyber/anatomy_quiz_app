import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/custom_quiz_provider.dart';

import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';
// It's now a ConsumerWidget to watch our new provider.
class QuizDifficultySelectionScreen extends ConsumerWidget {
  const QuizDifficultySelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider that calculates the max questions.
    final maxQuestionsAsync = ref.watch(maxQuestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار الصعوبة'),
      ),
      body: maxQuestionsAsync.when(
        // Show a loader while calculating.
        loading: () => const AppLoadingIndicator(),
        error: (e, st) => Center(child: Text('Error: $e')),
        // Once we have the data, build the main UI.
        data: (maxQuestions) {
          return _buildUI(context, ref, maxQuestions);
        },
      ),
    );
  }

  // This is the main UI builder, now separated for clarity.
  Widget _buildUI(BuildContext context, WidgetRef ref, int maxQuestions) {
    // We use a local StateNotifier to manage the slider state efficiently.
    final sliderState = ref.watch(_sliderProvider);
    final sliderNotifier = ref.read(_sliderProvider.notifier);

    final selectedDifficulty = QuizDifficulty.values[sliderState.toInt()];
    final tempConfig = CustomQuizConfig(difficulty: selectedDifficulty);
    final questionCount = tempConfig.questionCount;
    final timeInMinutes = tempConfig.timeInMinutes;

    // This is the key logic: check if the current difficulty is possible.
    final bool isCurrentDifficultyPossible = questionCount <= maxQuestions;

    return Padding(
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
          SizedBox(height: 10.h),
          if (maxQuestions < 50)
            Padding(
              padding: EdgeInsets.only(bottom: 20.h), // Add padding here
              child: Text(
                'الحد الأقصى للأسئلة المتاحة: $maxQuestions',
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ),
          SizedBox(height: 30.h),
          Text(
            _difficultyLabels[selectedDifficulty]!,
            style: TextStyle(
              fontSize: 22.sp,
              color: isCurrentDifficultyPossible ? Theme.of(context).primaryColor : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10.h),
          Text(
            '$questionCount سؤال في $timeInMinutes دقائق',
            style: TextStyle(
              fontSize: 18.sp,
              color: isCurrentDifficultyPossible ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 20.h),
          Slider(
            value: sliderState,
            min: 0,
            max: 4,
            divisions: 4,
            label: _difficultyLabels[selectedDifficulty]!,
            // The slider's onChanged is disabled if the selected difficulty is impossible.
            onChanged: (double value) {
              // This is a small UX improvement: if a user tries to slide past
              // the max possible, we stop them at the highest possible level.
              final tappedDifficulty = QuizDifficulty.values[value.toInt()];
              if (CustomQuizConfig(difficulty: tappedDifficulty).questionCount > maxQuestions) {
                // Don't update the slider if the choice is invalid.
                return;
              }
              sliderNotifier.setValue(value);
            },
          ),
          const Spacer(),
          ElevatedButton(
            // The "Start" button is only enabled if the chosen difficulty is possible.
            onPressed: isCurrentDifficultyPossible
                ? () {
                    ref.read(customQuizConfigProvider.notifier).setDifficulty(selectedDifficulty);
                    context.push('/quiz/in-progress');
                  }
                : null,
            child: const Text('ابدأ الاختبار'),
          ),
          TextButton(onPressed: () => context.pop(), child: const Text('رجوع')),
        ],
      ),
    );
  }
}

// A small, local provider to manage just the slider's state.
final _sliderProvider = StateNotifierProvider.autoDispose<SliderNotifier, double>((ref) {
  return SliderNotifier();
});

class SliderNotifier extends StateNotifier<double> {
  SliderNotifier() : super(0); // Start at Medium
  void setValue(double value) => state = value;
}

const Map<QuizDifficulty, String> _difficultyLabels = {
  QuizDifficulty.veryEasy: 'سهل جداً',
  QuizDifficulty.easy: 'سهل',
  QuizDifficulty.medium: 'متوسط',
  QuizDifficulty.difficult: 'صعب',
  QuizDifficulty.veryDifficult: 'صعب جداً',
};