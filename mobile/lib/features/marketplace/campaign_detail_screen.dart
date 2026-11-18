import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

class CampaignDetailScreen extends ConsumerStatefulWidget {
  final String campaignId;
  final CampaignModel? campaign;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
    this.campaign,
  });

  @override
  ConsumerState<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends ConsumerState<CampaignDetailScreen> {
  CampaignModel? _campaign;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _campaign = widget.campaign;
    if (_campaign == null) {
      _loadCampaign();
    }
  }

  Future<void> _loadCampaign() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(marketplaceServiceProvider);
      final campaign = await service.getCampaignDetails(widget.campaignId);
      setState(() => _campaign = campaign);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campaign Details')),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    if (_errorMessage != null || _campaign == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Campaign Details')),
        body: EmptyStateView(
          icon: Icons.error_outline_rounded,
          title: 'Unable to Load Campaign',
          message: _errorMessage ?? 'Campaign details not found.',
          actionLabel: 'Retry',
          onAction: _loadCampaign,
        ),
      );
    }

    final campaign = _campaign!;

    return Scaffold(
      appBar: AppBar(
        title: Text(campaign.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Campaign link copied to clipboard')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modality, Category, and Status Badges
            Row(
              children: [
                ModalityBadge(dataType: campaign.dataType),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    campaign.category,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
                const Spacer(),
                StatusBadge(status: campaign.status),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              campaign.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Reward Card
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reward per Verified Submission',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${campaign.rewardPerSubmission.toStringAsFixed(2)} cUSD',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.mintPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.mintPrimary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.mintPrimary,
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            const Text(
              'Campaign Overview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              campaign.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 24),

            // Instructions
            if (campaign.instructions != null && campaign.instructions!.isNotEmpty) ...[
              const Text(
                'Submission Instructions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Text(
                  campaign.instructions!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Technical Validation Policy
            const Text(
              'AI Validation & Acceptance Criteria',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildCriteriaTile(
              icon: Icons.check_circle_outline_rounded,
              title: 'Format Verification',
              description: 'Strict format check for ${campaign.dataType} payload integrity.',
            ),
            _buildCriteriaTile(
              icon: Icons.verified_user_outlined,
              title: 'AI Quality & Semantic Check',
              description: 'Automatic scoring for relevance, instruction adherence, and quality.',
            ),
            _buildCriteriaTile(
              icon: Icons.security_rounded,
              title: 'Anti-Spam & Duplicate Shield',
              description: 'Submissions are verified against similarity models to ensure uniqueness.',
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
          ),
          child: DataMintButton(
            label: 'Start Submission',
            icon: Icons.upload_file_rounded,
            width: double.infinity,
            onPressed: () {
              context.push('/submit/${campaign.id}', extra: campaign);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCriteriaTile({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.mintPrimary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
