import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagram_card.dart';

// It no longer needs to be a Consumer widget.
class DiagramsCarousel extends StatefulWidget {
  final List<DiagramWithProgress> diagrams;
  final int initialIndex;

  const DiagramsCarousel({
    super.key,
    required this.diagrams,
    required this.initialIndex,
  });

  @override
  State<DiagramsCarousel> createState() => _DiagramsCarouselState();
}

class _DiagramsCarouselState extends State<DiagramsCarousel> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    // ## THE FIX: Use the initialIndex passed from the parent ##
    _pageController = PageController(
      viewportFraction: 0.8,
      initialPage: widget.initialIndex,
    );
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
    // The widget now receives the diagrams directly.
    final diagrams = widget.diagrams;

    if (diagrams.isEmpty) {
      return const Center(child: Text('لا توجد رسوم بيانية في هذه الوحدة.'));
    }

    return SizedBox(
      height: 250.h,
      child: PageView.builder(
        controller: _pageController,
        itemCount: diagrams.length,
        itemBuilder: (context, index) {
          double scale = 1.0;
          double rotation = 0.0;
          if (_pageController.position.haveDimensions) {
            double value = index - _currentPageValue;
            value = (value * 0.038).clamp(-1, 1);
            rotation = value;
            scale = 1 - (value.abs() * 0.2);
          }

          return Transform.scale(
            scale: scale,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
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