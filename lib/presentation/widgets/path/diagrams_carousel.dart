import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagram_card.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';

// It needs to be a StatefulWidget again to track the focused index.
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
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    _focusedIndex = widget.initialIndex;
  }

  // This is a new helper method to build each item.
  Widget _buildListItem(BuildContext context, int index) {
    // We no longer need any manual Transform widgets here.
    // The package will handle the scaling for us.
    return DiagramCard(diagramWithProgress: widget.diagrams[index]);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.diagrams.isEmpty) {
      return const Center(child: Text('لا توجد رسوم بيانية في هذه الوحدة.'));
    }

    return SizedBox(
      height: 250.h,
      child: ScrollSnapList(
        onItemFocus: (index) {
          setState(() {
            _focusedIndex = index;
          });
        },
        itemBuilder: _buildListItem,

        itemCount: widget.diagrams.length,
        itemSize: 240.w,
        initialIndex: widget.initialIndex.toDouble(),
        scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,

        // This makes the items on the side smaller.
        dynamicItemSize: true, 
        
        // This makes the items on the side more transparent.
        dynamicItemOpacity: 0.5,
        selectedItemAnchor: SelectedItemAnchor.MIDDLE,
      ),
    );
  }
}