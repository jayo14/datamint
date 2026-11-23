import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

class TaskDetailScreen extends StatelessWidget {
  final String? campaignId;

  const TaskDetailScreen({
    super.key,
    this.campaignId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MintBackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.line),
                        ),
                        child: const Icon(Symbols.bookmark, size: 22, color: AppColors.ink),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Main Highlight Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      gradient: const RadialGradient(
                        center: Alignment(-0.6, -0.8),
                        radius: 0.9,
                        colors: [Color(0xFFB6F5D9), Color(0xFF74E3B6)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Symbols.mic, size: 24, color: AppColors.ink),
                            ),
                            const SizedBox(width: 10),
                            const MintTypePill(
                              type: MintPillType.voice,
                              customLabel: 'VOICE',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Say a short phrase in your native accent',
                          style: GoogleFonts.bricolageGrotesque(
                            fontSize: 30,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildInfoChip(Symbols.schedule, '~30s'),
                            _buildInfoChip(Symbols.groups, '124 spots left'),
                            _buildInfoChip(Symbols.verified, 'Verified builder'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '0.50',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 52,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                letterSpacing: -1.8,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'cUSD',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // "How you get paid" Section
                  Text(
                    'How you get paid',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stepper Strip
                  Row(
                    children: [
                      _buildStepCircle(Symbols.lock, isComplete: true),
                      const Expanded(child: Divider(color: AppColors.line, thickness: 2)),
                      _buildStepCircle(Symbols.mic, isComplete: false),
                      const Expanded(child: Divider(color: AppColors.line, thickness: 2)),
                      _buildStepCircle(Symbols.verified, isComplete: false),
                      const Expanded(child: Divider(color: AppColors.line, thickness: 2)),
                      _buildStepCircle(Symbols.paid, isComplete: false),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStepLabel('Funded'),
                      _buildStepLabel('Record'),
                      _buildStepLabel('Validate'),
                      _buildStepLabel('Paid'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'The builder has already locked 0.50 cUSD in escrow. It releases to your wallet when GPT-4o approves your recording.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.text,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // "Before you start" Section
                  Text(
                    'Before you start',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.sky,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Symbols.volume_off, size: 20, color: AppColors.ink),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Find a quiet spot',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.butter,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Symbols.record_voice_over, size: 20, color: AppColors.ink),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Speak naturally, in your own accent',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Sticky Action
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.mist.withValues(alpha: 0.0),
                      AppColors.mist,
                    ],
                    stops: const [0.0, 0.3],
                  ),
                ),
                child: MintButton(
                  label: 'Start task',
                  icon: Symbols.mic,
                  onPressed: () => context.push('/tasks/voice/ready'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.ink),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(IconData icon, {required bool isComplete}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isComplete ? AppColors.mint : Colors.white,
        shape: BoxShape.circle,
        border: Border.all(
          color: isComplete ? AppColors.mint : AppColors.line,
          width: 1.5,
        ),
      ),
      child: Icon(
        icon,
        size: 20,
        color: isComplete ? AppColors.ink : AppColors.text,
      ),
    );
  }

  Widget _buildStepLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
    );
  }
}
