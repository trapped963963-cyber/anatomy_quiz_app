import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/core/constants/app_strings.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.science_outlined,
            size: 80.r, // Slightly smaller for general use
            color: Theme.of(context).primaryColor,
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .fade(duration: 1500.ms, curve: Curves.easeInOut),
          SizedBox(height: 20.h),
          Text(
            AppStrings.loadingMessage,
            style: TextStyle(fontSize: 18.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}