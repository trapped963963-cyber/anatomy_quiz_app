import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:anatomy_quiz_app/presentation/theme/app_colors.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:anatomy_quiz_app/core/routing/app_router.dart';




void main() {
  // Ensure that widgets are initialized before running the app
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    // ProviderScope is what makes Riverpod work
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ScreenUtilInit is for making the UI responsive
    return ScreenUtilInit(
      designSize: const Size(375, 812), // iPhone X design size as a baseline
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'اختبر معلوماتك في علم التشريح', // Anatomy Quiz App
          debugShowCheckedModeBanner: false,
          
          // --- Forcing Arabic Language and RTL Layout ---
          locale: const Locale('ar', ''),
          supportedLocales: const [
            Locale('ar', ''),
          ],
          localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
          ],
          // --- App Theme ---
          theme: ThemeData(
            primaryColor: AppColors.primary,
            scaffoldBackgroundColor: AppColors.background,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.primary,
              background: AppColors.background,
              surface: AppColors.surface,
            ),
            textTheme: GoogleFonts.cairoTextTheme(Theme.of(context).textTheme).apply(
              bodyColor: AppColors.textPrimary,
              displayColor: AppColors.textPrimary,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
              ),
            ),
            useMaterial3: true,
          ),

          // --- Navigation ---
          routerConfig: AppRouter.router, 
          
          // This builder ensures that the entire app is wrapped in a Directionality
          // widget, forcing RTL layout.
          builder: (context, widget) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: widget!,
            );
          },
        );
      },
    );
  }
}


// A temporary placeholder screen to make sure the app runs
class PlaceholderHomeScreen extends StatelessWidget {
  const PlaceholderHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التطبيق قيد الإنشاء'),
      ),
      body: Center(
        child: Text(
          'أهلاً بك في تطبيق اختبار التشريح!',
          style: TextStyle(fontSize: 24.sp),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}