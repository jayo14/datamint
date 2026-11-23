import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

// ==========================================
// 1. Validating Screen
// ==========================================
class ValidatingScreen extends StatefulWidget {
  const ValidatingScreen({super.key});

  @override
  State<ValidatingScreen> createState() => _ValidatingScreenState();
}

class _ValidatingScreenState extends State<ValidatingScreen> {
  int _step = 1; // 1 = format check, 2 = transcription, 3 = escrow release
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
      if (!mounted) return;
      if (_step < 3) {
        setState(() => _step++);
      } else {
        timer.cancel();
        context.go('/tasks/paid');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.mint.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Center(
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.mint),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'Validating your submission',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'GPT-4o is checking quality against the builder’s criteria.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFFB7D6C9),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 36),

              // Checklist
              _buildStepItem(
                title: 'Audio format and length check',
                isDone: _step >= 2,
                isLoading: _step == 1,
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                title: 'Speech recognition & transcription',
                isDone: _step >= 3,
                isLoading: _step == 2,
              ),
              const SizedBox(height: 16),
              _buildStepItem(
                title: 'Escrow release instruction',
                isDone: false,
                isLoading: _step == 3,
              ),

              const Spacer(),

              Center(
                child: Text(
                  'Average validation time: 2.4s',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFB7D6C9),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem({
    required String title,
    required bool isDone,
    required bool isLoading,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          if (isDone)
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Symbols.check, size: 18, color: AppColors.ink),
            )
          else if (isLoading)
            const SizedBox(
              width: 28,
              height: 28,
              child: Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.mint),
                ),
              ),
            )
          else
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDone || isLoading ? Colors.white : const Color(0xFF9EC5B6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 2. Task Paid Screen (Success)
// ==========================================
class TaskPaidScreen extends StatelessWidget {
  const TaskPaidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: Stack(
        children: [
          // Background Glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.2),
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

          // Floating D Coin
          Positioned(
            left: 0,
            right: 0,
            top: 150,
            child: Center(
              child: Transform.rotate(
                angle: -12 * math.pi / 180,
                child: const MintDCoin(size: 132),
              ),
            ),
          ),

          // Confetti particles simulated
          Positioned(
            left: 50,
            top: 130,
            child: Transform.rotate(
              angle: 20 * math.pi / 180,
              child: Container(
                width: 12,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Positioned(
            right: 60,
            top: 170,
            child: Transform.rotate(
              angle: -30 * math.pi / 180,
              child: Container(
                width: 12,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.butter,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          Positioned(
            left: 100,
            top: 300,
            child: Transform.rotate(
              angle: 50 * math.pi / 180,
              child: Container(
                width: 12,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),

          // Center Payout Text
          Positioned(
            left: 24,
            right: 24,
            top: 312,
            child: Column(
              children: [
                Text(
                  'Task approved',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFB7D6C9),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '+0.50',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 68,
                    fontWeight: FontWeight.w500,
                    height: 1.0,
                    letterSpacing: -2.5,
                    color: AppColors.mint,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'cUSD paid to your wallet',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/receipt'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'View on Celo explorer',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Symbols.open_in_new, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Summary Glass Card
          Positioned(
            left: 24,
            right: 24,
            top: 540,
            child: MintGlassCard(
              isDark: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                children: [
                  _buildSummaryRow('New balance', '\$25.00'),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Earned today', '1.35 cUSD'),
                  const SizedBox(height: 12),
                  _buildSummaryRow('Streak', '5 days'),
                ],
              ),
            ),
          ),

          // Bottom Buttons
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Column(
              children: [
                MintButton(
                  label: 'Next task',
                  icon: Symbols.arrow_forward,
                  onPressed: () => context.go('/tasks/task-detail'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Back to home',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: const Color(0xFFCFE6DC),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 3. Task Rejected Screen (Not Approved)
// ==========================================
class TaskRejectedScreen extends StatelessWidget {
  const TaskRejectedScreen({super.key});

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
              MintBackButton(
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 28),

              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.peach,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Symbols.graphic_eq, size: 32, color: AppColors.ink),
              ),
              const SizedBox(height: 20),

              Text(
                'Almost there',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We couldn’t hear your phrase clearly, so it wasn’t approved this time.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.text,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // Feedback Checklist
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.peach,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Symbols.priority_high, size: 18, color: AppColors.ink),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Background noise was high',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Try a quieter spot or move away from fans.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppColors.line, height: 1),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: AppColors.mint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Symbols.check, size: 18, color: AppColors.ink),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Phrase matched',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'You said it correctly.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Symbols.lock, size: 22, color: Color(0xFF087A52)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your 0.50 cUSD reward stays safe in escrow. Nothing is lost if you try again.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.text,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),

              const Spacer(),

              MintButton(
                label: 'Try again',
                icon: Symbols.mic,
                onPressed: () => context.go('/tasks/voice/ready'),
              ),
              const SizedBox(height: 8),
              MintButton(
                label: 'Skip this task',
                variant: MintButtonVariant.text,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
