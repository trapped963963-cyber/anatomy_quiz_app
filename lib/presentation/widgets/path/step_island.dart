import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

enum StepStatus { locked, current, completed }

class StepIsland extends StatelessWidget {
  final int stepNumber;
  final String title;
  final StepStatus status;
  final VoidCallback? onTap;

  const StepIsland({
    super.key,
    required this.stepNumber,
    required this.title,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color foregroundColor = Colors.white;
    IconData iconData;
    bool isTappable = status != StepStatus.locked;

    switch (status) {
      case StepStatus.completed:
        backgroundColor = AppColors.completed;
        iconData = Icons.check;
        break;
      case StepStatus.current:
        backgroundColor = AppColors.inProgress;
        iconData = Icons.play_arrow;
        break;
      case StepStatus.locked:
      default:
        backgroundColor = AppColors.locked;
        iconData = Icons.lock;
        break;
    }

    return InkWell(
      onTap: isTappable ? onTap : null,
      borderRadius: BorderRadius.circular(50.r),
      child: Column(
        children: [
          Container(
            width: 70.r,
            height: 70.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor,
              border: Border.all(color: Colors.white, width: 4.w),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Icon(iconData, color: foregroundColor, size: 35.r),
          ),
          SizedBox(height: 8.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: isTappable ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}