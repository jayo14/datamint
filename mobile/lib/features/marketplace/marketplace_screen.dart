import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(marketplaceFilterProvider);
    final campaignsAsync = ref.watch(marketplaceCampaignsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.mintActive,
        onRefresh: () async {
          ref.invalidate(marketplaceCampaignsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Search & Filter Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
                    TextField(
                      onChanged: (val) {
                        ref.read(marketplaceFilterProvider.notifier).state =
                            filter.copyWith(search: val.trim().isNotEmpty ? val.trim() : null);
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Search dataset campaigns, tasks...',
                        hintStyle: TextStyle(
                          color: AppColors.textMuted.withValues(alpha: 0.7),
                          fontSize: 14,
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: AppColors.mintActive,
                        ),
                        suffixIcon: filter.search != null
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear_rounded,
                                  size: 18,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () {
                                  ref.read(marketplaceFilterProvider.notifier).state =
                                      filter.copyWith(search: null);
                                },
                              )
                            : null,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.mintBorder, width: 1.2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.mintBorder, width: 1.2),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: const BorderSide(color: AppColors.mintActive, width: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Modality Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            label: 'All Datasets',
                            isSelected: filter.dataType == null,
                            onSelected: () {
                              ref.read(marketplaceFilterProvider.notifier).state =
                                  filter.copyWith(dataType: null);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Text',
                            icon: Icons.text_snippet_rounded,
                            isSelected: filter.dataType == 'TEXT',
                            onSelected: () {
                              ref.read(marketplaceFilterProvider.notifier).state =
                                  filter.copyWith(dataType: 'TEXT');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Voice / Audio',
                            icon: Icons.mic_rounded,
                            isSelected: filter.dataType == 'VOICE',
                            onSelected: () {
                              ref.read(marketplaceFilterProvider.notifier).state =
                                  filter.copyWith(dataType: 'VOICE');
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            label: 'Image',
                            icon: Icons.image_rounded,
                            isSelected: filter.dataType == 'IMAGE',
                            onSelected: () {
                              ref.read(marketplaceFilterProvider.notifier).state =
                                  filter.copyWith(dataType: 'IMAGE');
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Campaign List
            campaignsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintActive),
                  ),
                ),
              ),
              error: (err, _) => SliverFillRemaining(
                child: EmptyStateView(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to Load Marketplace',
                  message: err.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(marketplaceCampaignsProvider),
                ),
              ),
              data: (campaigns) {
                if (campaigns.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateView(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'No Active Campaigns Found',
                      message: 'Try adjusting your filters or search terms.',
                      actionLabel: 'Reset Filters',
                      onAction: () {
                        ref.read(marketplaceFilterProvider.notifier).state =
                            const MarketplaceFilter();
                      },
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final campaign = campaigns[index];
                        return _CampaignCard(
                          campaign: campaign,
                          onTap: () => context.push('/marketplace/${campaign.id}', extra: campaign),
                        );
                      },
                      childCount: campaigns.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mint : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.mintActive : AppColors.mintBorder,
            width: isSelected ? 1.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.mintActive.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.ink : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.ink : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onTap;

  const _CampaignCard({required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final progress = campaign.maxSubmissions > 0
        ? (campaign.totalSubmissions / campaign.maxSubmissions).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ModalityBadge(dataType: campaign.dataType),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mintBg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.mintBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          campaign.category ?? 'AI Training',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Reward Badge Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.mintBg,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.mintActive.withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.payments_rounded,
                          size: 15,
                          color: AppColors.mintActive,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${campaign.rewardPerSubmission.toStringAsFixed(2)} cUSD',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Campaign Title
              Text(
                campaign.title,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                campaign.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${campaign.totalSubmissions} of ${campaign.maxSubmissions} tasks completed',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.mintActive,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 7,
                      backgroundColor: AppColors.mintBg,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintActive),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Bottom Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.mintActive,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Audited Escrow',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textMuted.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),

                  // Submit Pill Button
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.mint.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Contribute',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.5,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 14,
                          color: AppColors.ink,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
