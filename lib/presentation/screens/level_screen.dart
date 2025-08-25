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
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 16.w),
            itemCount: diagram.labels.length,
            itemBuilder: (context, index) {
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
                  onTap: () => context.push('/step/$levelId/$stepNumber'),
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('حدث خطأ: $e')),
      ),
    );
  }
}