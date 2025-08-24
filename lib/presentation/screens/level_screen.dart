import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:anatomy_quiz_app/data/models/level_stat.dart';
class LevelScreen extends ConsumerWidget {
  final int levelId;
  const LevelScreen({super.key, required this.levelId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagramAsync = ref.watch(diagramWithLabelsProvider(levelId));
    final userProgress = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: diagramAsync.when(
          data: (d) => Text(d.title),
          loading: () => const Text(''),
          error: (e, s) => const Text('خطأ'),
        ),
      ),
      body: diagramAsync.when(
        data: (diagram) {
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: diagram.labels.length,
            itemBuilder: (context, index) {
              final label = diagram.labels[index];
              final stepNumber = index + 1;
              // 1. Get the specific progress for THIS level from our userProgress map.
              final LevelStat? levelProgress = userProgress.levelStats[levelId];
              // 2. Find how many steps are completed for this level. Default to 0 if the user hasn't started it yet.
              final int completedStepsForThisLevel = levelProgress?.completedSteps ?? 0;

              // 3. Define the step's status based on this level's specific progress.
              final bool isStepCompleted = stepNumber <= completedStepsForThisLevel;
              final bool isCurrentStep = stepNumber == completedStepsForThisLevel + 1;
              final bool isLocked = stepNumber > completedStepsForThisLevel + 1;
              return Card(
                elevation: isLocked ? 1 : 2,
                color: isLocked ? Colors.grey.shade100 : AppColors.surface,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStepCompleted
                        ? AppColors.completed
                        : (isCurrentStep ? AppColors.inProgress : AppColors.locked),
                    child: Icon(
                      isLocked ? Icons.lock : (isStepCompleted ? Icons.check : Icons.play_arrow),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(label.title, style: TextStyle(
                    color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                    fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal
                  )),
                  subtitle: Text('الخطوة $stepNumber'),
                  // A step is tappable as long as it's not locked.
                  onTap: !isLocked
                      ? () {
                          context.push('/step/$levelId/$stepNumber');
                        }
                      : null,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('حدث خطأ: $e')),
      ),
    );
  }
}