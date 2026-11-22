import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
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

    final navItems = isContributor
        ? [
            _NavItemData(icon: Icons.storefront_rounded, label: 'Explore'),
            _NavItemData(icon: Icons.assignment_turned_in_rounded, label: 'Tasks'),
            _NavItemData(icon: Icons.account_balance_wallet_rounded, label: 'Rewards'),
            _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
          ]
        : [
            _NavItemData(icon: Icons.campaign_rounded, label: 'Campaigns'),
            _NavItemData(icon: Icons.add_circle_outline_rounded, label: 'Create'),
            _NavItemData(icon: Icons.rate_review_rounded, label: 'Reviews'),
            _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
          ];

    return Scaffold(
      backgroundColor: AppColors.mintBg,
      appBar: AppBar(
        titleSpacing: 16,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            const DataMintLogo(size: 30),
            const Spacer(),

            // Role Switcher Pill
            GestureDetector(
              onTap: () {
                setState(() => _currentTabIndex = 0);
                ref.read(activeWorkspaceProvider.notifier).toggle();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.mintBorder,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isContributor ? AppColors.mintActive : AppColors.celoGold,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isContributor ? 'Contributor' : 'Creator',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.sync_alt_rounded,
                      size: 13,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Celo Wallet Balance Pill
          if (walletState.isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.mintBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: AppColors.celoGold, size: 8),
                      const SizedBox(width: 5),
                      Text(
                        '${walletState.cusdBalance.toStringAsFixed(1)} cUSD',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.ink,
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
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: AppColors.ink,
                ),
                unreadCountAsync.maybeWhen(
                  data: (count) => count > 0
                      ? Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.mintActive,
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
      body: Stack(
        children: [
          // Ambient blurred background coin glows
          const Positioned(
            top: -50,
            left: -50,
            child: FloatingCoinGlow(
              size: 200,
              color: AppColors.mint,
              opacity: 0.35,
            ),
          ),
          const Positioned(
            bottom: 40,
            right: -40,
            child: FloatingCoinGlow(
              size: 220,
              color: AppColors.yellowAccent,
              opacity: 0.25,
            ),
          ),

          IndexedStack(
            index: _currentTabIndex,
            children: pages,
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: const Border(
            top: BorderSide(
              color: AppColors.mintBorder,
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (idx) {
              final isSelected = _currentTabIndex == idx;
              final item = navItems[idx];

              return GestureDetector(
                onTap: () => setState(() => _currentTabIndex = idx),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.mint.withValues(alpha: 0.25) : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: isSelected ? AppColors.mintActive : AppColors.textMuted,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: GoogleFonts.bricolageGrotesque(
                          color: isSelected ? AppColors.ink : AppColors.textMuted,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}
