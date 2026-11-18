import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsListProvider);
          ref.invalidate(unreadNotificationsCountProvider);
        },
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
                message: 'You are all caught up! Updates about your submissions, campaigns, and rewards will appear here.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];

                IconData icon;
                Color iconColor;

                switch (item.type.toUpperCase()) {
                  case 'REWARD_CLAIMABLE':
                  case 'PAYMENT_SETTLED':
                    icon = Icons.monetization_on_rounded;
                    iconColor = AppColors.mintPrimary;
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: !item.isRead
                      ? (isDark
                          ? AppColors.mintPrimary.withValues(alpha: 0.08)
                          : AppColors.mintPrimary.withValues(alpha: 0.05))
                      : null,
                  child: InkWell(
                    onTap: () => _handleMarkAsRead(item),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
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
                                        style: TextStyle(
                                          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    if (!item.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.mintPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.message,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
    );
  }
}
