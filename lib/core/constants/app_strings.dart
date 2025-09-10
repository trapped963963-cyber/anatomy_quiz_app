// lib/core/constants/app_strings.dart

class AppStrings {
  // Prevent this class from being instantiated.
  AppStrings._();

  // main.dart
  static const String appName = 'اختبر معلوماتك في علم التشريح';
  
  //splash_screen
  static const String loadingMessage = 'انتظر من فضلك...';
  static const String unAbleToFindDbMessage = 'حدث خطأما, قد تكون هذه النسخة من التطبيق تالفةيرجى تحميل اخر اصدار من الرابط التالي';

   static String askForTitle(int number) {
    return 'ما هو اسم الجزء رقم $number؟';
  }

  static String askForNumber(String title) {
    return 'ما هو رقم الجزء "$title"؟';
  }

  static String askFromDef(String definition) {
    return '"$definition"';
  }

  static String askToWriteTitle(int number) {
    return 'اكتب اسم الجزء رقم $number';
  }

  static String matchingChallenge() {
    return 'اختر الرقم من الأعلى والمسمى المطابق من الأسفل';
  }
  
  static String askToWriteTitleWithContext(int number, String blankedTitle) {
    return 'أكمل اسم الجزء رقم $number:\n"$blankedTitle"';
  }

}