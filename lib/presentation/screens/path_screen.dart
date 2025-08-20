import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';
import 'package:anatomy_quiz_app/presentation/providers/user_progress_provider.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// A new provider to fetch the diagrams just once
final diagramsProvider = FutureProvider<List<AnatomicalDiagram>>((ref) async {
  final dbHelper = ref.read(databaseHelperProvider);
  return dbHelper.getDiagrams();
});

class PathScreen extends ConsumerWidget {
  const PathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diagramsAsyncValue = ref.watch(diagramsProvider);
    final userProgress = ref.watch(userProgressProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('مسار التعلم'),
      ),
      body: diagramsAsyncValue.when(
        data: (diagrams) {
          return ListView.builder(
            padding: EdgeInsets.all(16.w),
            itemCount: diagrams.length,
            itemBuilder: (context, index) {
              final diagram = diagrams[index];
              final levelId = diagram.id;
              
              bool isLocked = levelId > userProgress.currentLevelId;
              bool isCompleted = userProgress.levelStats[levelId]?.isCompleted ?? false;
              bool isInProgress = levelId == userProgress.currentLevelId;

              return Card(
                elevation: isLocked ? 0 : 4,
                color: isLocked ? Colors.grey.shade200 : AppColors.surface,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCompleted ? AppColors.completed : (isInProgress ? AppColors.inProgress : AppColors.locked),
                    child: Icon(
                      isLocked ? Icons.lock : (isCompleted ? Icons.check : Icons.edit),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    diagram.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isLocked ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: isLocked ? const Text('مغلق') : (isCompleted ? const Text('مكتمل') : const Text('قيد التقدم')),
                  enabled: !isLocked,
                  onTap: () {
                    if (!isLocked) {
                      context.go('/level/${diagram.id}');
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }
}