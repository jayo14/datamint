import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(mySubmissionsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // Status Filter Tabs
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = _selectedStatus == status;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatus = status),
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

class _SubmissionCard extends StatelessWidget {
  final SubmissionModel submission;
  final VoidCallback onTap;

  const _SubmissionCard({required this.submission, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ModalityBadge(dataType: submission.mediaType ?? 'TEXT'),
                      const SizedBox(width: 8),
                      Text(
                        'ID: ${submission.id.length > 8 ? submission.id.substring(0, 8) : submission.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          fontFamily: 'monospace',
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Footer: AI Confidence & Reward
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (submission.validationScore != null)
                    Row(
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: AppColors.mintPrimary),
                        const SizedBox(width: 4),
                        Text(
                          'Score: ${(submission.validationScore! * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.mintPrimary,
                          ),
                        ),
                      ],
                    )
                  else
                    const Text(
                      'Validation in progress...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),

                  if (submission.rewardAmount != null && submission.rewardAmount! > 0)
                    Text(
                      '+${submission.rewardAmount!.toStringAsFixed(2)} cUSD',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mintPrimary,
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
