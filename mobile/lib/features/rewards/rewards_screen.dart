import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';
import '../submissions/my_submissions_screen.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen> {
  final Map<String, bool> _claimingMap = {};

  Future<void> _handleClaim(SubmissionModel submission) async {
    setState(() => _claimingMap[submission.id] = true);

    try {
      final payoutService = ref.read(payoutServiceProvider);
      final walletService = ref.read(walletServiceProvider);

      // 1. Fetch EIP-712 payout voucher
      final voucher = await payoutService.getVoucher(submission.id);

      // 2. Broadcast claim transaction via Celo wallet
      final txHash = await walletService.claimRewardOnChain(voucher);

      // 3. Confirm claim on backend
      await payoutService.recordClaimOnChain(
        submissionId: submission.id,
        claimTxHash: txHash,
      );

      // 4. Refresh submissions and wallet balances
      ref.invalidate(mySubmissionsProvider);
      ref.read(walletStateProvider.notifier).refreshBalances();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward claimed successfully on Celo!'),
            backgroundColor: AppColors.mintPrimary,
          ),
        );
      }
    } on AppException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Claim failed: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _claimingMap[submission.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(mySubmissionsProvider);
    final walletState = ref.watch(walletStateProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mySubmissionsProvider);
          await ref.read(walletStateProvider.notifier).refreshBalances();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF064E3B), const Color(0xFF0F172A)]
                        : [const Color(0xFFD1FAE5), const Color(0xFFECFDF5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.mintPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Celo Wallet Balance',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.celoGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.link_rounded, size: 12, color: AppColors.celoGold),
                              SizedBox(width: 4),
                              Text(
                                'Celo Alfajores',
                                style: TextStyle(
                                  color: AppColors.celoGold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${walletState.cusdBalance.toStringAsFixed(2)} cUSD',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.mintPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${walletState.celoBalance.toStringAsFixed(4)} CELO',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Ready to Claim',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text(
                'Verified submissions with signed EIP-712 payout vouchers',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              submissionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                error: (err, _) => EmptyStateView(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to Load Rewards',
                  message: err.toString(),
                ),
                data: (submissions) {
                  final claimable = submissions.where((s) => s.canClaim).toList();

                  if (claimable.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 40, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            'All Caught Up!',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'No pending unclaimed rewards at this time.',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: claimable.map((item) {
                      final isClaiming = _claimingMap[item.id] ?? false;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.mintPrimary.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.verified_rounded,
                                  color: AppColors.mintPrimary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Submission #${item.id.length > 8 ? item.id.substring(0, 8) : item.id}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '+${item.rewardAmount?.toStringAsFixed(2) ?? "0.00"} cUSD',
                                      style: const TextStyle(
                                        color: AppColors.mintPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              DataMintButton(
                                label: 'Claim',
                                icon: Icons.arrow_downward_rounded,
                                isLoading: isClaiming,
                                onPressed: () => _handleClaim(item),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              const Text(
                'Settled Payouts History',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 12),

              submissionsAsync.maybeWhen(
                data: (submissions) {
                  final settled = submissions
                      .where((s) => s.claimTxHash != null && s.claimTxHash!.isNotEmpty)
                      .toList();

                  if (settled.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No on-chain settled payouts yet.',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: settled.map((item) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_rounded, color: AppColors.success),
                          title: Text(
                            '+${item.rewardAmount?.toStringAsFixed(2) ?? ""} cUSD',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            item.claimTxHash!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Text(
                            'Settled',
                            style: TextStyle(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
