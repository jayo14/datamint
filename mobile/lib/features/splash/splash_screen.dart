import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';
import '../../shared/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _loadController;
  Timer? _navTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _loadController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..forward();

    _navTimer = Timer(const Duration(milliseconds: 2600), _navigateNext);
  }

  void _navigateNext() {
    if (!mounted) return;
    final currentUser = ref.read(currentUserProvider).value;
    if (currentUser != null) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _loadController.dispose();
    _navTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _navigateNext,
      child: Scaffold(
        backgroundColor: AppColors.forest,
        body: Stack(
          children: [
            // Radial Glow Backgrounds
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.08),
                    radius: 0.8,
                    colors: [
                      AppColors.mint.withValues(alpha: 0.38),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.52],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              width: 300,
              height: 300,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.8, -0.8),
                    radius: 0.7,
                    colors: [
                      const Color(0xFFFFE08A).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.45],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              width: 320,
              height: 320,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.8, 0.8),
                    radius: 0.7,
                    colors: [
                      const Color(0xFF5FD6E8).withValues(alpha: 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.5],
                  ),
                ),
              ),
            ),

            // Expanding Ripple Rings
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.mint.withValues(alpha: 0.25),
                            width: 1.5,
                          ),
                        ),
                      ),
                      Container(
                        width: 280,
                        height: 280,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.mint.withValues(alpha: 0.15),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Center Floating Coin
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final dy = math.sin(_pulseController.value * math.pi * 2) * 8.0;
                    return Transform.translate(
                      offset: Offset(0, dy),
                      child: Transform.rotate(
                        angle: -12 * math.pi / 180,
                        child: const MintDCoin(size: 176),
                      ),
                    );
                  },
                ),
              ),
            ),

            // App Name & Tagline
            Positioned(
              left: 24,
              right: 24,
              top: 500,
              child: Column(
                children: [
                  Text(
                    'datamint',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -1.5,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Human knowledge, paid instantly.',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFB7D6C9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Progress Loading Indicator Bar
            Positioned(
              left: 96,
              right: 96,
              bottom: 92,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: AnimatedBuilder(
                  animation: _loadController,
                  builder: (context, child) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _loadController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.mint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Built on Celo Footer
            Positioned(
              left: 0,
              right: 0,
              bottom: 48,
              child: Text(
                'Built on Celo',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFFB7D6C9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
