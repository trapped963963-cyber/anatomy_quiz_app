import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:anatomy_quiz_app/presentation/providers/search_provider.dart';
import 'package:anatomy_quiz_app/presentation/widgets/path/diagram_card.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';

// ## FIX 1: Convert to a ConsumerStatefulWidget ##
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

// Inside your _SearchScreenState class...

@override
void dispose() {
  // ## THE FIX: Hide the keyboard to prevent overflow on the MainScreen ##
  _focusNode.unfocus();

  // We no longer need to reset the provider here, as it's handled by the MainScreen.

  _searchController.dispose();
  _focusNode.dispose();
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'ابحث عن رسم بياني...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
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
                return ListView.builder(
                  padding: EdgeInsets.all(16.w),
                  itemCount: diagrams.length,
                  itemBuilder: (context, index) {
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