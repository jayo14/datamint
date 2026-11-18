import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/providers/app_providers.dart';
import '../campaigns/create_campaign_screen.dart';
import '../campaigns/my_campaigns_screen.dart';
import '../marketplace/marketplace_screen.dart';
import '../profile/profile_screen.dart';
import '../reviews/review_queue_screen.dart';
import '../rewards/rewards_screen.dart';
import '../submissions/my_submissions_screen.dart';

class HomeScaffold extends ConsumerStatefulWidget {
  const HomeScaffold({super.key});

  @override
  ConsumerState<HomeScaffold> createState() => _HomeScaffoldState();
}

class _HomeScaffoldState extends ConsumerState<HomeScaffold> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final activeWorkspace = ref.watch(activeWorkspaceProvider);
    final walletState = ref.watch(walletStateProvider);
    final unreadCountAsync = ref.watch(unreadNotificationsCountProvider);

    final isContributor = activeWorkspace == WorkspaceRole.contributor;

    final List<Widget> pages = isContributor
        ? const [
            MarketplaceScreen(),
            MySubmissionsScreen(),
            RewardsScreen(),
            ProfileScreen(),
          ]
        : const [
            MyCampaignsScreen(),
            CreateCampaignScreen(),
            ReviewQueueScreen(),
            ProfileScreen(),
          ];

    final List<BottomNavigationBarItem> navItems = isContributor
        ? const [
            BottomNavigationBarItem(
              icon: Icon(Icons.storefront_rounded),
              label: 'Explore',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_turned_in_rounded),
              label: 'Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Rewards',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ]
        : const [
            BottomNavigationBarItem(
              icon: Icon(Icons.campaign_rounded),
              label: 'Campaigns',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_rounded),
              label: 'Reviews',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            // Logo
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.mintPrimary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.token_rounded,
                color: AppColors.mintPrimary,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'DataMint',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const Spacer(),
            // Workspace Switcher Pill
            GestureDetector(
              onTap: () {
                setState(() {
                  _currentTabIndex = 0; // reset tab index on switch
                });
                ref.read(activeWorkspaceProvider.notifier).toggle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isContributor ? AppColors.mintPrimary : AppColors.celoGold,
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isContributor
                          ? Icons.volunteer_activism_rounded
                          : Icons.business_center_rounded,
                      size: 14,
                      color: isContributor ? AppColors.mintPrimary : AppColors.celoGold,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isContributor ? 'Contributor' : 'Creator',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isContributor ? AppColors.mintPrimary : AppColors.celoGold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.sync_alt_rounded, size: 12, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Wallet Status Chip
          if (walletState.isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.celoGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: AppColors.celoGold, size: 8),
                      const SizedBox(width: 4),
                      Text(
                        '${walletState.cusdBalance.toStringAsFixed(1)} cUSD',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.celoGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          // Notification Bell
          IconButton(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 24),
                unreadCountAsync.maybeWhen(
                  data: (count) => count > 0
                      ? Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                  orElse: () => const SizedBox.shrink(),
                ),
              ],
            ),
            onPressed: () => context.push('/notifications'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        onTap: (index) => setState(() => _currentTabIndex = index),
        type: BottomNavigationBarStyle.fixed,
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        selectedItemColor: isContributor ? AppColors.mintPrimary : AppColors.celoGold,
        unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 11),
        items: navItems,
      ),
    );
  }
}
