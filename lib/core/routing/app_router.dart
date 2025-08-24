import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/screens/screens.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/', // Start at the splash screen
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(), // New initial route
      ),
      // Activation Flow
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/name',
        builder: (context, state) => const NameInputScreen(),
      ),
      GoRoute(
        path: '/phone',
        builder: (context, state) => const PhoneInputScreen(),
      ),
      GoRoute(
        path: '/promo',
        builder: (context, state) => const PromoCodeScreen(),
      ),
      GoRoute(
        path: '/contact',
        builder: (context, state) => const ContactAdminScreen(),
      ),
      GoRoute(
        path: '/activate',
        builder: (context, state) => const ActivationCodeScreen(),
      ),

      // Main Content Flow
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScreen(),
      ),
      GoRoute(
        path: '/path',
        builder: (context, state) => const PathScreen(),
      ),
      GoRoute(
          path: '/level/:levelId',
          builder: (context, state) {
          final levelId = int.parse(state.pathParameters['levelId']!);
          return LevelScreen(levelId: levelId);
          },
      ),
      GoRoute(
          path: '/step/:levelId/:stepNumber',
          builder: (context, state) {
          final levelId = int.parse(state.pathParameters['levelId']!);
          final stepNumber = int.parse(state.pathParameters['stepNumber']!);
          return StepScreen(levelId: levelId, stepNumber: stepNumber);
          },
      ),
      GoRoute(
          path: '/step-end',
          builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return StepEndScreen(
              levelId: extra['levelId'],
              stepNumber: extra['stepNumber'],
              totalCorrect: extra['totalCorrect'],
              totalWrong: extra['totalWrong'],
              wronglyAnswered: extra['wronglyAnswered'],
              );
          },
      ),
      GoRoute(
        path: '/review',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ReviewStepScreen(
            questionsToReview: extra['questions'],
            levelId: extra['levelId'],
            stepNumber: extra['stepNumber'],
          );
        },
      ),
      GoRoute(
        path: '/final-matching/:levelId/:stepNumber',
        builder: (context, state) {
          final levelId = int.parse(state.pathParameters['levelId']!);
          final stepNumber = int.parse(state.pathParameters['stepNumber']!);
          return FinalMatchingScreen(
            levelId: levelId,
            stepNumber: stepNumber,
          );
        },
      ),
      GoRoute(
        path: '/units',
        builder: (context, state) => const UnitsScreen(),
      ),
    ],
  );
}