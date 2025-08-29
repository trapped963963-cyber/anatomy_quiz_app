import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/core/utils/feedback_messages.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

// This is now a standalone function, not a method inside a class.
Future<bool?> showFeedbackBottomSheet({
  required BuildContext context,
  required WidgetRef ref,
  required bool isCorrect,
  required Question question,
}) async {
  final screenHeight = MediaQuery.of(context).size.height;
  final userProgress = ref.read(userProgressProvider);
  final gender = userProgress.gender == 'female' ? Gender.female : Gender.male;
  final message = FeedbackMessages.getRandomMessage(isCorrect: isCorrect, gender: gender);

  final bool shouldShowTitle =
      question.questionType == QuestionType.askForTitle ||
      question.questionType == QuestionType.askToWriteTitle;

  final String correctAnswerText = shouldShowTitle
      ? question.correctLabel.title
      : question.correctLabel.labelNumber.toString();

  return await showModalBottomSheet<bool>(
    context: context,
    isDismissible: true,
    backgroundColor: isCorrect ? AppColors.correct : AppColors.incorrect,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SizedBox(
        width: double.infinity,
        height: screenHeight * 0.33,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                message,
                style: TextStyle(fontSize: 32.sp, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12.h),
              if (!isCorrect)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: AutoSizeText(
                    'الإجابة الصحيحة: $correctAnswerText',
                    style: TextStyle(fontSize: 25.sp, color: Colors.white70),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    minFontSize: 14,
                  ),
                ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('التالي'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: isCorrect ? AppColors.correct : AppColors.incorrect,
                ),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              ),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      );
    },
  );
}


void showFullQuestionText(BuildContext context, String fullText) {
  final screenHeight = MediaQuery.of(context).size.height;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxHeight: screenHeight * 0.5),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Stack(
            children: [
              SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(height: 22.h),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          fullText,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 20.sp, height: 2.0, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -4.h,
                right: -12.w,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}


Widget buildQuestionContainer({
  required BuildContext context,
  required String text,
}) {
  return Stack(
    children: [
      Container(
        width: double.infinity,
        constraints: BoxConstraints(minHeight: 60.h, maxHeight: 80.h),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Center(
          child: AutoSizeText(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.bold),
            minFontSize: 14,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      Positioned(
        top: 0,
        left: -1.w,
        child: IconButton(
          icon: const Icon(Icons.zoom_out_map, color: AppColors.textSecondary),
          onPressed: () => showFullQuestionText(context, text),
          tooltip: 'عرض النص الكامل',
        ),
      ),
    ],
  );
}