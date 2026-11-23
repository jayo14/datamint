import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/settings'),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                  ),
                  child: const Icon(Symbols.settings, size: 22, color: AppColors.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // User info
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.butter,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  'A',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Amina',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Contributor · Nigeria',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 3 Stat tiles
          Row(
            children: [
              _buildStatTile('48', 'Tasks done'),
              const SizedBox(width: 10),
              _buildStatTile('94%', 'Approved'),
              const SizedBox(width: 10),
              _buildStatTile('\$68', 'Earned'),
            ],
          ),
          const SizedBox(height: 28),

          // "How you speak"
          Text(
            'How you speak',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              MintChip(label: 'English', isSelected: true, onTap: () {}),
              const SizedBox(width: 8),
              MintChip(label: 'Yoruba', isSelected: true, onTap: () {}),
              const SizedBox(width: 8),
              MintChip(label: 'Pidgin', isSelected: true, onTap: () {}),
            ],
          ),
          const SizedBox(height: 28),

          // Options list
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _buildMenuItem(
                  icon: Symbols.edit,
                  title: 'Edit profile',
                  onTap: () => context.push('/auth/profile'),
                ),
                const Divider(color: AppColors.line, height: 1),
                _buildMenuItem(
                  icon: Symbols.account_balance_wallet,
                  title: 'Payout wallet',
                  onTap: () => context.push('/wallet'),
                ),
                const Divider(color: AppColors.line, height: 1),
                _buildMenuItem(
                  icon: Symbols.help,
                  title: 'Help and support',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Support at help@datamint.io')),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.line),
        ),
        alignment: Alignment.center,
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.mist,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF087A52)),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
      ),
      trailing: const Icon(Symbols.chevron_right, size: 20, color: AppColors.text),
      onTap: onTap,
    );
  }
}
