import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../core/widgets/mint_components.dart';
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
  final Set<int> _readIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 14,
              left: 20,
              child: MintBackButton(
                onTap: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
              ),
            ),
            Positioned.fill(
              top: 70,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontFamily: 'Bricolage Grotesque',
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0D1F18),
                          letterSpacing: -0.8,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _readIds.addAll([1, 2, 3, 4, 5]);
                          });
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'Mark all read',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF087A52),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Today',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildNotificationItem(
                    id: 1,
                    isDefaultUnread: true,
                    icon: Symbols.paid,
                    iconBg: const Color(0xFF74E3B6),
                    title: '+0.50 cUSD received',
                    subtitle: 'Your voice task was approved · 2m',
                    onTap: () => context.push('/receipt'),
                  ),
                  _buildNotificationItem(
                    id: 2,
                    isDefaultUnread: true,
                    icon: Symbols.checklist,
                    iconBg: const Color(0xFFFFF1B8),
                    title: 'New tasks in Yoruba',
                    subtitle: '12 tasks just opened up · 1h',
                    onTap: () => context.go('/home'),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Earlier',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildNotificationItem(
                    id: 3,
                    isDefaultUnread: false,
                    icon: Symbols.local_fire_department,
                    iconBg: const Color(0xFFFFC9B0),
                    title: 'Keep your 4-day streak',
                    subtitle: 'One task today keeps it going · Yesterday',
                  ),
                  _buildNotificationItem(
                    id: 4,
                    isDefaultUnread: false,
                    icon: Symbols.south_west,
                    iconBg: Colors.white,
                    hasBorder: true,
                    title: 'Cash out sent',
                    subtitle: '5.00 cUSD arrived in MiniPay · Yesterday',
                  ),
                  _buildNotificationItem(
                    id: 5,
                    isDefaultUnread: false,
                    icon: Symbols.info,
                    iconBg: const Color(0xFFD9F3FF),
                    title: 'Task not approved',
                    subtitle: 'Noise was high. Your reward is safe · 2d',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required int id,
    required bool isDefaultUnread,
    required IconData icon,
    required Color iconBg,
    bool hasBorder = false,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final isUnread = isDefaultUnread && !_readIds.contains(id);

    return InkWell(
      onTap: () {
        setState(() {
          _readIds.add(id);
        });
        if (onTap != null) onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
                border: hasBorder ? Border.all(color: const Color(0xFFD5EDE2)) : null,
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF0D1F18),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1F18),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: Color(0xFF3F5F52),
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF0B9E6B),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
