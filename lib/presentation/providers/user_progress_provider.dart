import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
import 'package:anatomy_quiz_app/presentation/providers/database_provider.dart';


class UserProgressNotifier extends StateNotifier<UserProgress> {
  final Ref _ref;

  UserProgressNotifier(this._ref) : super(const UserProgress.initial());

  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final dbHelper = _ref.read(databaseHelperProvider);
    
    final userName = prefs.getString('userName');
    final genderString = prefs.getString('userGender');
    final lastActiveLevelId = prefs.getInt('lastActiveLevelId') ?? 1;
    final lastActiveLevelTitle = prefs.getString('lastActiveLevelTitle');
    final levelStats = await dbHelper.getAllLevelStats();

    state = UserProgress(
      userName: userName,
      gender: genderString,
      levelStats: levelStats,
      lastActiveLevelId: lastActiveLevelId,
      lastActiveLevelTitle: lastActiveLevelTitle,

    );
  }

  Future<void> setLastActiveLevel(int levelId,  String title) async {

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastActiveLevelId', levelId);
    await prefs.setString('lastActiveLevelTitle', title);
    state = state.copyWith(lastActiveLevelId: levelId,lastActiveLevelTitle: title);
  }

  // Method to save user's name
  Future<void> setUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    state = state.copyWith(userName: name);
  }

  Future<void> setGender(Gender gender) async {
    final prefs = await SharedPreferences.getInstance();
    final genderString = gender == Gender.male ? 'ذكر' : 'أنثى';
    await prefs.setString('userGender', genderString);
    state = state.copyWith(gender: genderString);
  }


  Future<void> completeStep(int levelId, int stepNumber) async {
    final dbHelper = _ref.read(databaseHelperProvider);
    final currentCompleted = state.levelStats[levelId]?.completedSteps ?? 0;
    // If we are replaying a step we've already completed, do nothing.
    if (stepNumber <= currentCompleted) {
      return;
    }

    final totalStepsInLevel = await dbHelper.getLabelsCountForDiagram(levelId);

    
    final newStat = LevelStat(
      levelId: levelId,
      completedSteps: stepNumber,
      isCompleted: stepNumber == totalStepsInLevel,
      lastVisited: DateTime.now(),
    );

    await dbHelper.updateLevelStat(newStat);

    final updatedStats = Map<int, LevelStat>.from(state.levelStats);
    updatedStats[levelId] = newStat;
    state = state.copyWith(levelStats: updatedStats);
  }
}


// Finally, we create the provider that the UI will interact with.
final userProgressProvider = StateNotifierProvider<UserProgressNotifier, UserProgress>((ref) {
  return UserProgressNotifier(ref);
});