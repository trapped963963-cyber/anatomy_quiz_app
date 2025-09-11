import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:anatomy_quiz_app/presentation/providers/settings_provider.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';

class QuizStatusBar extends ConsumerStatefulWidget {
  final int totalSeconds;
  final int remainingSeconds;

  const QuizStatusBar({
    super.key,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  @override
  ConsumerState<QuizStatusBar> createState() => _QuizStatusBarState();
}

class _QuizStatusBarState extends ConsumerState<QuizStatusBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int? _lastDisplayedMinute;
  bool _isPulsingContinuously = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _lastDisplayedMinute = (widget.remainingSeconds / 60).floor();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuizStatusBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.remainingSeconds != oldWidget.remainingSeconds) {
      _updateAnimationState();
    }
  }

  void _updateAnimationState() {
    final currentMinute = (widget.remainingSeconds / 60).floor();
    final hapticsEnabled = ref.read(settingsProvider)['haptics'] ?? true;

    // Minute Pulse
    if (currentMinute < _lastDisplayedMinute!) {
      // We now need to play and then reverse the animation for a single pulse
      _pulseController.forward().then((_) => _pulseController.reverse());
      if (hapticsEnabled) HapticFeedback.selectionClick();
    }
    _lastDisplayedMinute = currentMinute;

    // Urgency Pulse
    if (widget.remainingSeconds <= 30) {
      if (!_isPulsingContinuously) {
        _isPulsingContinuously = true;
        _pulseController.repeat(reverse: true);
      }
    } else {
      if (_isPulsingContinuously) {
        _isPulsingContinuously = false;
        _pulseController.stop();
        _pulseController.animateTo(0.0); // Animate back to the normal scale
      }
    }

    // Haptic feedback
    if (widget.remainingSeconds == 5) {
      if (hapticsEnabled) HapticFeedback.heavyImpact();
    }
  }

  // ## THE FIX: This function now returns a single, solid Color ##
  Color _getProgressColor(BuildContext context) {
    final ratio = widget.totalSeconds > 0
        ? (widget.remainingSeconds / widget.totalSeconds).clamp(0.0, 1.0)
        : 0.0;

    if (ratio > 0.5) {
      // For the top half, smoothly transition from orange to your primary theme color
      return Color.lerp(Colors.orange, Theme.of(context).primaryColor, (ratio - 0.5) / 0.5)!;
    } else {
      // For the bottom half, smoothly transition from red to orange
      return Color.lerp(AppColors.incorrect, Colors.orange, ratio / 0.5)!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progressColor = _getProgressColor(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.w, vertical: 8.h),
      child: ScaleTransition(
        scale: _pulseAnimation,
        child: LinearPercentIndicator(
          percent: widget.totalSeconds > 0
              ? widget.remainingSeconds / widget.totalSeconds
              : 0,
          lineHeight: 8.h,
          barRadius: Radius.circular(10.r),
          
          // ## THE FIX: Set both colors to the same dynamic color ##
          progressColor: progressColor,
          backgroundColor: progressColor.withOpacity(0.3), // Use a faded version for the background

          animation: true,
          animateFromLastPercent: true,
          animationDuration: 1000,
        ),
      ),
    );
  }
}