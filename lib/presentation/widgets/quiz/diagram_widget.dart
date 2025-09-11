import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DiagramWidget extends StatefulWidget {
  final String imageAssetPath;

  const DiagramWidget({
    super.key,
    required this.imageAssetPath,
  });

  @override
  State<DiagramWidget> createState() => _DiagramWidgetState();
}

class _DiagramWidgetState extends State<DiagramWidget>
    with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  bool _areControlsVisible = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
    _startHideTimer();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _areControlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    if (!_areControlsVisible) {
      setState(() {
        _areControlsVisible = true;
      });
    }
    _startHideTimer();
  }

  void _resetView() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    _animationController.forward(from: 0);
    _startHideTimer();
  }

  void _handleDoubleTap(TapDownDetails details) {
    _animationController.stop();
    final position = details.localPosition;
    Matrix4 targetMatrix;
    if (_transformationController.value.isIdentity()) {
      const double scale = 2.5;
      targetMatrix = Matrix4.identity()
        ..translate(-position.dx * (scale - 1), -position.dy * (scale - 1))
        ..scale(scale);
    } else {
      targetMatrix = Matrix4.identity();
    }
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    _animationController.forward(from: 0);
    _startHideTimer();
  }

  void _openFullScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => _FullScreenDiagram(
          imageAssetPath: widget.imageAssetPath,
          initialMatrix: _transformationController.value,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // ## THE FIX: Add onTap to the GestureDetector ##
            GestureDetector(
              onTap: _openFullScreen, // Single tap now opens the full-screen view
              onDoubleTapDown: _handleDoubleTap,
              onScaleStart: (_) => _showControls(), // Also show controls on pan/zoom
              child: Hero(
                tag: widget.imageAssetPath,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  onInteractionStart: (_) => _showControls(),
                  panEnabled: true,
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.asset(
                    widget.imageAssetPath,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // We can now position the reset button in a different corner
            Positioned(
              top: 8.h,
              left: 8.w,
              child: AnimatedOpacity(
                opacity: _areControlsVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                child: Material(
                  color: Colors.black.withOpacity(0.3),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.zoom_out),
                    color: Colors.white,
                    onPressed: _resetView,
                    tooltip: 'إعادة تعيين',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// (The _FullScreenDiagram helper widget remains the same)
// --- The Full-Screen Helper Widget ---
// (This is now a StatefulWidget to handle its own smooth animations)

class _FullScreenDiagram extends StatefulWidget {
  final String imageAssetPath;
  final Matrix4 initialMatrix;

  const _FullScreenDiagram({required this.imageAssetPath, required this.initialMatrix});

  @override
  State<_FullScreenDiagram> createState() => _FullScreenDiagramState();
}

class _FullScreenDiagramState extends State<_FullScreenDiagram> with SingleTickerProviderStateMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController(widget.initialMatrix);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      _transformationController.value = _animation!.value;
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleDoubleTap(TapDownDetails details) {
    _animationController.stop();
    final position = details.localPosition;
    Matrix4 targetMatrix;

    if (_transformationController.value.isIdentity()) {
      const double scale = 2.5;
      targetMatrix = Matrix4.identity()
        ..translate(-position.dx * (scale - 1), -position.dy * (scale - 1))
        ..scale(scale);
    } else {
      targetMatrix = Matrix4.identity();
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurveTween(curve: Curves.easeInOut).animate(_animationController));
    _animationController.forward(from: 0);
  }

// In your _FullScreenDiagramState class...
// In your _FullScreenDiagramState class...
@override
Widget build(BuildContext context) {
  return Dismissible(
    key: const Key('fullscreen_diagram'),
    direction: DismissDirection.vertical,
    onDismissed: (_) => Navigator.of(context).pop(),
    child: Scaffold(
      backgroundColor: Colors.black.withOpacity(0.85),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: widget.imageAssetPath,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  panEnabled: true,
                  minScale: 1.0,
                  maxScale: 5.0,
                  // ## THE FIX ##
                  // The child is now a Container that fills the available space,
                  // making the entire black area interactive.
                  child: Container(
                    color: Colors.transparent, // Necessary to capture gestures on empty space
                    child: GestureDetector(
                      onDoubleTapDown: _handleDoubleTap,
                      child: Center( // Center the image within the full-size container
                        child: Image.asset(widget.imageAssetPath),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 10.h,
              right: 10.w,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}