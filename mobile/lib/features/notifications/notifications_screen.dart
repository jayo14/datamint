import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/models/models.dart';
import '../../shared/providers/app_providers.dart';

final notificationsListProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final service = ref.watch(notificationServiceProvider);
  return await service.getNotifications();
});

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  Future<void> _handleMarkAsRead(NotificationModel notification) async {
    if (notification.isRead) return;
    try {
      final service = ref.read(notificationServiceProvider);
      await service.markAsRead(notification.id);
      ref.invalidate(notificationsListProvider);
      ref.invalidate(unreadNotificationsCountProvider);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsListProvider);

    return Scaffold(
      backgroundColor: AppColors.mintBg,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Notifications',
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.ink,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.ink),
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -40,
            right: -40,
            child: FloatingCoinGlow(
              size: 200,
              color: AppColors.mint,
              opacity: 0.35,
            ),
          ),

          RefreshIndicator(
            color: AppColors.mintActive,
            onRefresh: () async {
              ref.invalidate(notificationsListProvider);
              ref.invalidate(unreadNotificationsCountProvider);
            },
            child: notificationsAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mintActive),
                ),
              ),
              error: (err, _) => EmptyStateView(
                icon: Icons.error_outline_rounded,
                title: 'Unable to Load Notifications',
                message: err.toString(),
                actionLabel: 'Retry',
                onAction: () => ref.invalidate(notificationsListProvider),
              ),
              data: (notifications) {
                if (notifications.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.notifications_none_rounded,
                    title: 'No Notifications Yet',
                    message:
                        'You are all caught up! Updates about your submissions, campaigns, and rewards will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final item = notifications[index];

                    IconData icon;
                    Color iconColor;

                    switch (item.type.toUpperCase()) {
                      case 'REWARD_CLAIMABLE':
                      case 'PAYMENT_SETTLED':
                        icon = Icons.monetization_on_rounded;
                        iconColor = AppColors.mintActive;
                        break;
                      case 'VALIDATION_PASSED':
                      case 'SUBMISSION_UPDATE':
                        icon = Icons.verified_rounded;
                        iconColor = AppColors.info;
                        break;
                      case 'REVIEW_REQUIRED':
                        icon = Icons.flag_rounded;
                        iconColor = AppColors.warning;
                        break;
                      default:
                        icon = Icons.notifications_active_rounded;
                        iconColor = AppColors.celoGold;
                        break;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: !item.isRead
                              ? AppColors.mintActive.withValues(alpha: 0.5)
                              : AppColors.mintBorder,
                          width: !item.isRead ? 1.5 : 1.2,
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
                        onTap: () => _handleMarkAsRead(item),
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(icon, color: iconColor, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: GoogleFonts.bricolageGrotesque(
                                              fontWeight:
                                                  item.isRead ? FontWeight.w600 : FontWeight.bold,
                                              fontSize: 14,
                                              color: AppColors.ink,
                                            ),
                                          ),
                                        ),
                                        if (!item.isRead)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: AppColors.mintActive,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.message,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: AppColors.textMuted,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
