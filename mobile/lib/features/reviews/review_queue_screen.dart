import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            title: Text(
              'Review Decision',
              style: GoogleFonts.bricolageGrotesque(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppColors.ink,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Campaign: ${item.campaignTitle}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          size: 15,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.flagReason,
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Select Decision:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => decision = 'APPROVE'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: decision == 'APPROVE'
                                  ? AppColors.mint
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: decision == 'APPROVE'
                                    ? AppColors.mintActive
                                    : AppColors.mintBorder,
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Approve',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setDialogState(() => decision = 'REJECT'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: decision == 'REJECT'
                                  ? AppColors.error.withValues(alpha: 0.15)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: decision == 'REJECT'
                                    ? AppColors.error
                                    : AppColors.mintBorder,
                                width: 1.2,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: const Text(
                              'Reject',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
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
                child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
              ),
              DataMintButton(
                label: 'Confirm Decision',
                onPressed: () async {
                  Navigator.pop(ctx);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
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
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Submission $decision confirmed.'),
                        backgroundColor:
                            decision == 'APPROVE' ? AppColors.mintActive : AppColors.error,
                      ),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.error),
                    );
                  }
                },
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

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AppColors.mintActive,
        onRefresh: () async {
          ref.invalidate(reviewQueueProvider);
        },
        child: queueAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintActive),
            ),
          ),
          error: (err, _) => EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: 'Unable to Load Review Queue',
            message: err.toString(),
            actionLabel: 'Retry',
            onAction: () => ref.invalidate(reviewQueueProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const EmptyStateView(
                icon: Icons.verified_user_outlined,
                title: 'Review Queue Clear',
                message:
                    'All submissions have passed automated AI verification. No manual reviews pending.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item.campaignTitle,
                              style: GoogleFonts.bricolageGrotesque(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: AppColors.warning.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Flagged QA',
                              style: TextStyle(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Reason: ${item.flagReason}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Align(
                        alignment: Alignment.centerRight,
                        child: DataMintButton(
                          label: 'Review Submission',
                          icon: Icons.rate_review_rounded,
                          onPressed: () => _showDecisionDialog(item),
                        ),
                      ),
                    ],
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
