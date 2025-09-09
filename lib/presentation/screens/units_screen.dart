import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/learning_path_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagrams_carousel.dart';
import 'package:anatomy_quiz_app/presentation/widgets/shared/app_loading_indicator.dart';

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  // ## NEW: A predefined list of beautiful gradients ##
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
    final unitsAsync = ref.watch(unitsProvider);

    return Scaffold(
      // The AppBar is now simpler
      appBar: AppBar(
        title: const Text(''),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: unitsAsync.when(
        data: (units) {
          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];
              final diagramsAsync = ref.watch(diagramsWithProgressProvider(unit.id));

              // ## THE FIX: The new Gradient Banner design ##
              return Column(
                children: [
                  // This is the banner for the title
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                    decoration: BoxDecoration(
                      // Cycle through our predefined gradients
                      gradient: _unitGradients[index % _unitGradients.length],
                    ),
                    child: Text(
                      unit.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white, // White text for contrast
                        shadows: [
                          Shadow(blurRadius: 4, color: Colors.black.withOpacity(0.3))
                        ]
                      ),
                    ),
                  ),
                  // The carousel sits below the banner
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: diagramsAsync.when(
                      loading: () => SizedBox(height: 250.h, child: const AppLoadingIndicator()),
                      error: (e, st) => SizedBox(height: 250.h, child: Center(child: Text('لا يمكن تحميل الرسوم'))),
                      data: (diagramsWithProgress) {
                        int initialIndex = diagramsWithProgress.indexWhere(
                          (d) => d.progress == null || d.progress!.isCompleted == false,
                        );
                        if (initialIndex == -1) initialIndex = 0;

                        return DiagramsCarousel(
                          diagrams: diagramsWithProgress,
                          initialIndex: initialIndex,
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                ],
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