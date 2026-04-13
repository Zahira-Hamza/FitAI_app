import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/auth/forgot_password_screen.dart';
import '../../presentation/screens/profile_setup/profile_setup_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/workouts/workout_browser_screen.dart';
import '../../presentation/screens/workouts/workout_detail_screen.dart';
import '../../presentation/screens/active_workout/active_workout_screen.dart';
import '../../presentation/screens/active_workout/rest_timer_screen.dart';
import '../../presentation/screens/workout_complete/workout_complete_screen.dart';
import '../../presentation/screens/ai_coach/ai_coach_screen.dart';
import '../../presentation/screens/progress/progress_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (_, __) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (_, __) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (_, __) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (_, __) => const SignupScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (_, __) => const ProfileSetupScreen(),
    ),
    // ── Main shell (bottom nav screens) ──────────────────────
    GoRoute(
      path: '/home',
      builder: (_, __) => const HomeScreen(),
    ),
    GoRoute(
      path: '/workouts',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final category = extra?['category'] as String?;
        return WorkoutBrowserScreen(initialCategory: category);
      },
    ),
    GoRoute(
      path: '/workout-detail/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return WorkoutDetailScreen(workoutId: id, extra: extra);
      },
    ),
    GoRoute(
      path: '/ai-coach',
      builder: (_, __) => const AiCoachScreen(),
    ),
    GoRoute(
      path: '/progress',
      builder: (_, __) => const ProgressScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (_, __) => const ProfileScreen(),
    ),
    // ── Fullscreen flows (no bottom nav) ──────────────────────
    GoRoute(
      path: '/active-workout',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ActiveWorkoutScreen(workoutData: extra);
      },
    ),
    GoRoute(
      path: '/rest-timer',
      builder: (_, __) => const RestTimerScreen(),
    ),
    GoRoute(
      path: '/workout-complete',
      builder: (_, __) => const WorkoutCompleteScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    backgroundColor: const Color(0xFF12121D),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6584), size: 48),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: const TextStyle(
              fontFamily: 'SpaceGrotesk',
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/home'),
            child: const Text('Go Home',
                style: TextStyle(color: Color(0xFFC4C0FF))),
          ),
        ],
      ),
    ),
  ),
);
