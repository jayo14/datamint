import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

final mySubmissionsProvider = FutureProvider<List<SubmissionModel>>((ref) async {
  final service = ref.watch(submissionServiceProvider);
  return await service.getMySubmissions();
});

class MySubmissionsScreen extends ConsumerStatefulWidget {
  const MySubmissionsScreen({super.key});

  @override
  ConsumerState<MySubmissionsScreen> createState() => _MySubmissionsScreenState();
}

class _MySubmissionsScreenState extends ConsumerState<MySubmissionsScreen> {
  String _selectedStatus = 'ALL';

  @override
  Widget build(BuildContext context) {
    final submissionsAsync = ref.watch(mySubmissionsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.mintActive,
        onRefresh: () async {
          ref.invalidate(mySubmissionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Status Filter Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabChip('ALL', 'All Tasks'),
                      const SizedBox(width: 8),
                      _buildTabChip('PENDING_VALIDATION', 'In Validation'),
                      const SizedBox(width: 8),
                      _buildTabChip('APPROVED', 'Approved'),
                      const SizedBox(width: 8),
                      _buildTabChip('HUMAN_REVIEW', 'In Review'),
                      const SizedBox(width: 8),
                      _buildTabChip('REJECTED', 'Rejected'),
                    ],
                  ),
                ),
              ),
            ),

            submissionsAsync.when(
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
                  title: 'Unable to Load Submissions',
                  message: err.toString(),
                  actionLabel: 'Retry',
                  onAction: () => ref.invalidate(mySubmissionsProvider),
                ),
              ),
              data: (submissions) {
                final filtered = _selectedStatus == 'ALL'
                    ? submissions
                    : submissions
                        .where((s) => s.status.toUpperCase() == _selectedStatus)
                        .toList();

                if (filtered.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyStateView(
                      icon: Icons.task_outlined,
                      title: 'No Submissions Found',
                      message: _selectedStatus == 'ALL'
                          ? 'You have not submitted any data yet.'
                          : 'No submissions in $_selectedStatus state.',
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filtered[index];
                        return _SubmissionCard(
                          submission: item,
                          onTap: () => context.push('/submissions/${item.id}', extra: item),
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

  Widget _buildTabChip(String status, String label) {
    final isSelected = _selectedStatus == status;

    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
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

class _SubmissionCard extends StatelessWidget {
  final SubmissionModel submission;
  final VoidCallback onTap;

  const _SubmissionCard({required this.submission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ModalityBadge(dataType: submission.mediaType ?? 'TEXT'),
                      const SizedBox(width: 8),
                      Text(
                        '#${submission.id.length > 8 ? submission.id.substring(0, 8) : submission.id}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: submission.status),
                ],
              ),
              const SizedBox(height: 12),

              if (submission.textContent != null && submission.textContent!.isNotEmpty) ...[
                Text(
                  submission.textContent!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Footer: AI Confidence & Reward
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (submission.validationScore != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mintBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.mintBorder, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: AppColors.mintActive,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'AI Score: ${(submission.validationScore! * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  if (submission.rewardAmount != null)
                    Text(
                      '+${submission.rewardAmount!.toStringAsFixed(2)} cUSD',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mintActive,
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
