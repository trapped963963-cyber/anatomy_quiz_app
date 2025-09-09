import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/search_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagram_card.dart';
import 'package:anatomy_quiz_app/data/models/diagram_with_progress.dart';

class SearchScreen extends ConsumerWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResults = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        // The Search Bar
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ابحث هنا...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            // Update the search query provider as the user types
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
      ),
      body: searchQuery.isEmpty
          ? const Center(child: Text('ابدأ الكتابة للبحث.'))
          : searchResults.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('خطأ: $e')),
              data: (diagrams) {
                if (diagrams.isEmpty) {
                  return const Center(child: Text('لم يتم العثور على نتائج.'));
                }
                // Display the results as a simple vertical list of cards
                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: diagrams.length,
                  itemBuilder: (context, index) {
                    // We need to create a DiagramWithProgress object for the card
                    final diagramWithProgress = DiagramWithProgress(diagram: diagrams[index]);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: SizedBox(
                        height: 250.h,
                        child: DiagramCard(diagramWithProgress: diagramWithProgress),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}