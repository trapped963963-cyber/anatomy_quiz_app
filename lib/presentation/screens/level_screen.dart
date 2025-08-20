import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

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
              final bool isCurrentStep = userProgress.currentLevelId == levelId && userProgress.currentStepInLevel == stepNumber;
              final bool isStepCompleted = userProgress.currentLevelId > levelId || (userProgress.currentLevelId == levelId && userProgress.currentStepInLevel > stepNumber);
              
              return Card(
                elevation: 2,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isStepCompleted ? AppColors.completed : (isCurrentStep ? AppColors.inProgress : AppColors.locked),
                    child: Text(stepNumber.toString(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(label.title),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  // The onTap is now enabled if the step is the current one OR is already completed.
                  onTap: (isCurrentStep || isStepCompleted)
                      ? () {
                          context.go('/step/$levelId/$stepNumber');
                        }
                      : null, // The button is disabled for locked steps.
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