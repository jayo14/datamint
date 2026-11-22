import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
            backgroundColor: AppColors.mintActive,
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.mintActive,
        onRefresh: () async {
          ref.invalidate(mySubmissionsProvider);
          await ref.read(walletStateProvider.notifier).refreshBalances();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.mintBorder,
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.ink.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const PillBadge(
                          text: 'Audited Smart Escrow',
                          icon: Icons.shield_outlined,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.mintBg,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: AppColors.mintBorder,
                              width: 1,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.link_rounded, size: 12, color: AppColors.celoGold),
                              SizedBox(width: 4),
                              Text(
                                'Celo L2',
                                style: TextStyle(
                                  color: AppColors.ink,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Celo Wallet cUSD Balance',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${walletState.cusdBalance.toStringAsFixed(2)} cUSD',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.ink,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${walletState.celoBalance.toStringAsFixed(4)} CELO',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.mintBorder,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Sub-Second Settlement',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mintActive,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ready to Claim Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ready to Claim',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.ink,
                    ),
                  ),
                  const PillBadge(
                    text: 'EIP-712 Signed',
                    icon: Icons.verified_rounded,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'AI-verified submissions ready for instant on-chain escrow withdrawal',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 14),

              submissionsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintActive),
                    ),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.mintBorder,
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: const BoxDecoration(
                              color: AppColors.mintBg,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_outline_rounded,
                              size: 32,
                              color: AppColors.mintActive,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'All Caught Up!',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'No pending unclaimed rewards. Submit more data to earn cUSD.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: claimable.map((item) {
                      final isClaiming = _claimingMap[item.id] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
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
                              decoration: const BoxDecoration(
                                color: AppColors.mintBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified_rounded,
                                color: AppColors.mintActive,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Submission #${item.id.length > 8 ? item.id.substring(0, 8) : item.id}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '+${item.rewardAmount?.toStringAsFixed(2) ?? "0.00"} cUSD',
                                    style: GoogleFonts.bricolageGrotesque(
                                      color: AppColors.mintActive,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DataMintButton(
                              label: 'Claim',
                              icon: Icons.payments_outlined,
                              isLoading: isClaiming,
                              onPressed: isClaiming ? null : () => _handleClaim(item),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
