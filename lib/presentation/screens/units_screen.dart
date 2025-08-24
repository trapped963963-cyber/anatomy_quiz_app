import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/learning_path_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagrams_carousel.dart';

class UnitsScreen extends ConsumerWidget {
  const UnitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unitsAsync = ref.watch(unitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('مسار التعلم')),
      body: unitsAsync.when(
        data: (units) {
          return ListView.builder(
            itemCount: units.length,
            itemBuilder: (context, index) {
              final unit = units[index];

              // Now, instead of getting a list directly, we get an AsyncValue
              // which can be in a loading, error, or data state.
              final diagramsAsync = ref.watch(diagramsWithProgressProvider(unit.id));

              return Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Text(
                        unit.title,
                        style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 12.h),

                    // We use .when() to build the correct UI for each state.
                    diagramsAsync.when(
                      // While loading, show a placeholder.
                      loading: () => SizedBox(
                        height: 250.h,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      // If there's an error, show an error message.
                      error: (e, st) => SizedBox(
                        height: 250.h,
                        child: Center(child: Text('لا يمكن تحميل الرسوم')),
                      ),
                      // Only when data is ready, we build the carousel.
                      data: (diagramsWithProgress) {
                        // The calculation and widget building now happens here.
                        int initialIndex = diagramsWithProgress.indexWhere(
                          (d) => d.progress == null || d.progress!.isCompleted == false
                        );
                        if (initialIndex == -1) {
                          initialIndex = 0;
                        }

                        return DiagramsCarousel(
                          diagrams: diagramsWithProgress,
                          initialIndex: initialIndex,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}