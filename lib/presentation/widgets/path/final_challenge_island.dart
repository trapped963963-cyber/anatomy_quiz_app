import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class FinalChallengeIsland extends StatelessWidget {
  final bool isUnlocked;
  final VoidCallback onTap;

  const FinalChallengeIsland({
    super.key,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isUnlocked ? AppColors.accent : AppColors.locked;

    return InkWell(
      onTap: isUnlocked ? onTap : null,
      borderRadius: BorderRadius.circular(50.r),
      child: Column(
        children: [
          Container(
            width: 70.r,
            height: 70.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              border: Border.all(color: Colors.white, width: 4.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events_rounded : Icons.lock,
              color: isUnlocked ? Colors.white : Colors.white70,
              size: 35.r
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'التحدي النهائي',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}