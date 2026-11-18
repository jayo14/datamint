import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
            content: Text('Wallet connected: ${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}'),
            backgroundColor: AppColors.mintPrimary,
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
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of DataMint?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final user = userAsync.value;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.mintPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.mintPrimary, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        (user?.displayName ?? user?.email ?? 'D').substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mintPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'DataMint User',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? 'user@datamint.ai',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.mintPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Reputation Score: ${(user?.reputationScore ?? 1.0).toStringAsFixed(1)} ★',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.mintPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Active Workspace Card
            const Text(
              'Active Workspace Mode',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    activeWorkspace == WorkspaceRole.contributor
                        ? Icons.volunteer_activism_rounded
                        : Icons.business_center_rounded,
                    color: activeWorkspace == WorkspaceRole.contributor
                        ? AppColors.mintPrimary
                        : AppColors.celoGold,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeWorkspace == WorkspaceRole.contributor
                              ? 'Contributor Workspace'
                              : 'Creator Workspace',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          activeWorkspace == WorkspaceRole.contributor
                              ? 'Browse tasks, submit multi-modal data, and claim cUSD.'
                              : 'Publish dataset campaigns, fund escrow, and review data.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  DataMintButton(
                    label: 'Switch',
                    isOutlined: true,
                    onPressed: () => ref.read(activeWorkspaceProvider.notifier).toggle(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Celo Wallet Card
            const Text(
              'Connected Celo Wallet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: walletState.isConnected
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.circle, color: AppColors.success, size: 10),
                                SizedBox(width: 6),
                                Text(
                                  'Celo Alfajores Testnet',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () => ref.read(walletStateProvider.notifier).disconnect(),
                              child: const Text('Disconnect', style: TextStyle(color: AppColors.error, fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          walletState.address ?? '0x...',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('cUSD Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${walletState.cusdBalance.toStringAsFixed(2)} cUSD',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('CELO Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${walletState.celoBalance.toStringAsFixed(4)} CELO',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text(
                          'No Celo Wallet Connected',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Connect your MiniPay, Valora, or Web3 wallet to sign vouchers and claim rewards.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        DataMintButton(
                          label: 'Connect Celo Wallet',
                          icon: Icons.link_rounded,
                          isLoading: _isConnectingWallet,
                          onPressed: _handleConnectWallet,
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            DataMintButton(
              label: 'Sign Out',
              icon: Icons.logout_rounded,
              color: AppColors.error,
              isOutlined: true,
              width: double.infinity,
              onPressed: _handleLogout,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
