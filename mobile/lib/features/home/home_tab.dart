import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

class HomeTab extends ConsumerWidget {
  final VoidCallback? onGoToTasks;

  const HomeTab({super.key, this.onGoToTasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name & Bell
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.butter,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'A',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    'Amina',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Symbols.notifications, size: 24, color: AppColors.ink),
                      Positioned(
                        top: 10,
                        right: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.alert,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Available Balance Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(36),
              gradient: RadialGradient(
                center: const Alignment(0.8, -0.6),
                radius: 0.9,
                colors: [
                  AppColors.mint.withValues(alpha: 0.4),
                  AppColors.forest,
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -24,
                  top: 18,
                  child: Transform.rotate(
                    angle: -14 * math.pi / 180,
                    child: const MintDCoin(size: 120),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available balance',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFCFE6DC),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$24.50',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 54,
                          fontWeight: FontWeight.w500,
                          height: 1.05,
                          letterSpacing: -1.8,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '+0.85 today',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: MintButton(
                              label: 'Cash out',
                              icon: Symbols.south_west,
                              isSmall: true,
                              onPressed: () => context.push('/withdraw/amount'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 40,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withValues(alpha: 0.14),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                onPressed: () => context.push('/history'),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Symbols.history, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'History',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Stat Tiles (Today & Streak)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Symbols.trending_up, size: 18, color: Color(0xFF087A52)),
                          const SizedBox(width: 6),
                          Text(
                            'Today',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '0.85 cUSD',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Symbols.local_fire_department, size: 18, color: Color(0xFFD2562B)),
                          const SizedBox(width: 6),
                          Text(
                            'Streak',
                            style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '4 days',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // "Tasks for you"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tasks for you',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: onGoToTasks,
                child: Text(
                  'See all',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal Task Cards
          SizedBox(
            height: 236,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              children: [
                _buildTaskCard(
                  context,
                  title: 'Say a short phrase in Yoruba',
                  type: MintPillType.voice,
                  duration: '~30s',
                  reward: '+0.50',
                  bg: AppColors.mint,
                  onTap: () => context.push('/tasks/task-detail'),
                ),
                const SizedBox(width: 12),
                _buildTaskCard(
                  context,
                  title: 'Photograph a street sign',
                  type: MintPillType.image,
                  duration: '~45s',
                  reward: '+0.35',
                  bg: AppColors.butter,
                  onTap: () => context.push('/tasks/photo/capture'),
                ),
                const SizedBox(width: 12),
                _buildTaskCard(
                  context,
                  title: 'Translate 3 phrases to Pidgin',
                  type: MintPillType.text,
                  duration: '~1 min',
                  reward: '+0.40',
                  bg: AppColors.sky,
                  onTap: () => context.push('/tasks/text'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // "Recent earnings"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent earnings',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/history'),
                child: Text(
                  'View all',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mintDeep,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Earning Rows
          _buildEarningRow(
            context,
            icon: Symbols.mic,
            title: 'Voice task · Yoruba',
            subtitle: 'Just now · Approved',
            amount: '+0.50',
            iconBg: AppColors.mint,
          ),
          const SizedBox(height: 10),
          _buildEarningRow(
            context,
            icon: Symbols.photo_camera,
            title: 'Street sign photo',
            subtitle: '14:20 · Approved',
            amount: '+0.35',
            iconBg: AppColors.butter,
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    BuildContext context, {
    required String title,
    required MintPillType type,
    required String duration,
    required String reward,
    required Color bg,
    required VoidCallback onTap,
  }) {
    IconData icon;
    switch (type) {
      case MintPillType.voice:
        icon = Symbols.mic;
        break;
      case MintPillType.image:
        icon = Symbols.photo_camera;
        break;
      case MintPillType.text:
        icon = Symbols.text_fields;
        break;
      default:
        icon = Symbols.mic;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 262,
        height: 236,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 20, color: AppColors.ink),
                ),
                MintTypePill(type: type),
              ],
            ),
            Text(
              title,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                height: 1.15,
                color: AppColors.ink,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  duration,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.ink,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    reward,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String amount,
    required Color iconBg,
  }) {
    return GestureDetector(
      onTap: () => context.push('/receipt'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 22, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              amount,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
