import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

// ==========================================
// 1. Photo 1 · Capture Screen
// ==========================================
class PhotoCaptureScreen extends StatefulWidget {
  const PhotoCaptureScreen({super.key});

  @override
  State<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends State<PhotoCaptureScreen> {
  bool _flashOn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Top Prompt Card
            Positioned(
              top: 16,
              left: 20,
              right: 20,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Symbols.close, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Photograph a street sign',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Viewfinder with Corner Guides
            Center(
              child: Container(
                width: 320,
                height: 420,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                ),
                child: Stack(
                  children: [
                    // Simulated Camera Feed Preview
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.grey.shade900,
                            Colors.grey.shade800,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Symbols.photo_camera, size: 48, color: Colors.white54),
                            const SizedBox(height: 12),
                            Text(
                              'Center sign inside guides',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 4 Corner Brackets
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.mint, width: 4),
                            left: BorderSide(color: AppColors.mint, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppColors.mint, width: 4),
                            right: BorderSide(color: AppColors.mint, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.mint, width: 4),
                            left: BorderSide(color: AppColors.mint, width: 4),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.mint, width: 4),
                            right: BorderSide(color: AppColors.mint, width: 4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Shutter Controls
            Positioned(
              left: 0,
              right: 0,
              bottom: 34,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _flashOn = !_flashOn),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _flashOn ? Symbols.flash_on : Symbols.flash_off,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  // White circular Shutter Button
                  GestureDetector(
                    onTap: () => context.go('/tasks/photo/review'),
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 5),
                      ),
                      child: Center(
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Symbols.flip_camera_ios,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. Photo 2 · Review Screen
// ==========================================
class PhotoReviewScreen extends StatelessWidget {
  const PhotoReviewScreen({super.key});

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
                          '0.35 cUSD',
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
              const SizedBox(height: 20),

              Text(
                'Review your photo',
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
                'Make sure the sign text is sharp and readable.',
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.text),
              ),
              const SizedBox(height: 20),

              // Captured Image Preview Box
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.ink,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Symbols.photo, size: 48, color: AppColors.mint),
                      const SizedBox(height: 8),
                      Text(
                        'Marina Rd, Lagos Island',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Automated AI Checks
              Text(
                'Automated quality checks',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              _buildQualityCheck('In focus and sharp'),
              const SizedBox(height: 10),
              _buildQualityCheck('Text readable'),
              const SizedBox(height: 10),
              _buildQualityCheck('Good lighting'),

              const Spacer(),

              // Retake & Submit
              Row(
                children: [
                  Expanded(
                    child: MintButton(
                      label: 'Retake',
                      icon: Symbols.replay,
                      variant: MintButtonVariant.ghost,
                      onPressed: () => context.go('/tasks/photo/capture'),
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
