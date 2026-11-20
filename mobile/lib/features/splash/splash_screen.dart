import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/providers/app_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();

    _navigationTimer = Timer(const Duration(milliseconds: 1800), () {
      _checkAuthAndNavigate();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _navigationTimer?.cancel();
    super.dispose();
  }

  void _checkAuthAndNavigate() {
    if (!mounted) return;
    final currentUserAsync = ref.read(currentUserProvider);
    final isAuthenticated = currentUserAsync.value != null;

    if (isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _checkAuthAndNavigate,
        child: Stack(
          children: [
            // Ambient glowing coins matching landing hero
            const Positioned(
              top: -40,
              left: -40,
              child: FloatingCoinGlow(
                size: 240,
                color: AppColors.mint,
                opacity: 0.45,
              ),
            ),
            const Positioned(
              bottom: -50,
              right: -50,
              child: FloatingCoinGlow(
                size: 260,
                color: AppColors.yellowAccent,
                opacity: 0.35,
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.35,
              right: -30,
              child: const FloatingCoinGlow(
                size: 160,
                color: AppColors.blueAccent,
                opacity: 0.25,
              ),
            ),

            // Content
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Spacer(),

                      // Animated Logo Emblem
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Pulsing halo ring
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.mint.withValues(alpha: 0.6),
                                  width: 2,
                                ),
                              ),
                            ),
                            Container(
                              width: 86,
                              height: 86,
                              decoration: BoxDecoration(
                                color: AppColors.mint,
                                borderRadius: BorderRadius.circular(26),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.mintActive.withValues(alpha: 0.35),
                                    blurRadius: 28,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                '⌘',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.ink,
                                  height: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Brand Title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DataMint',
                                  style: GoogleFonts.bricolageGrotesque(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.ink,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(left: 4, top: 18),
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.mintActive,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Decentralized AI Dataset Marketplace',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textMuted,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Badge
                            const PillBadge(
                              text: 'Celo L2 • Audited Smart Escrow',
                              icon: Icons.shield_outlined,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // Loading indicator & Protocol notes
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.mintActive,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              'Sub-Second Payouts • AI-Validated Data',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textMuted.withValues(alpha: 0.8),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
