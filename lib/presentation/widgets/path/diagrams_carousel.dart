import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/learning_path_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagram_card.dart';

class DiagramsCarousel extends ConsumerStatefulWidget {
  final int unitId;
  const DiagramsCarousel({super.key, required this.unitId});

  @override
  ConsumerState<DiagramsCarousel> createState() => _DiagramsCarouselState();
}

class _DiagramsCarouselState extends ConsumerState<DiagramsCarousel> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.8);
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diagrams = ref.watch(diagramsWithProgressProvider(widget.unitId));

    if (diagrams.isEmpty) {
      return const Center(child: Text('لا توجد رسوم بيانية في هذه الوحدة.'));
    }

    return SizedBox(
      height: 250.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: diagrams.length,
        itemBuilder: (context, index) {
          // The magic happens here: calculate transform based on page position
          double scale = 1.0;
          double rotation = 0.0;
          if (_pageController.position.haveDimensions) {
            double value = index - _currentPageValue;
            value = (value * 0.038).clamp(-1, 1); // Small rotation
            rotation = value;
            scale = 1 - (value.abs() * 0.2); // Scale down side items
          }

          return Transform.scale(
            scale: scale,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001) // Perspective
                ..rotateY(rotation),
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w),
                child: DiagramCard(diagramWithProgress: diagrams[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}