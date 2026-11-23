import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

// ==========================================
// 1. Voice 1 · Ready Screen
// ==========================================
class VoiceReadyScreen extends StatelessWidget {
  const VoiceReadyScreen({super.key});

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
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MintBackButton(
                    onPressed: () => context.go('/home'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.paid, size: 18, color: Color(0xFF087A52)),
                        const SizedBox(width: 6),
                        Text(
                          '0.50 cUSD',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const MintTypePill(type: MintPillType.voice),
              const SizedBox(height: 12),
              Text(
                'Say this phrase out loud',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),

              // Quote Prompt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“The quick brown fox jumps over the lazy dog.”',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Use your natural, everyday accent.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Noise Check
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Symbols.volume_mute, size: 20, color: Color(0xFF087A52)),
                      const SizedBox(width: 8),
                      Text(
                        'Background noise',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'Low',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF087A52),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.18,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Record Button
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/tasks/voice/recording'),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.mint.withValues(alpha: 0.4),
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Symbols.mic,
                          size: 40,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tap to start recording',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. Voice 2 · Recording Screen
// ==========================================
class VoiceRecordingScreen extends StatefulWidget {
  const VoiceRecordingScreen({super.key});

  @override
  State<VoiceRecordingScreen> createState() => _VoiceRecordingScreenState();
}

class _VoiceRecordingScreenState extends State<VoiceRecordingScreen> {
  int _seconds = 8;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _seconds++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

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
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MintBackButton(
                    onPressed: () => _showDiscardDialog(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.paid, size: 18, color: Color(0xFF087A52)),
                        const SizedBox(width: 6),
                        Text(
                          '0.50 cUSD',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const MintTypePill(type: MintPillType.voice),
              const SizedBox(height: 12),
              Text(
                'Say this phrase out loud',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),

              // Quote Prompt Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: AppColors.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“The quick brown fox jumps over the lazy dog.”',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Use your natural, everyday accent.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dark Container with Waveform
              Container(
                height: 110,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(28),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.alert,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_formattedTime · Recording...',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const MintWaveform(isRecording: true, barCount: 24),
                  ],
                ),
              ),

              const Spacer(),

              // Stop Recording Button
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/tasks/voice/review'),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.alert.withValues(alpha: 0.35),
                              spreadRadius: 12,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Symbols.stop,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tap when done',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  void _showDiscardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Discard recording?',
          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Your current audio will not be saved.',
          style: GoogleFonts.inter(color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('Discard', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. Voice 3 · Review Screen
// ==========================================
class VoiceReviewScreen extends StatefulWidget {
  const VoiceReviewScreen({super.key});

  @override
  State<VoiceReviewScreen> createState() => _VoiceReviewScreenState();
}

class _VoiceReviewScreenState extends State<VoiceReviewScreen> {
  bool _isPlaying = false;
  double _playbackPosition = 0.35;

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
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  MintBackButton(
                    onPressed: () => context.go('/tasks/voice/ready'),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Symbols.paid, size: 18, color: Color(0xFF087A52)),
                        const SizedBox(width: 6),
                        Text(
                          '0.50 cUSD',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Text(
                'Review your recording',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Listen back and confirm you can hear every word clearly.',
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.text),
              ),
              const SizedBox(height: 24),

              // Player Scrubber Card
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
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isPlaying = !_isPlaying),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              color: AppColors.mint,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Symbols.pause : Symbols.play_arrow,
                              size: 28,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.ink,
                                  inactiveTrackColor: AppColors.line,
                                  thumbColor: AppColors.ink,
                                  trackHeight: 6,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                                ),
                                child: Slider(
                                  value: _playbackPosition,
                                  onChanged: (v) => setState(() => _playbackPosition = v),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '0:04',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.text),
                                    ),
                                    Text(
                                      '0:12',
                                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.text),
                                    ),
                                  ],
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

              // Automated Quality Checks
              Text(
                'Automated checks',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildQualityCheck('Loud and clear'),
              const SizedBox(height: 10),
              _buildQualityCheck('Low background noise'),
              const SizedBox(height: 10),
              _buildQualityCheck('Phrase matches text'),

              const Spacer(),

              // Actions: Re-record & Submit
              Row(
                children: [
                  Expanded(
                    child: MintButton(
                      label: 'Re-record',
                      icon: Symbols.replay,
                      variant: MintButtonVariant.ghost,
                      onPressed: () => context.go('/tasks/voice/ready'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MintButton(
                      label: 'Submit',
                      onPressed: () => context.go('/tasks/validating'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQualityCheck(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
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
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
        ],
      ),
    );
  }
}
