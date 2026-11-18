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
            backgroundColor: AppColors.mintPrimary,
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
        title: const Text('Submit Appeal'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Explain why the AI or human review decision was incorrect:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason for Appeal',
                  hintText: 'e.g., Audio is clear despite background noise',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: evidenceController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional Evidence / Notes',
                  hintText: 'Provide details supporting your submission',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
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
                      backgroundColor: AppColors.mintPrimary,
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
            child: const Text('Submit Appeal'),
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
        appBar: AppBar(title: const Text('Submission Details')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_errorMessage != null || _submission == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Submission Details')),
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
      appBar: AppBar(
        title: Text('Submission #${sub.id.length > 8 ? sub.id.substring(0, 8) : sub.id}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadSubmission,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Modality Header
            Row(
              children: [
                ModalityBadge(dataType: sub.mediaType ?? 'TEXT'),
                const SizedBox(width: 8),
                StatusBadge(status: sub.status),
                const Spacer(),
                if (sub.rewardAmount != null && sub.rewardAmount! > 0)
                  Text(
                    '+${sub.rewardAmount!.toStringAsFixed(2)} cUSD',
                    style: const TextStyle(
                      color: AppColors.mintPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            // Content Payload Preview
            const Text(
              'Submitted Data Payload',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: sub.textContent != null && sub.textContent!.isNotEmpty
                  ? Text(
                      sub.textContent!,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                    )
                  : Row(
                      children: [
                        const Icon(Icons.attachment_rounded, size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          sub.assetKey ?? 'Attached Media Asset',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),

            // AI Validation Confidence & Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bolt_rounded, color: AppColors.mintPrimary, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'AI Validation Analysis',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                      if (sub.validationScore != null)
                        Text(
                          '${(sub.validationScore! * 100).toStringAsFixed(0)}% Confidence',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.mintPrimary,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),

                  if (sub.findings.isEmpty) ...[
                    const Text(
                      'AI pipeline execution running or queued...',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ] else ...[
                    ...sub.findings.map((f) => _buildFindingRow(f)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Human Review Notes if present
            if (sub.humanReviewNotes != null && sub.humanReviewNotes!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
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
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      sub.humanReviewNotes!,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Appeal Section if rejected
            if (sub.canAppeal) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Disagree with this decision?',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'You can submit an appeal with additional context for a human reviewer to inspect.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
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
              const SizedBox(height: 12),
            ],

            if (sub.claimTxHash != null && sub.claimTxHash!.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.mintPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.mintPrimary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.mintPrimary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Settled on Celo Blockchain',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            sub.claimTxHash!,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Colors.grey,
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
          ],
        ),
      ),
    );
  }

  Widget _buildFindingRow(ValidationFinding finding) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      '${(finding.confidence * 100).toStringAsFixed(0)}% conf',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                if (finding.details != null && finding.details!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    finding.details!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
