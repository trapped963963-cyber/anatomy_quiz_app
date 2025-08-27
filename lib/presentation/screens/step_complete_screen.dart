import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/providers/quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';

// It's now a ConsumerStatefulWidget
class StepCompleteScreen extends ConsumerStatefulWidget {
  final int levelId;
  final int stepNumber;
  const StepCompleteScreen({super.key, required this.levelId, required this.stepNumber});

  @override
  ConsumerState<StepCompleteScreen> createState() => _StepCompleteScreenState();
}

class _StepCompleteScreenState extends ConsumerState<StepCompleteScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _confettiController.play();

    // ## THE FIX: Complete the step when this screen loads ##
    // We use a post-frame callback to safely call the provider after the build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProgressProvider.notifier).completeStep(widget.levelId, widget.stepNumber);
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _goBackToLevelScreen() {
    // We use context.go here to reset the quiz flow stack
    context.go('/home');
    context.push('/level/${widget.levelId}');
  }

  @override
  Widget build(BuildContext context) {
    final diagramAsync = ref.watch(diagramWithLabelsProvider(widget.levelId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if(!didPop) _goBackToLevelScreen();
      },
      child: Scaffold(
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('🎉 أحسنت!', style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold)),
                  SizedBox(height: 20.h),
                  Text('لقد أتقنت هذه الخطوة بنجاح.', style: TextStyle(fontSize: 20.sp), textAlign: TextAlign.center),
                  SizedBox(height: 40.h),

                  diagramAsync.when(
                    data: (diagram) {
                      // Show "Next Step" button only if this isn't the last step.
                      if (widget.stepNumber < diagram.labels.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.w),
                          child: ElevatedButton(
                            onPressed: () {
                              context.go('/home');
                              context.push('/level/${widget.levelId}');
                              context.push('/step/${widget.levelId}/${widget.stepNumber + 1}');
                           


                              // Use pushReplacement to go to the next step without building up history
                              context.pushReplacement('/step/${widget.levelId}/${widget.stepNumber + 1}');
                            },
                            child: const Text('الخطوة التالية'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  ),

                  SizedBox(height: 10.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: OutlinedButton(
                      onPressed: _goBackToLevelScreen,
                      child: const Text('تم'),
                    ),
                  ),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
            ),
          ],
        ),
      ),
    );
  }
}