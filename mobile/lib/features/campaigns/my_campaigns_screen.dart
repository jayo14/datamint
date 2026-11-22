import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
            backgroundColor: AppColors.mintActive,
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.mintActive,
        onRefresh: () async {
          ref.invalidate(myCampaignsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Metrics Overview Cards
            campaignsAsync.maybeWhen(
              data: (campaigns) {
                final activeCount = campaigns.where((c) => c.status.toUpperCase() == 'ACTIVE').length;
                final totalSubmissions = campaigns.fold<int>(0, (acc, c) => acc + c.totalSubmissions);
                final totalEscrow = campaigns
                    .where((c) => c.status.toUpperCase() == 'ACTIVE')
                    .fold<double>(0.0, (acc, c) => acc + c.totalBudget);

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Active Escrows',
                                value: '$activeCount',
                                icon: Icons.shield_outlined,
                                color: AppColors.mintActive,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Submissions',
                                value: '$totalSubmissions',
                                icon: Icons.task_alt_rounded,
                                color: AppColors.info,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildMetricCard(
                                title: 'Funded Pool',
                                value: '${totalEscrow.toStringAsFixed(0)} cUSD',
                                icon: Icons.payments_rounded,
                                color: AppColors.celoGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              orElse: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),

            // Filter Pills
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
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
            ),

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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        final progress = item.maxSubmissions > 0
                            ? (item.totalSubmissions / item.maxSubmissions).clamp(0.0, 1.0)
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
                          child: Padding(
                            padding: const EdgeInsets.all(18),
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
                                const SizedBox(height: 12),
                                Text(
                                  item.title,
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.ink,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppColors.textMuted,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Progress
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${item.totalSubmissions}/${item.maxSubmissions} collected',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                        Text(
                                          '${item.remainingBudget.toStringAsFixed(1)} / ${item.totalBudget.toStringAsFixed(1)} cUSD',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.ink,
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
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppColors.mintActive,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                if (item.status.toUpperCase() == 'DRAFT') ...[
                                  const SizedBox(height: 14),
                                  Divider(color: AppColors.mintBorder.withValues(alpha: 0.6)),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: DataMintButton(
                                      label: 'Publish to Escrow',
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.mintBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter, String label) {
    final isSelected = _filter == filter;

    return GestureDetector(
      onTap: () => setState(() => _filter = filter),
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
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.ink : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}
