import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

// ==========================================
// 1. Withdraw 1 · Amount Screen
// ==========================================
class WithdrawAmountScreen extends StatefulWidget {
  const WithdrawAmountScreen({super.key});

  @override
  State<WithdrawAmountScreen> createState() => _WithdrawAmountScreenState();
}

class _WithdrawAmountScreenState extends State<WithdrawAmountScreen> {
  String _amount = '10.00';

  void _onKeyPress(String key) {
    if (_amount == '0' || _amount == '0.00') {
      setState(() => _amount = key);
    } else if (_amount.length < 7) {
      setState(() => _amount += key);
    }
  }

  void _onBackspace() {
    if (_amount.isNotEmpty) {
      setState(() {
        _amount = _amount.substring(0, _amount.length - 1);
        if (_amount.isEmpty) _amount = '0';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MintBackButton(
                        onPressed: () => context.go('/home'),
                      ),
                      Text(
                        'Cash out',
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.ink,
                        ),
                      ),
                      const SizedBox(width: 44),
                    ],
                  ),
                  const SizedBox(height: 36),

                  Text(
                    '\$$_amount',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 60,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                      letterSpacing: -2.0,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Available to cash out: \$25.00',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.account_balance_wallet,
                            size: 18, color: Color(0xFF087A52)),
                        const SizedBox(width: 8),
                        Text(
                          'To MiniPay (0x4f2a…9c1e)',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  MintButton(
                    label: 'Review cash out',
                    onPressed: () => context.push('/withdraw/review'),
                  ),
                ],
              ),
            ),
            const Spacer(),

            MintNumericKeypad(
              showDot: true,
              onKeyPress: _onKeyPress,
              onBackspace: _onBackspace,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. Withdraw 2 · Review Screen
// ==========================================
class WithdrawReviewScreen extends StatelessWidget {
  final double amount;
  const WithdrawReviewScreen({super.key, this.amount = 10.0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MintBackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Text(
                    'Review cash out',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
              const SizedBox(height: 32),

              Center(
                child: Column(
                  children: [
                    Text(
                      'Cash out amount',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '\$10.00 cUSD',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 48,
                        fontWeight: FontWeight.w500,
                        height: 1.05,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Key-Value Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    _buildReviewKV('To', 'MiniPay wallet'),
                    const Divider(color: AppColors.line, height: 24),
                    _buildReviewKV('Address', '0x4f2a…9c1e'),
                    const Divider(color: AppColors.line, height: 24),
                    _buildReviewKV('Network', 'Celo (fast & low fee)'),
                    const Divider(color: AppColors.line, height: 24),
                    _buildReviewKV('Network fee', '< 0.001 cUSD'),
                    const Divider(color: AppColors.line, height: 24),
                    _buildReviewKV('You receive', '10.00 cUSD', isBold: true),
                  ],
                ),
              ),

              const Spacer(),

              MintButton(
                label: 'Confirm cash out',
                icon: Symbols.fingerprint,
                onPressed: () => context.go('/withdraw/sent'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewKV(String key, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: AppColors.text,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. Withdraw 3 · Sent Screen
// ==========================================
class WithdrawSentScreen extends StatelessWidget {
  final double amount;
  const WithdrawSentScreen({super.key, this.amount = 10.0});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.3),
                  radius: 0.85,
                  colors: [
                    AppColors.mint.withValues(alpha: 0.38),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Symbols.check,
                      size: 40,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    '10.00 cUSD sent',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 36,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Funds are on their way to your MiniPay wallet.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: const Color(0xFFB7D6C9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  MintGlassCard(
                    isDark: true,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildSentKV('Destination', 'MiniPay'),
                        const SizedBox(height: 12),
                        _buildSentKV('Network', 'Celo'),
                        const SizedBox(height: 12),
                        _buildSentKV('Status', 'Complete'),
                      ],
                    ),
                  ),

                  const Spacer(),

                  MintButton(
                    label: 'Done',
                    onPressed: () => context.go('/home'),
                  ),
                  const SizedBox(height: 10),
                  MintButton(
                    label: 'View receipt',
                    icon: Symbols.open_in_new,
                    variant: MintButtonVariant.ghost,
                    onPressed: () => context.push('/receipt'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentKV(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          key,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFFCFE6DC),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
