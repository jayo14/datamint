import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

final myCampaignsProvider = FutureProvider<List<CampaignModel>>((ref) async {
  final service = ref.watch(campaignServiceProvider);
  return await service.getMyCampaigns();
});

class MyCampaignsScreen extends ConsumerStatefulWidget {
  const MyCampaignsScreen({super.key});

  @override
  ConsumerState<MyCampaignsScreen> createState() => _MyCampaignsScreenState();
}

class _MyCampaignsScreenState extends ConsumerState<MyCampaignsScreen> {
  String _filter = 'ALL';

  Future<void> _handlePublish(String campaignId) async {
    try {
      final service = ref.read(campaignServiceProvider);
      await service.publishCampaign(campaignId);
      ref.invalidate(myCampaignsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Campaign published to marketplace!'),
            backgroundColor: AppColors.mintPrimary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Publish failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final campaignsAsync = ref.watch(myCampaignsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myCampaignsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Filter Pills
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    _buildFilterChip('ALL', 'All Campaigns'),
                    const SizedBox(width: 8),
                    _buildFilterChip('ACTIVE', 'Active'),
                    const SizedBox(width: 8),
                    _buildFilterChip('DRAFT', 'Drafts'),
                    const SizedBox(width: 8),
                    _buildFilterChip('COMPLETED', 'Completed'),
                  ],
                ),
              ),
            ),

            campaignsAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, _) => SliverFillRemaining(
                child: EmptyStateView(
                  icon: Icons.error_outline_rounded,
                  title: 'Unable to Load Campaigns',
                  message: err.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(myCampaignsProvider),
                ),
              ),
              data: (campaigns) {
                final filtered = _filter == 'ALL'
                    ? campaigns
                    : campaigns
                        .where((c) => c.status.toUpperCase() == _filter)
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateView(
                      icon: Icons.campaign_outlined,
                      title: 'No Campaigns Found',
                      message: _filter == 'ALL'
                          ? 'You have not created any campaigns yet.'
                          : 'No campaigns matching "$_filter".',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        final progress = item.maxSubmissions > 0
                            ? (item.totalSubmissions / item.maxSubmissions).clamp(0.0, 1.0)
                            : 0.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ModalityBadge(dataType: item.dataType),
                                    StatusBadge(status: item.status),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  item.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Progress
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDark ? AppColors.darkSurface : Colors.grey.shade200,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.mintPrimary),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item.totalSubmissions}/${item.maxSubmissions} submissions',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                    Text(
                                      '${item.remainingBudget.toStringAsFixed(1)} / ${item.totalBudget.toStringAsFixed(1)} cUSD',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.celoGold,
                                      ),
                                    ),
                                  ],
                                ),

                                if (item.status.toUpperCase() == 'DRAFT') ...[
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 6),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: DataMintButton(
                                      label: 'Publish to Marketplace',
                                      icon: Icons.rocket_launch_rounded,
                                      onPressed: () => _handlePublish(item.id),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: filtered.length,
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

  Widget _buildFilterChip(String filter, String label) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _filter == filter;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = filter),
      selectedColor: AppColors.mintPrimary,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87),
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
