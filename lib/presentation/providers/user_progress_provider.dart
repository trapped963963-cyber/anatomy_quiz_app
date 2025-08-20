import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';

// This Notifier will be the single source of truth for user progress
class UserProgressNotifier extends StateNotifier<UserProgress> {
  final Ref _ref;

  UserProgressNotifier(this._ref) : super(const UserProgress.initial());

  // Method to load the initial user data from device storage
  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final dbHelper = _ref.read(databaseHelperProvider);
    
    final userName = prefs.getString('userName');
    final currentLevelId = prefs.getInt('currentLevelId') ?? 1;
    final currentStepInLevel = prefs.getInt('currentStepInLevel') ?? 1;

    // Load all level statistics from the database
    final levelStats = await dbHelper.getAllLevelStats();

    state = UserProgress(
      userName: userName,
      currentLevelId: currentLevelId,
      currentStepInLevel: currentStepInLevel,
      levelStats: levelStats,
    );
  }

  // Method to save user's name
  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    state = state.copyWith(userName: name);
  }


  // Method to be called when a user completes a step
  Future<void> completeStep(int levelId, int stepNumber) async {
    
    // --- START: New Progress Protection Logic ---
    // First, check if this step is already marked as complete in our state.
    final bool isAlreadyCompleted = levelId < state.currentLevelId || (levelId == state.currentLevelId && stepNumber < state.currentStepInLevel);

    // If it's already done, do nothing and exit immediately.
    if (isAlreadyCompleted) {
      return; 
    }
    // --- END: New Progress Protection Logic ---


    
    
    final dbHelper = _ref.read(databaseHelperProvider);
    final prefs = await SharedPreferences.getInstance();

    // Fetch the total steps dynamically right here!
    final totalStepsInLevel = await dbHelper.getLabelsCountForDiagram(levelId);

    // Logic for advancing to the next step or level
    if (stepNumber < totalStepsInLevel) {
      // Advance to the next step in the same level
      await prefs.setInt('currentStepInLevel', stepNumber + 1);
      state = state.copyWith(currentStepInLevel: stepNumber + 1);
    } else {
      // Completed the level, advance to the next one
      await prefs.setInt('currentLevelId', levelId + 1);
      await prefs.setInt('currentStepInLevel', 1);
      state = state.copyWith(
        currentLevelId: levelId + 1,
        currentStepInLevel: 1,
      );
    }
    
    // Update the statistics for the completed level
    final newStat = LevelStat(
      levelId: levelId,
      completedSteps: stepNumber,
      isCompleted: stepNumber == totalStepsInLevel,
      lastVisited: DateTime.now(),
    );

    await dbHelper.updateLevelStat(newStat);

    // Update the state in memory
    final updatedStats = Map<int, LevelStat>.from(state.levelStats);
    updatedStats[levelId] = newStat;
    state = state.copyWith(levelStats: updatedStats);
  }
}


// Finally, we create the provider that the UI will interact with.
final userProgressProvider = StateNotifierProvider<UserProgressNotifier, UserProgress>((ref) {
  return UserProgressNotifier(ref);
});