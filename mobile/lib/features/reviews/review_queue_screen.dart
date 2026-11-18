import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

final reviewQueueProvider = FutureProvider<List<ReviewQueueItem>>((ref) async {
  final service = ref.watch(reviewServiceProvider);
  return await service.getReviewQueue();
});

class ReviewQueueScreen extends ConsumerStatefulWidget {
  const ReviewQueueScreen({super.key});

  @override
  ConsumerState<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends ConsumerState<ReviewQueueScreen> {
  Future<void> _showDecisionDialog(ReviewQueueItem item) async {
    final notesController = TextEditingController();
    String decision = 'APPROVE';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Review Decision'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campaign: ${item.campaignTitle}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Flag Reason: ${item.flagReason}',
                    style: const TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Text('Select Decision:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Approve')),
                          selected: decision == 'APPROVE',
                          selectedColor: AppColors.success.withValues(alpha: 0.2),
                          onSelected: (_) => setDialogState(() => decision = 'APPROVE'),
                          showCheckmark: false,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('Reject')),
                          selected: decision == 'REJECT',
                          selectedColor: AppColors.error.withValues(alpha: 0.2),
                          onSelected: (_) => setDialogState(() => decision = 'REJECT'),
                          showCheckmark: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Reviewer Feedback Notes',
                      hintText: 'Explain the reason for this decision...',
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
                  Navigator.pop(ctx);
                  try {
                    final service = ref.read(reviewServiceProvider);
                    await service.decideReview(
                      submissionId: item.submissionId,
                      decision: decision,
                      notes: notesController.text.trim().isNotEmpty
                          ? notesController.text.trim()
                          : null,
                    );
                    ref.invalidate(reviewQueueProvider);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Submission decided as $decision.'),
                          backgroundColor: decision == 'APPROVE'
                              ? AppColors.mintPrimary
                              : AppColors.error,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to decide review: $e'),
                          backgroundColor: AppColors.error,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Submit Decision'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final queueAsync = ref.watch(reviewQueueProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reviewQueueProvider);
        },
        child: queueAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (err, _) => EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: 'Unable to Load Review Queue',
            message: err.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(reviewQueueProvider),
          ),
          data: (queue) {
            if (queue.isEmpty) {
              return const EmptyStateView(
                icon: Icons.done_all_rounded,
                title: 'Review Queue Clear',
                message: 'No submissions are currently flagged for human intervention.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final item = queue[index];

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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'AI Score: ${(item.aiScore * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        Text(
                          item.campaignTitle,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Flag Reason
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.flag_rounded, size: 16, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.flagReason,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Submission Payload Snippet
                        if (item.textContent != null) ...[
                          Text(
                            item.textContent!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Review Action Button
                        Align(
                          alignment: Alignment.centerRight,
                          child: DataMintButton(
                            label: 'Review & Decide',
                            icon: Icons.rate_review_rounded,
                            onPressed: () => _showDecisionDialog(item),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
