import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/learning_path_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagrams_carousel.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  final List<Gradient> _unitGradients = const [
    LinearGradient(
      colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFF2C94C), Color(0xFFF2994A)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFB24592), Color(0xFFF15F79)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningPathAsync = ref.watch(learningPathProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: learningPathAsync.when(
      data: (unitsWithDiagrams) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: unitsWithDiagrams.length,
            cacheExtent: 900.h,
            itemBuilder: (context, index) {
              // The itemBuilder now just creates our new, optimized widget.
              return UnitSection(
                unitWithDiagrams: unitsWithDiagrams[index],
                gradient: _unitGradients[index % _unitGradients.length],
              );
            },
          );
        },
        loading: () => const AppLoadingIndicator(),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

// ## NEW: A dedicated, stateful widget for each unit section ##
class UnitSection extends ConsumerStatefulWidget {
  final UnitWithDiagrams unitWithDiagrams;
  final Gradient gradient;

  const UnitSection({
    super.key,
    required this.unitWithDiagrams,
    required this.gradient,
  });

  @override
  ConsumerState<UnitSection> createState() => _UnitSectionState();
}


// ## THE FIX: Add the AutomaticKeepAliveClientMixin ##
class _UnitSectionState extends ConsumerState<UnitSection> with AutomaticKeepAliveClientMixin {
  // This tells the ListView to keep this widget alive.
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    // We must call super.build(context) for the mixin to work.
    super.build(context);

    final unit = widget.unitWithDiagrams.unit;
    final diagramsWithProgress = widget.unitWithDiagrams.diagrams;

    int initialIndex = diagramsWithProgress.indexWhere(
      (d) => d.progress == null || d.progress!.isCompleted == false,
    );
    if (initialIndex == -1) initialIndex = 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          decoration: BoxDecoration(gradient: widget.gradient),
          child: Text(
            unit.title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white, shadows: [Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.3))]),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: DiagramsCarousel(
            diagrams: diagramsWithProgress,
            initialIndex: initialIndex,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}