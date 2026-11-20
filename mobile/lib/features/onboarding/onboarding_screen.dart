import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'badge': 'Audited Smart Escrow',
      'badgeIcon': Icons.shield_outlined,
      'icon': Icons.dataset_rounded,
      'title': 'Decentralized AI Dataset Marketplace',
      'description':
          'Connect directly with AI researchers and dataset creators. Provide high-quality voice, image, and text data with trustless cryptographic escrow.',
      'tags': ['Voice Data', 'Image Capture', 'Text Labeling'],
    },
    {
      'badge': 'Sub-Second Verification',
      'badgeIcon': Icons.bolt_rounded,
      'icon': Icons.verified_user_rounded,
      'title': 'Real-Time Multi-Modal AI Validation',
      'description':
          'Instant technical and semantic verification for every submission with transparent audit findings and automated quality grading.',
      'tags': ['Automated QA', 'Quality Score', 'Zero Fraud'],
    },
    {
      'badge': 'Instant cUSD Settlement',
      'badgeIcon': Icons.account_balance_wallet_rounded,
      'icon': Icons.payments_rounded,
      'title': 'Sub-Second On-Chain Escrow Payouts',
      'description':
          'Automated EIP-712 reward vouchers settled trustlessly on Celo L2. Zero intermediary delays, full cryptographic provenance.',
      'tags': ['Celo cUSD', 'MiniPay Friendly', 'Instant Gasless'],
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentIndex < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      context.go('/register');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBg,
      body: Stack(
        children: [
          // Ambient background glow circles matching landing hero
          Positioned(
            top: -40,
            left: -40,
            child: FloatingCoinGlow(
              size: 220,
              color: AppColors.mint,
              opacity: 0.4,
            ),
          ),
          Positioned(
            bottom: -60,
            right: -40,
            child: FloatingCoinGlow(
              size: 240,
              color: AppColors.yellowAccent,
              opacity: 0.3,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top Brand Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const DataMintLogo(size: 32),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                            side: const BorderSide(
                              color: AppColors.mintBorder,
                              width: 1.2,
                            ),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Carousel in Expanded to prevent any overflow on smaller viewports
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      onPageChanged: (idx) => setState(() => _currentIndex = idx),
                      itemCount: _pages.length,
                      itemBuilder: (context, idx) {
                        final item = _pages[idx];
                        return Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: AppColors.mintBorder,
                                  width: 1.4,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.ink.withValues(alpha: 0.06),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Floating tag pill
                                  PillBadge(
                                    text: item['badge'] as String,
                                    icon: item['badgeIcon'] as IconData,
                                    badgeColor: AppColors.mintBg,
                                    borderColor: AppColors.mintBorder,
                                  ),
                                  const SizedBox(height: 16),

                                  // Central Feature Icon
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: AppColors.mint,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.mintActive.withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      item['icon'] as IconData,
                                      size: 38,
                                      color: AppColors.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Title
                                  Text(
                                    item['title'] as String,
                                    style: GoogleFonts.bricolageGrotesque(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.ink,
                                      letterSpacing: -0.4,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 10),

                                  // Description
                                  Text(
                                    item['description'] as String,
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: AppColors.textMuted,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 14),

                                  // Tags Row
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    alignment: WrapAlignment.center,
                                    children: (item['tags'] as List<String>).map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 3.5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.mintBg,
                                          borderRadius: BorderRadius.circular(999),
                                          border: Border.all(
                                            color: AppColors.mintBorder,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          tag,
                                          style: const TextStyle(
                                            color: AppColors.mintActive,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bottom Controls
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Step Pill Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_pages.length, (idx) {
                          final isSelected = _currentIndex == idx;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 7,
                            width: isSelected ? 26 : 7,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.mintActive
                                  : AppColors.mintBorder,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16),

                      // Primary Button
                      DataMintButton(
                        label: _currentIndex == _pages.length - 1
                            ? 'Get Started'
                            : 'Continue',
                        icon: _currentIndex == _pages.length - 1
                            ? Icons.rocket_launch_rounded
                            : Icons.arrow_forward_rounded,
                        width: double.infinity,
                        onPressed: _onNext,
                      ),
                      const SizedBox(height: 10),

                      // Secondary Sign In Button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Already have an account? ',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(
                                color: AppColors.mintActive,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
