import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class FinalChallengeIsland extends StatelessWidget {
  final bool isLessonCompleted;
  final VoidCallback onTap;

  const FinalChallengeIsland({
    super.key,
    required this.isLessonCompleted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = isLessonCompleted ? AppColors.surface : AppColors.accent;
    final IconData iconData = isLessonCompleted ? Icons.emoji_events_rounded : Icons.fitness_center;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50.r),
      child: Column(
        children: [
          Container(
            width: 100.r,
            height: 100.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              // ## THE FIX: Adjust the border and shadow for a cleaner look ##
              border: Border.all(
                color: Colors.black.withOpacity(0.1), // A subtle grey border
                width: 2.w,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15), // A slightly softer shadow
                  blurRadius: 10,
                  spreadRadius: 5,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Icon(
              iconData,
              color: isLessonCompleted ? Colors.amber.shade400 : Colors.white,
              size: 70.r,
            ),
          ),
          SizedBox(height: 8.h),
          if(!isLessonCompleted)
            Text(
              'التحدي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }
}