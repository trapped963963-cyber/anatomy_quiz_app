import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/custom_quiz_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/learning_path_provider.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';


class QuizContentSelectionScreen extends ConsumerStatefulWidget {
  const QuizContentSelectionScreen({super.key});

  @override
  ConsumerState<QuizContentSelectionScreen> createState() =>
      _QuizContentSelectionScreenState();
}

class _QuizContentSelectionScreenState extends ConsumerState<QuizContentSelectionScreen> {
  late Set<int> _selectedDiagramIds;
  final Set<int> _expandedUnitIds = {};

  @override
  void initState() {
    super.initState();
    _selectedDiagramIds = Set<int>.from(ref.read(customQuizConfigProvider).selectedDiagramIds);
  }

  @override
  Widget build(BuildContext context) {
    final unitsAsync = ref.watch(unitsProvider);
    final allCompletedDiagrams = ref.watch(userProgressProvider)
        .levelStats.values
        .where((stat) => stat.isCompleted)
        .map((stat) => stat.levelId)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('اختيار محتوى الاختبار'),
      ),
      body: unitsAsync.when(
        data: (units) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.all(8.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedDiagramIds = allCompletedDiagrams;
                        });
                      },
                      child: const Text('تحديد كل المكتمل'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade300, foregroundColor: Colors.black),
                      onPressed: () {
                        setState(() {
                          _selectedDiagramIds.clear();
                        });
                      },
                      child: const Text('إلغاء الكل'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: units.length,
                  itemBuilder: (context, index) {
                    final unit = units[index];
                    return _buildUnitSection(unit);
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _selectedDiagramIds.isNotEmpty
            ? () {
                ref.read(customQuizConfigProvider.notifier).setDiagrams(_selectedDiagramIds);
                context.push('/quiz/difficulty');
              }
            : null,
        label: const Text('التالي'),
        icon: const Icon(Icons.arrow_forward_ios),
        backgroundColor: _selectedDiagramIds.isNotEmpty ? AppColors.accent : Colors.grey,
      ),
    );
  }

  // ## NEW: This method now uses an ExpansionTile ##
  Widget _buildUnitSection(Unit unit) {
    final diagramsAsync = ref.watch(diagramsWithProgressProvider(unit.id));

    return diagramsAsync.when(
      loading: () => const SizedBox.shrink(), // Don't show anything while loading diagrams
      error: (e, st) => const SizedBox.shrink(),
      data: (diagramsWithProgress) {
        if (diagramsWithProgress.isEmpty) return const SizedBox.shrink();

        final diagramIdsInUnit = diagramsWithProgress.map((d) => d.diagram.id).toSet();
        final isAllSelected = diagramIdsInUnit.isNotEmpty && _selectedDiagramIds.containsAll(diagramIdsInUnit);

        return Card(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            key: PageStorageKey(unit.id), // Helps remember the expanded state
            title: Row(
              children: [
                Expanded(
                  child: Text(unit.title, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
                ),
                  GestureDetector(
                    // This onTap performs the same logic as the Checkbox
                    onTap: () {
                      setState(() {
                        // We manually toggle the state
                        if (isAllSelected) {
                          _selectedDiagramIds.removeAll(diagramIdsInUnit);
                        } else {
                          _selectedDiagramIds.addAll(diagramIdsInUnit);
                        }
                      });
                    },
                    // Use a Row to group the text and checkbox visually
                    child: Row(
                      mainAxisSize: MainAxisSize.min, // Prevents the Row from taking extra space
                      children: [
                        Text('تحديد الكل', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600)),
                        // The Checkbox's onChanged is now simpler, as the main logic is in the GestureDetector
                        Checkbox(
                          value: isAllSelected,
                          onChanged: (value) {
                            setState(() {
                              if (value == true) {
                                _selectedDiagramIds.addAll(diagramIdsInUnit);
                              } else {
                                _selectedDiagramIds.removeAll(diagramIdsInUnit);
                              }
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            children: diagramsWithProgress.map((dwp) {
              final isCompleted = dwp.progress?.isCompleted ?? false;
              final isSelected = _selectedDiagramIds.contains(dwp.diagram.id);
              return CheckboxListTile(
                // ## NEW: Use tileColor for completed status ##
                tileColor: isCompleted ? AppColors.correct.withOpacity(0.1) : null,
                title: Text(dwp.diagram.title),
                value: isSelected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedDiagramIds.add(dwp.diagram.id);
                    } else {
                      _selectedDiagramIds.remove(dwp.diagram.id);
                    }
                  });
                },
                activeColor: AppColors.primary,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

