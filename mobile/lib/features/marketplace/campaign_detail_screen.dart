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
        backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Campaign Details',
            style: TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700),
          ),
        ),
        body: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.mintActive)),
      );
    }

    if (_errorMessage != null || _campaign == null) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Campaign Details',
            style: TextStyle(fontFamily: 'Bricolage Grotesque', fontWeight: FontWeight.w700),
          ),
        ),
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
      backgroundColor: isDark ? AppColors.darkBg : AppColors.mintBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(
          campaign.title,
          style: const TextStyle(
            fontFamily: 'Bricolage Grotesque',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Campaign link copied to clipboard'),
                  backgroundColor: AppColors.mintActive,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background subtle glowing halos
          const Positioned(
            top: -40,
            right: -40,
            child: FloatingCoinGlow(size: 160, color: AppColors.mintPrimary, opacity: 0.25),
          ),
          const Positioned(
            bottom: 60,
            left: -50,
            child: FloatingCoinGlow(size: 200, color: Color(0xFF5FD6E8), opacity: 0.15),
          ),

          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modality, Category, and Status Badges
                Row(
                  children: [
                    PillBadge(
                      text: campaign.dataType.toUpperCase(),
                      icon: campaign.dataType.toLowerCase() == 'voice'
                          ? Icons.mic_rounded
                          : campaign.dataType.toLowerCase() == 'image'
                              ? Icons.image_rounded
                              : Icons.article_rounded,
                      badgeColor: isDark ? AppColors.darkCard : Colors.white,
                      borderColor: isDark ? AppColors.darkBorder : AppColors.mintBorder,
                    ),
                    const SizedBox(width: 8),
                    PillBadge(
                      text: campaign.category,
                      badgeColor: isDark ? AppColors.darkCard : Colors.white,
                      borderColor: isDark ? AppColors.darkBorder : AppColors.mintBorder,
                    ),
                    const Spacer(),
                    PillBadge(
                      text: campaign.status.toUpperCase(),
                      badgeColor: campaign.status.toLowerCase() == 'active'
                          ? AppColors.mintPrimary.withValues(alpha: 0.2)
                          : isDark ? AppColors.darkCard : Colors.white,
                      borderColor: campaign.status.toLowerCase() == 'active'
                          ? AppColors.mintActive
                          : isDark ? AppColors.darkBorder : AppColors.mintBorder,
                      textColor: campaign.status.toLowerCase() == 'active'
                          ? AppColors.mintActive
                          : isDark ? AppColors.darkTextPrimary : AppColors.ink,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Title
                Text(
                  campaign.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontFamily: 'Bricolage Grotesque',
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 18),

                // Escrow Reward Hero Card
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
                        color: AppColors.mintPrimary.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'REWARD PER VERIFIED SUBMISSION',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                campaign.rewardPerSubmission.toStringAsFixed(2),
                                style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'cUSD',
                                style: TextStyle(
                                  fontFamily: 'Bricolage Grotesque',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.mintActive,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.mintPrimary.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.mintBorder,
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                          color: AppColors.ink,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description
                Text(
                  'Campaign Overview',
                  style: TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
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
                  child: Text(
                    campaign.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'Inter',
                      height: 1.6,
                      fontSize: 14,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Instructions
                if (campaign.instructions != null && campaign.instructions!.isNotEmpty) ...[
                  Text(
                    'Submission Instructions',
                    style: TextStyle(
                      fontFamily: 'Bricolage Grotesque',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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
                    child: Text(
                      campaign.instructions!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'Inter',
                        height: 1.6,
                        fontSize: 14,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Technical Validation Policy
                Text(
                  'AI Validation & Acceptance Criteria',
                  style: TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCriteriaTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Format Verification',
                  description: 'Strict format check for ${campaign.dataType} payload integrity.',
                  isDark: isDark,
                ),
                _buildCriteriaTile(
                  icon: Icons.verified_user_outlined,
                  title: 'AI Quality & Semantic Check',
                  description: 'Automatic scoring for relevance, instruction adherence, and quality.',
                  isDark: isDark,
                ),
                _buildCriteriaTile(
                  icon: Icons.security_rounded,
                  title: 'Anti-Spam & Duplicate Shield',
                  description: 'Submissions are verified against similarity models to ensure uniqueness.',
                  isDark: isDark,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.mintBorder,
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
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.mintBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.mintPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.mintActive, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Bricolage Grotesque',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: isDark ? AppColors.darkTextSecondary : AppColors.textMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
