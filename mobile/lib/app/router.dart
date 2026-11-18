import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/authentication/login_screen.dart';
import '../features/authentication/register_screen.dart';
import '../features/home/home_scaffold.dart';
import '../features/marketplace/campaign_detail_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/submissions/submission_detail_screen.dart';
import '../features/submissions/submission_editor_screen.dart';
import '../shared/models/models.dart';
import '../shared/providers/app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final currentUserAsync = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (BuildContext context, GoRouterState state) {
      // If user state is still loading initial session check, do not redirect
      if (currentUserAsync.isLoading) return null;

      final isAuthenticated = currentUserAsync.value != null;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/onboarding';

      if (!isAuthenticated && !isAuthRoute) {
        return '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
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
