import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/auth_screens.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/register_screen.dart';
import '../features/home/home_scaffold.dart';
import '../features/marketplace/campaign_detail_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/submissions/submission_detail_screen.dart';
import '../features/submissions/submission_editor_screen.dart';
import '../shared/models/models.dart';
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
      // Legacy / Aliases
      GoRoute(
        path: '/login',
        builder: (context, state) => const AuthWelcomeScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const AuthPhoneScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScaffold(),
      ),
      GoRoute(
        path: '/marketplace/:id',
        builder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final campaign = state.extra as CampaignModel?;
          return CampaignDetailScreen(
            campaignId: campaignId,
            campaign: campaign,
          );
        },
      ),
      GoRoute(
        path: '/submit/:id',
        builder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final campaign = state.extra as CampaignModel?;
          return SubmissionEditorScreen(
            campaignId: campaignId,
            campaign: campaign,
          );
        },
      ),
      GoRoute(
        path: '/submissions/:id',
        builder: (context, state) {
          final submissionId = state.pathParameters['id']!;
          final submission = state.extra as SubmissionModel?;
          return SubmissionDetailScreen(
            submissionId: submissionId,
            submission: submission,
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
    ],
  );
});
