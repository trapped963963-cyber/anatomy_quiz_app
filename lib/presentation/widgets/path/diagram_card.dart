import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart'; // <-- ADD THIS IMPORT


class DiagramCard extends ConsumerWidget {
  final DiagramWithProgress diagramWithProgress;

  const DiagramCard({super.key, required this.diagramWithProgress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        alignment: Alignment.bottomCenter,
        children: [
          Positioned.fill(
            child: Image.asset(
              diagram.imageAssetPath,
              fit: BoxFit.cover,
              color: Colors.black.withOpacity(0.5),
              colorBlendMode: BlendMode.darken,
            ),
          ),
          
          Positioned(
            top: 16.h,
            left: 16.w,
            right: 16.w,
            child: Text(
              diagram.title,
              style: TextStyle(
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.7))],
              ),
            ),
          ),

          Container(
            height: 60.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: const BoxDecoration(
              color: AppColors.surface,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: isCompleted
                      ? Icon(Icons.check_circle, color: AppColors.correct, size: 30.r)
                      : SizedBox(
                          width: 50.r,
                          height: 50.r,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircularProgressIndicator(
                                value: percentage,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                              Text(
                                '${(percentage * 100).toInt()}%',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                
                // -- Center: The Action Button --
                Align(
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(userProgressProvider.notifier).setLastActiveLevel(diagram.id, diagram.title);
                      print(diagram.title);
                      context.push('/level/${diagram.id}');
                    }, 
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      padding: EdgeInsets.all(12.r),
                      backgroundColor: isCompleted ? AppColors.correct : AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Icon(
                      isCompleted ? Icons.replay : Icons.arrow_forward,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}