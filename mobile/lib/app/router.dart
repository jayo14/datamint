import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_screens.dart';
import '../features/home/home_scaffold.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/offline/offline_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/task_flow/photo_screens.dart';
import '../features/task_flow/text_task_screen.dart';
import '../features/task_flow/validation_screens.dart';
import '../features/task_flow/voice_screens.dart';
import '../features/tasks/task_detail_screen.dart';
import '../features/tasks/tasks_empty_screen.dart';
import '../features/wallet/history_screen.dart';
import '../features/wallet/receipt_screen.dart';
import '../features/wallet/withdraw_screens.dart';
import '../shared/providers/app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (BuildContext context, GoRouterState state) {
      if (currentUserAsync.isLoading) return null;

      final isAuthenticated = currentUserAsync.value != null;
      final isSplash = state.matchedLocation == '/splash';
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding';

      if (isSplash) return null;

      if (!isAuthenticated && !isAuthRoute) {
        return '/auth/welcome';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // Auth Flow Routes
      GoRoute(
        path: '/auth/welcome',
        builder: (context, state) => const AuthWelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/phone',
        builder: (context, state) => const AuthPhoneScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (context, state) => const AuthOtpScreen(),
      ),
      GoRoute(
        path: '/auth/profile',
        builder: (context, state) => const AuthProfileScreen(),
      ),
      GoRoute(
        path: '/auth/permissions',
        builder: (context, state) => const AuthPermissionsScreen(),
      ),
      GoRoute(
        path: '/auth/success',
        builder: (context, state) => const AuthSuccessScreen(),
      ),
      // Main App Scaffold (Tabs: Home, Tasks, Wallet, Profile)
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScaffold(),
      ),
      // Tasks Flow
      GoRoute(
        path: '/tasks/detail',
        builder: (context, state) => const TaskDetailScreen(),
      ),
      GoRoute(
        path: '/tasks/empty',
        builder: (context, state) => const TasksEmptyScreen(),
      ),
      GoRoute(
        path: '/tasks/voice/ready',
        builder: (context, state) => const VoiceReadyScreen(),
      ),
      GoRoute(
        path: '/tasks/voice/recording',
        builder: (context, state) => const VoiceRecordingScreen(),
      ),
      GoRoute(
        path: '/tasks/voice/review',
        builder: (context, state) => const VoiceReviewScreen(),
      ),
      GoRoute(
        path: '/tasks/photo/capture',
        builder: (context, state) => const PhotoCaptureScreen(),
      ),
      GoRoute(
        path: '/tasks/photo/review',
        builder: (context, state) => const PhotoReviewScreen(),
      ),
      GoRoute(
        path: '/tasks/text',
        builder: (context, state) => const TextTaskScreen(),
      ),
      GoRoute(
        path: '/tasks/validating',
        builder: (context, state) => const ValidatingScreen(),
      ),
      GoRoute(
        path: '/tasks/paid',
        builder: (context, state) => const TaskPaidScreen(),
      ),
      GoRoute(
        path: '/tasks/rejected',
        builder: (context, state) => const TaskRejectedScreen(),
      ),
      // Wallet Flow
      GoRoute(
        path: '/withdraw/amount',
        builder: (context, state) => const WithdrawAmountScreen(),
      ),
      GoRoute(
        path: '/withdraw/review',
        builder: (context, state) {
          final amount = state.extra as double? ?? 10.0;
          return WithdrawReviewScreen(amount: amount);
        },
      ),
      GoRoute(
        path: '/withdraw/sent',
        builder: (context, state) {
          final amount = state.extra as double? ?? 10.0;
          return WithdrawSentScreen(amount: amount);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/receipt',
        builder: (context, state) => const ReceiptScreen(),
      ),
      // Settings & Notifications & Offline
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/offline',
        builder: (context, state) => const OfflineScreen(),
      ),
    ],
  );
});
