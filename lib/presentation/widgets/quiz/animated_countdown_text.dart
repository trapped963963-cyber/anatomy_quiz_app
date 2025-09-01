import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:flutter/services.dart';
class AnimatedCountdownText extends StatefulWidget {
  final int totalSeconds;
  final int remainingSeconds;
  final bool hapticsEnabled;

  const AnimatedCountdownText({
    Key? key,
    required this.totalSeconds,
    required this.remainingSeconds,
    required this.hapticsEnabled,

  }) : super(key: key);

  @override
  State<AnimatedCountdownText> createState() => _AnimatedCountdownTextState();
}

class _AnimatedCountdownTextState extends State<AnimatedCountdownText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late int _lastDisplayedMinute;
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();
    // initialize last minute so we only pulse when minute actually decreases
    _lastDisplayedMinute = (widget.remainingSeconds / 60).floor();

    // controller uses 0..1; we map it to a visual scale tween (1.0 -> 1.12)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 540),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // if we start already inside last-30s, start repeating pulse
    if (widget.remainingSeconds <= 30) {
      _startRepeating();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedCountdownText oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newMinute = (widget.remainingSeconds / 60).floor();

    // 1) minute boundary: if minute decreased, play a single pulse (no-op if repeating)
    if (newMinute < _lastDisplayedMinute && !_isRepeating) {
      _singlePulse();
    }
    _lastDisplayedMinute = newMinute;

    // 2) last 30s continuous pulse
    if (widget.remainingSeconds <= 30) {
      if (!_isRepeating) _startRepeating();
    } else {
      if (_isRepeating) _stopRepeating();
    }

    // 3) optional: do a small one-time haptic when crossing into last-5s
    if (widget.remainingSeconds <= 5 && oldWidget.remainingSeconds > 5) {
        if (widget.hapticsEnabled) {
          HapticFeedback.heavyImpact();
        }
    }
  }

  void _singlePulse() {
    try {
      if (widget.hapticsEnabled) {
      HapticFeedback.selectionClick();}
      _controller.forward(from: 0.0);
    } catch (_) {
      // defensive: shouldn't happen now, but swallow to avoid crashes
    }
  }

  void _startRepeating() {
    if (_isRepeating) return;
    _isRepeating = true;
    _controller.repeat(reverse: true);
  }

  void _stopRepeating() {
    if (!_isRepeating) return;
    _isRepeating = false;
    _controller.stop();
    _controller.reset(); // bring it back to neutral scale (1.0)
  }

  Color _getGradientColor() {
    final total = widget.totalSeconds > 0 ? widget.totalSeconds : 1;
    final ratio = (widget.remainingSeconds / total).clamp(0.0, 1.0);

    if (ratio >= 0.5) {
      // green -> orange for the top half
      final t = (ratio - 0.5) / 0.5;
      return Color.lerp(Colors.orange, Colors.green, t)!;
    } else {
      // orange -> red for the bottom half
      final t = ratio / 0.5;
      return Color.lerp(Colors.red, Colors.orange, t)!;
    }
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Text(
        _formatTime(widget.remainingSeconds),
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
          color: _getGradientColor(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
