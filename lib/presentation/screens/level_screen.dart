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
import 'package:confetti/confetti.dart';
import 'package:anatomy_quiz_app/presentation/providers/celebration_provider.dart';


class LevelScreen extends ConsumerStatefulWidget {
  final int levelId;
  const LevelScreen({super.key, required this.levelId});

  @override
  ConsumerState<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends ConsumerState<LevelScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }
  void _showChallengeDialog(BuildContext context) {
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
              // Navigate to the quiz with a special step number for the challenge
              context.push('/step/${widget.levelId}/-1');
            },
            child: const Text('ابدأ التحدي'),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
     
     ref.listen<int?>(completedLevelCelebrationProvider, (previous, next) {
      // If a level ID was set, and it's the current level...
      if (next != null && next == widget.levelId) {
        _confettiController.play();
        // Reset the provider so the celebration doesn't happen again.
        ref.read(completedLevelCelebrationProvider.notifier).state = null;
      }
    });
    final diagramAsync = ref.watch(diagramWithLabelsProvider(widget.levelId));
    final userProgress = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: diagramAsync.when(
          data: (d) => Text(d.title),
          loading: () => const Text(''),
          error: (e, s) => const Text('خطأ'),
        ),
      ),
      body: Stack(
        alignment: Alignment.topCenter,
        children: 
          [diagramAsync.when(
          data: (diagram) {
            return Column(
              children: [ 
                SizedBox(
                  height: 200.h, // Give the diagram a fixed height
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
                      return SizedBox(
                        height: 150.h,
                        child: Center(
                          child: FinalChallengeIsland(
                            isUnlocked: true,
                            onTap: () => _showChallengeDialog(context),
                          ),
                        ),
                      );
                    }
                    final label = diagram.labels[index];
                    final stepNumber = index + 1;
                              
                    final LevelStat? levelProgress = userProgress.levelStats[widget.levelId];
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
                        onTap: () => context.push('/step/${widget.levelId}/$stepNumber'),
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
            ConfettiWidget(
      confettiController: _confettiController,
      blastDirectionality: BlastDirectionality.explosive,
      shouldLoop: false,),
    
        ]
      ),
    );
  }
}