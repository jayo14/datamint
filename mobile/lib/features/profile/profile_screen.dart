import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isConnectingWallet = false;

  Future<void> _handleConnectWallet() async {
    setState(() {
      _isConnectingWallet = true;
    });

    try {
      final walletNotifier = ref.read(walletStateProvider.notifier);
      final walletService = ref.read(walletServiceProvider);
      final addr = await walletService.connect();
      await walletNotifier.refreshBalances(addr);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Wallet connected: ${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}',
            ),
            backgroundColor: AppColors.mintActive,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connection failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnectingWallet = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Log Out',
          style: GoogleFonts.bricolageGrotesque(
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of DataMint?',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(currentUserProvider.notifier).logout();
      await ref.read(walletStateProvider.notifier).disconnect();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final walletState = ref.watch(walletStateProvider);
    final activeWorkspace = ref.watch(activeWorkspaceProvider);

    final user = userAsync.value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: AppColors.mintBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.05),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mintActive.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (user?.displayName ?? user?.email ?? 'D').substring(0, 1).toUpperCase(),
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'DataMint Contributor',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'user@datamint.ai',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: AppColors.mintBorder, width: 1),
                          ),
                          child: Text(
                            'Reputation Score: ${(user?.reputationScore ?? 1.0).toStringAsFixed(1)} ★',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.mintActive,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Active Workspace Card
            const Text(
              'Active Workspace Mode',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.mintBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      activeWorkspace == WorkspaceRole.contributor
                          ? Icons.volunteer_activism_rounded
                          : Icons.business_center_rounded,
                      color: activeWorkspace == WorkspaceRole.contributor
                          ? AppColors.mintActive
                          : AppColors.celoGold,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeWorkspace == WorkspaceRole.contributor
                              ? 'Contributor Mode'
                              : 'Creator Mode',
                          style: GoogleFonts.bricolageGrotesque(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeWorkspace == WorkspaceRole.contributor
                              ? 'Browse tasks, submit voice/image/text data, and earn cUSD.'
                              : 'Create campaigns, fund smart escrow, and review submissions.',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DataMintButton(
                    label: 'Switch',
                    isOutlined: true,
                    onPressed: () => ref.read(activeWorkspaceProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Celo Wallet Card
            const Text(
              'Connected Celo Wallet',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.mintBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ink.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: walletState.isConnected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.mintActive,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Celo Sepolia Connected',
                                  style: TextStyle(
                                    color: AppColors.mintActive,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh_rounded, size: 20),
                              color: AppColors.textMuted,
                              onPressed: () =>
                                  ref.read(walletStateProvider.notifier).refreshBalances(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          walletState.address ?? '0x...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: AppColors.ink,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Text(
                              '${walletState.cusdBalance.toStringAsFixed(2)} cUSD',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${walletState.celoBalance.toStringAsFixed(4)} CELO',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            icon: const Icon(Icons.link_off_rounded, size: 16),
                            label: const Text('Disconnect'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onPressed: () =>
                                ref.read(walletStateProvider.notifier).disconnect(),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'No Web3 wallet currently linked',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DataMintButton(
                          label: 'Connect Celo Wallet',
                          icon: Icons.account_balance_wallet_outlined,
                          isLoading: _isConnectingWallet,
                          onPressed: _handleConnectWallet,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 28),

            // Logout Action
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Log Out'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _handleLogout,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
