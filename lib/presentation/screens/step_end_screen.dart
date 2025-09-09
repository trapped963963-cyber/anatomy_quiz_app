import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';


class StepEndScreen extends ConsumerStatefulWidget {
  final int levelId;
  final int stepNumber;
  final int totalCorrect;
  final int totalWrong;
  final List<Question> wronglyAnswered;

  const StepEndScreen({
    super.key,
    required this.levelId,
    required this.stepNumber,
    required this.totalCorrect,
    required this.totalWrong,
    required this.wronglyAnswered,
  });

  @override
  ConsumerState<StepEndScreen> createState() => _StepEndScreenState();
}

class _StepEndScreenState extends ConsumerState<StepEndScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    if (widget.totalWrong == 0) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // ## NEW: Confirmation Dialog Logic ##
  void _showExitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('هل أنت متأكد؟'),
          content: const Text('لم تكمل هذه الخطوة بعد. إذا خرجت الآن، فسيتم فقدان تقدمك.'),
          actions: <Widget>[
            TextButton(
              child: const Text('البقاء'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              child: const Text('الخروج'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.go('/home');
                context.push('/level/${widget.levelId}');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool needsReview = widget.wronglyAnswered.isNotEmpty;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _showExitConfirmationDialog(context);
        }
      },
      child: Scaffold(
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    needsReview ? 'تحتاج إلى بعض المراجعة' : 'أداء رائع!',
                    style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    'الأجوبة الصحيحة: ${widget.totalCorrect}\nالأجوبة الخاطئة: ${widget.totalWrong}',
                    style: TextStyle(fontSize: 20.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40.h),
                  ElevatedButton.icon(
                    icon: Icon(needsReview ? Icons.replay : Icons.check_circle),
                    label: Text(needsReview ? 'بدء المراجعة' : 'إنهاء الخطوة'),
                    onPressed: () {
                      if (needsReview) {
                        context.push(
                          '/review',
                          extra: {
                            'questions': widget.wronglyAnswered,
                            'levelId': widget.levelId,
                            'stepNumber': widget.stepNumber,
                          },
                        );
                      } else {
                        ref.read(userProgressProvider.notifier).masterLevel(widget.levelId);
                        context.pushReplacement('/step-complete/${widget.levelId}/${widget.stepNumber}');
                      }
                    },
                  ),
                ],
              ),
            ),
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
              createParticlePath: (size) {
                return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: 8));
              },
            ),
          ],
        ),
      ),
    );
  }
}