import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class DiagramCard extends StatelessWidget {
  final DiagramWithProgress diagramWithProgress;

  const DiagramCard({super.key, required this.diagramWithProgress});

  @override
  Widget build(BuildContext context) {
    final diagram = diagramWithProgress.diagram;
    final progress = diagramWithProgress.progress;

    final completedSteps = progress?.completedSteps ?? 0;
    final totalSteps = diagram.totalSteps;
    final percentage = totalSteps > 0 ? (completedSteps / totalSteps) : 0.0;
    final isCompleted = progress?.isCompleted ?? false;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Stack(
        children: [
          // Faded Background Image
          Positioned.fill(
            child: Image.asset(
              diagram.imageAssetPath,
              fit: BoxFit.cover,
              color: Colors.black.withAlpha(125),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diagram.title,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.7))],
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.correct : AppColors.accent),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${(percentage * 100).toInt()}%',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                ElevatedButton(
                  onPressed: () => context.push('/level/${diagram.id}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('ابدأ الدراسة'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}