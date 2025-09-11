import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/step_island.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:anatomy_quiz_app/presentation/widgets/quiz/diagram_widget.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/final_challenge_island.dart';

// It is now a simple ConsumerWidget again.
class LevelScreen extends ConsumerWidget {
  final int levelId;
  const LevelScreen({super.key, required this.levelId});

  void _showChallengeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('🌟 تحدي الإتقان'),
        content: const Text('هذا اختبار شامل لكل الخطوات في هذا الدرس. إذا أجبت على جميع الأسئلة بشكل صحيح، فسيتم اعتبار الدرس مكتملاً!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('رجوع'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(quizProvider.notifier).reset();
              context.push('/step/$levelId/-1');
            },
            child: const Text('ابدأ التحدي'),
          ),
        ],
      ),
    );
  }

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
            return Column(
              children: [ 
                SizedBox(
                  height: 250.h, // Give the diagram a fixed height
                  child: DiagramWidget(
                    imageAssetPath: diagram.labeledImageAssetPath, // Use the new labeled image
                  ),
                ),
                const Divider(thickness: 2),
                Expanded(
                  child: ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 16.w),
                  itemCount: diagram.labels.length + 1,
                  itemBuilder: (context, index) {
                    if (index == diagram.labels.length) {
                      final isLessonCompleted = (userProgress.levelStats[levelId]?.isCompleted ?? false);

                      return SizedBox(
                        height: 150.h,
                        child: Center(
                          child: FinalChallengeIsland(
                            isLessonCompleted: isLessonCompleted,
                            onTap: () {
                              // ## THE FIX: Reset the provider here too ##
                              ref.read(quizProvider.notifier).reset();
                              _showChallengeDialog(context,ref);
                            },
                          ),
                        ),
                      );
                    }
                    final label = diagram.labels[index];
                    final stepNumber = index + 1;
                              
                    final LevelStat? levelProgress = userProgress.levelStats[levelId];
                    final int completedSteps = levelProgress?.completedSteps ?? 0;
                              
                    StepStatus status;
                    if (stepNumber <= completedSteps) {
                      status = StepStatus.completed;
                    } else if (stepNumber == completedSteps + 1) {
                      status = StepStatus.current;
                    } else {
                      status = StepStatus.locked;
                    }
                              
                              
                    Color pathColor;
                    if (status == StepStatus.completed) {
                      pathColor = AppColors.completed;
                    } else if (status == StepStatus.current) {
                      pathColor = AppColors.inProgress; // Use the 'in-progress' blue color
                    } else {
                      pathColor = Colors.grey.shade300;
                    }
                              
                    Widget pathConnector = Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: pathColor,
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: Colors.white, width: 3.w),
                        ),
                      ),
                    );
                              
                   
                    Widget island = Expanded(
                      flex: 2,
                      child: StepIsland(
                        stepNumber: stepNumber,
                        title: label.title,
                        status: status,
                        onTap: () {
                          // ## THE FIX: Reset the provider before starting a new quiz ##
                          ref.read(quizProvider.notifier).reset();
                          context.push('/step/$levelId/$stepNumber');
                        },
                      ),
                    );
                              
                    // ## TWEAK: Pulse Animation for Current Step ##
                    // If this is the current step, wrap the island in a repeating pulse animation.
                    if (status == StepStatus.current) {
                      island = island.animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .moveY( 
                        begin: 0,
                        end: -5.h, // Move it up by 8 pixels
                        duration: 1500.ms,
                        curve: Curves.easeInOut,
                      );
                    }
                              
                    // Alternate the position for a zig-zag effect.
                    if (index % 2 == 1) {
                      return SizedBox(
                        height: 150.h,
                        child: Row(
                          children: [const Spacer(flex: 2), pathConnector, island],
                        ),
                      );
                    } else {
                      return SizedBox(
                        height: 150.h,
                        child: Row(
                          children: [island, pathConnector, const Spacer(flex: 2)],
                        ),
                      );
                    }
                  },
                  ),
                ),
            ]
            );
          },
          loading: () => const AppLoadingIndicator(),
          error: (e, s) => Center(child: Text('حدث خطأ: $e')),
        ),
    );
  }
}