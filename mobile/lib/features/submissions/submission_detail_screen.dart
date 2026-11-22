import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

class SubmissionDetailScreen extends ConsumerStatefulWidget {
  final String submissionId;
  final SubmissionModel? submission;

  const SubmissionDetailScreen({
    super.key,
    required this.submissionId,
    this.submission,
  });

  @override
  ConsumerState<SubmissionDetailScreen> createState() => _SubmissionDetailScreenState();
}

class _SubmissionDetailScreenState extends ConsumerState<SubmissionDetailScreen> {
  SubmissionModel? _submission;
  bool _isLoading = false;
  bool _isClaiming = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _submission = widget.submission;
    if (_submission == null) {
      _loadSubmission();
    }
  }

  Future<void> _loadSubmission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(submissionServiceProvider);
      final sub = await service.getSubmission(widget.submissionId);
      setState(() => _submission = sub);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleClaimReward() async {
    if (_submission == null) return;

    setState(() {
      _isClaiming = true;
      _errorMessage = null;
    });

    try {
      final payoutService = ref.read(payoutServiceProvider);
      final walletService = ref.read(walletServiceProvider);

      // 1. Fetch EIP-712 typed voucher from backend
      final voucher = await payoutService.getVoucher(_submission!.id);

      // 2. Broadcast claim transaction on Celo or sign voucher
      final txHash = await walletService.claimRewardOnChain(voucher);

      // 3. Record claim on backend
      await payoutService.recordClaimOnChain(
        submissionId: _submission!.id,
        claimTxHash: txHash,
      );

      // 4. Reload submission
      await _loadSubmission();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reward claimed successfully on Celo!'),
            backgroundColor: AppColors.mintActive,
          ),
        );
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Claim failed: $e');
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Future<void> _showAppealDialog() async {
    final reasonController = TextEditingController();
    final evidenceController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Colors.white,
        title: const Text(
          'Submit Appeal',
          style: TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explain why the AI or human review decision was incorrect:',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  labelText: 'Reason for Appeal',
                  hintText: 'e.g., Audio is clear despite background noise',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: evidenceController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Additional Evidence / Notes',
                  hintText: 'Provide details supporting your submission',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mintPrimary,
              foregroundColor: AppColors.ink,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              final reason = reasonController.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final reviewService = ref.read(reviewServiceProvider);
                await reviewService.submitAppeal(
                  submissionId: widget.submissionId,
                  reason: reason,
                  evidenceText: evidenceController.text.trim(),
                );
                await _loadSubmission();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Appeal submitted for human re-evaluation.'),
                      backgroundColor: AppColors.mintActive,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit appeal: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Submit Appeal', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Submission Details', style: TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700)),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mintActive)),
      );
    }

    if (_errorMessage != null || _submission == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text('Submission Details', style: TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700)),
        ),
        body: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Unable to Load Details',
          message: _errorMessage ?? 'Submission not found.',
          actionLabel: 'Retry',
          onAction: _loadSubmission,
        ),
      );
    }

    final sub = _submission!;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Submission #${sub.id.length > 8 ? sub.id.substring(0, 8) : sub.id}',
          style: const TextStyle(
            fontFamily: 'Bricolage Grotesque',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSubmission,
          ),
        ],
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -40,
            right: -40,
            child: FloatingCoinGlow(size: 160, color: AppColors.mintPrimary, opacity: 0.25),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and Modality Header
                Row(
                  children: [
                    PillBadge(
                      text: (sub.mediaType ?? 'TEXT').toUpperCase(),
                      icon: (sub.mediaType?.toLowerCase() == 'voice')
                          ? Icons.mic_rounded
                          : (sub.mediaType?.toLowerCase() == 'image')
                              ? Icons.image_rounded
                              : Icons.article_rounded,
                      badgeColor: isDark ? AppColors.darkCard : Colors.white,
                      borderColor: isDark ? AppColors.darkBorder : AppColors.mintBorder,
                    ),
                    const SizedBox(width: 8),
                    PillBadge(
                      text: sub.status.toUpperCase(),
                      badgeColor: sub.status.toLowerCase() == 'approved'
                          ? AppColors.mintPrimary.withValues(alpha: 0.2)
                          : sub.status.toLowerCase() == 'rejected'
                              ? AppColors.error.withValues(alpha: 0.1)
                              : isDark ? AppColors.darkCard : Colors.white,
                      borderColor: sub.status.toLowerCase() == 'approved'
                          ? AppColors.mintActive
                          : sub.status.toLowerCase() == 'rejected'
                              ? AppColors.error
                              : isDark ? AppColors.darkBorder : AppColors.mintBorder,
                      textColor: sub.status.toLowerCase() == 'approved'
                          ? AppColors.mintActive
                          : sub.status.toLowerCase() == 'rejected'
                              ? AppColors.error
                              : isDark ? AppColors.darkTextPrimary : AppColors.ink,
                    ),
                    const Spacer(),
                    if (sub.rewardAmount != null && sub.rewardAmount! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.mintPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.mintBorder),
                        ),
                        child: Text(
                          '+${sub.rewardAmount!.toStringAsFixed(2)} cUSD',
                          style: const TextStyle(
                            fontFamily: 'Bricolage Grotesque',
                            color: AppColors.mintActive,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Content Payload Preview
                Text(
                  'Submitted Data Payload',
                  style: TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.mintBorder,
                    ),
                  ),
                  child: sub.textContent != null && sub.textContent!.isNotEmpty
                      ? Text(
                          sub.textContent!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'Inter',
                            height: 1.6,
                            fontSize: 14,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.mintPrimary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.attachment_rounded, size: 20, color: AppColors.ink),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                sub.assetKey ?? 'Attached Media Asset',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 24),

                // AI Validation Confidence Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.mintBorder,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mintPrimary.withValues(alpha: 0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.mintPrimary.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.bolt_rounded, color: AppColors.mintActive, size: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'AI Validation Analysis',
                                style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                                ),
                              ),
                            ],
                          ),
                          if (sub.validationScore != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.mintPrimary.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${(sub.validationScore! * 100).toStringAsFixed(0)}% Confidence',
                                style: const TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.mintActive,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Divider(color: isDark ? AppColors.darkBorder : AppColors.mintBorder, height: 1),
                      const SizedBox(height: 14),

                      if (sub.findings.isEmpty) ...[
                        const Text(
                          'AI pipeline execution running or queued...',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: AppColors.textMuted),
                        ),
                      ] else ...[
                        ...sub.findings.map((f) => _buildFindingRow(f, isDark)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Human Review Notes if present
                if (sub.humanReviewNotes != null && sub.humanReviewNotes!.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.rate_review_rounded, size: 18, color: AppColors.warning),
                            SizedBox(width: 8),
                            Text(
                              'Reviewer Feedback',
                              style: TextStyle(
                                fontFamily: 'Bricolage Grotesque',
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sub.humanReviewNotes!,
                          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Appeal Section if rejected
                if (sub.canAppeal) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? AppColors.darkBorder : AppColors.mintBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Disagree with this decision?',
                          style: TextStyle(
                            fontFamily: 'Bricolage Grotesque',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'You can submit an appeal with additional context for human re-evaluation.',
                          style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
                        ),
                        const SizedBox(height: 14),
                        DataMintButton(
                          label: 'Appeal Decision',
                          icon: Icons.gavel_rounded,
                          isOutlined: true,
                          onPressed: _showAppealDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Claim Reward Section if approved
                if (sub.canClaim) ...[
                  DataMintButton(
                    label: 'Claim ${sub.rewardAmount?.toStringAsFixed(2) ?? ""} cUSD on Celo',
                    icon: Icons.account_balance_wallet_rounded,
                    width: double.infinity,
                    isLoading: _isClaiming,
                    onPressed: _handleClaimReward,
                  ),
                  const SizedBox(height: 14),
                ],

                if (sub.claimTxHash != null && sub.claimTxHash!.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.mintPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.mintBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.mintActive, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Settled on Celo Blockchain',
                                style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sub.claimTxHash!,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingRow(ValidationFinding finding, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.mintBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.mintBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            finding.passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 18,
            color: finding.passed ? AppColors.success : AppColors.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      finding.checkName,
                      style: TextStyle(
                        fontFamily: 'Bricolage Grotesque',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                      ),
                    ),
                    Text(
                      '${(finding.confidence * 100).toStringAsFixed(0)}% conf',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                if (finding.details != null && finding.details!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    finding.details!,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
