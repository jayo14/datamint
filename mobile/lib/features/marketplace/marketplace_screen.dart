import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

class MarketplaceScreen extends ConsumerWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filter = ref.watch(marketplaceFilterProvider);
    final campaignsAsync = ref.watch(marketplaceCampaignsProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(marketplaceCampaignsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Search & Filter Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                        hintText: 'Search dataset campaigns, tasks...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        suffixIcon: filter.search != null
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  ref.read(marketplaceFilterProvider.notifier).state =
                                      filter.copyWith(search: null);
                                },
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Modality Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            context: context,
                            label: 'All Datasets',
                            isSelected: filter.dataType == null,
                            onSelected: () {
                              ref.read(marketplaceFilterProvider.notifier).state =
                                  filter.copyWith(dataType: null);
                            },
                          ),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                            context: context,
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
                            context: context,
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
                            context: context,
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
                  child: CircularProgressIndicator(strokeWidth: 2),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    required BuildContext context,
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return FilterChip(
      avatar: icon != null
          ? Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
            )
          : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: AppColors.mintPrimary,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.mintPrimary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      showCheckmark: false,
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final CampaignModel campaign;
  final VoidCallback onTap;

  const _CampaignCard({required this.campaign, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final progress = campaign.maxSubmissions > 0
        ? (campaign.totalSubmissions / campaign.maxSubmissions).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ModalityBadge(dataType: campaign.dataType),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          campaign.category,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Escrow Verified Badge
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: campaign.onchainCampaignId != null
                            ? AppColors.mintPrimary
                            : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        campaign.onchainCampaignId != null ? 'Escrow Funded' : 'Pending Escrow',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: campaign.onchainCampaignId != null
                              ? AppColors.mintPrimary
                              : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                campaign.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),

              // Description
              Text(
                campaign.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),

              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintPrimary),
                ),
              ),
              const SizedBox(height: 12),

              // Footer: Submissions count and Reward
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${campaign.totalSubmissions} / ${campaign.maxSubmissions} submissions',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  // Reward Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.mintPrimary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, size: 14, color: AppColors.mintPrimary),
                        const SizedBox(width: 4),
                        Text(
                          '+${campaign.rewardPerSubmission.toStringAsFixed(2)} cUSD',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mintPrimary,
                          ),
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
