import 'dart:math';
import 'package:anatomy_quiz_app/data/models/user_progress.dart';

class FeedbackMessages {
  static const List<String> _correctMale = ['أحسنت!', 'رائع!', 'عمل ممتاز!', 'إجابة صحيحة! ✔'];
  static const List<String> _correctFemale = ['أحسنتِ!', 'رائعة!', 'عمل ممتاز!', 'إجابة صحيحة! ✔'];
  static const List<String> _wrongMale = ['خطأ ✖', 'للأسف!', 'حاول مرة أخرى', 'ليست الإجابة الصحيحة'];
  static const List<String> _wrongFemale = ['خطأ ✖', 'للأسف!', 'حاولي مرة أخرى', 'ليست الإجابة الصحيحة'];

  static String getRandomMessage({required bool isCorrect, required Gender? gender}) {
    final random = Random();
    if (isCorrect) {
      if (gender == Gender.female) {
        return _correctFemale[random.nextInt(_correctFemale.length)];
      }
      // Default to male for null gender or male
      return _correctMale[random.nextInt(_correctMale.length)];
    } else {
      if (gender == Gender.female) {
        return _wrongFemale[random.nextInt(_wrongFemale.length)];
      }
      // Default to male for null gender or male
      return _wrongMale[random.nextInt(_wrongMale.length)];
    }
  }
}