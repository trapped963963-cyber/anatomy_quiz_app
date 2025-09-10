import 'package:go_router/go_router.dart';
import 'package:anatomy_quiz_app/presentation/screens/screens.dart';
import 'package:anatomy_quiz_app/data/models/models.dart';
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
            onReviewCompleted: () {
              context.pushReplacement('/step-complete/${extra['levelId']}/${extra['stepNumber']}');
            },
            onExit: () {
              context.go('/home');
              context.push('/level/${extra['levelId']}');
            },
          );
        },
      ),
      GoRoute(
        path: '/units',
        builder: (context, state) => const UnitsScreen(),
      ),
      GoRoute(
        path: '/quiz/difficulty',
        builder: (context, state) => const QuizDifficultySelectionScreen(),
      ),
      GoRoute(
        path: '/quiz/in-progress',
        builder: (context, state) => const QuizInProgressScreen(),
      ),
      GoRoute(
        path: '/quiz/select-content',
        builder: (context, state) => const QuizContentSelectionScreen(),
      ),
      GoRoute(
        path: '/quiz/end',
        builder: (context, state) => const QuizEndScreen(),
      ),
      GoRoute(
        path: '/quiz/review',
        builder: (context, state) {
          final questions = state.extra as List<Question>;
          return ReviewStepScreen(
            questionsToReview: questions,
            onReviewCompleted: () {
              context.go('/quiz/review-end');
            },
            onExit: () {
              context.pop();
            },
          );
        },
      ),
      GoRoute(
        path: '/quiz/review-end',
        builder: (context, state) => const ReviewEndScreen(),
      ),
      GoRoute(
        path: '/step-complete/:levelId/:stepNumber',
        builder: (context, state) {
          final levelId = int.parse(state.pathParameters['levelId']!);
          final stepNumber = int.parse(state.pathParameters['stepNumber']!);
          return StepCompleteScreen(levelId: levelId, stepNumber: stepNumber);
        },
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      GoRoute(
        path: '/challenge-end',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ChallengeEndScreen(
            levelId: extra['levelId'],
            incorrectAnswers: extra['incorrectAnswers'],
            totalQuestions: extra['totalQuestions'],
          );
        },
      ),
    ],
  );
}