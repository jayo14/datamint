import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../shared/providers/app_providers.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletService = ref.watch(walletServiceProvider);
    final rawAddress = walletService.connectedAddress ?? '0x4f2a1b9c1e82a4d3e7f6091234567890abcdef12';
    final shortAddress = rawAddress.length > 10
        ? '${rawAddress.substring(0, 6)}…${rawAddress.substring(rawAddress.length - 4)}'
        : rawAddress;

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
                'Wallet',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.line),
                ),
                child: const Icon(Symbols.qr_code_2, size: 22, color: AppColors.ink),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Forest Dark Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(36),
              gradient: RadialGradient(
                center: const Alignment(0.8, -0.7),
                radius: 0.9,
                colors: [
                  AppColors.mint.withValues(alpha: 0.4),
                  AppColors.forest,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Available balance',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFCFE6DC),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'MINIPAY',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$25.00',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 54,
                    fontWeight: FontWeight.w500,
                    height: 1.05,
                    letterSpacing: -1.8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: rawAddress));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Address copied to clipboard!')),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'cUSD on Celo · $shortAddress',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFFCFE6DC),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Symbols.content_copy, size: 16, color: AppColors.mint),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3 Action Icons (Cash out, Receive, History)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildWalletAction(
                      icon: Symbols.south_west,
                      label: 'Cash out',
                      isPrimary: true,
                      onTap: () => context.push('/withdraw/amount'),
                    ),
                    _buildWalletAction(
                      icon: Symbols.qr_code_2,
                      label: 'Receive',
                      isPrimary: false,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Receive to $shortAddress')),
                        );
                      },
                    ),
                    _buildWalletAction(
                      icon: Symbols.history,
                      label: 'History',
                      isPrimary: false,
                      onTap: () => context.push('/history'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Escrow notification row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.butter,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Symbols.hourglass_top, size: 22, color: AppColors.ink),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0.35 cUSD in escrow',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                    Text(
                      '1 task is being validated',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF4B4720),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Activity section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/history'),
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

          _buildActivityRow(
            context,
            icon: Symbols.mic,
            title: 'Voice task',
            subtitle: 'Just now · Approved',
            amount: '+0.50',
            iconBg: AppColors.mint,
          ),
          const SizedBox(height: 10),
          _buildActivityRow(
            context,
            icon: Symbols.photo_camera,
            title: 'Image task',
            subtitle: 'Today, 09:15 · Approved',
            amount: '+0.35',
            iconBg: AppColors.butter,
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAction({
    required IconData icon,
    required String label,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isPrimary ? AppColors.mint : Colors.white.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: isPrimary ? AppColors.ink : AppColors.mint,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityRow(
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
