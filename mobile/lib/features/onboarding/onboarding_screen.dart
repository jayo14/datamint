import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
      'icon': Icons.dataset_rounded,
      'title': 'Decentralized AI Dataset Marketplace',
      'description':
          'Connect directly with AI researchers and dataset creators. Provide high-quality data or source labeled data with cryptographic escrow.',
    },
    {
      'icon': Icons.bolt_rounded,
      'title': 'Real-Time Multi-Modal AI Validation',
      'description':
          'Instant technical and semantic verification for Text, Audio, and Image submissions with transparent audit findings.',
    },
    {
      'icon': Icons.account_balance_wallet_rounded,
      'title': 'Instant On-Chain cUSD Payouts',
      'description':
          'Automated EIP-712 reward vouchers settled trustlessly on Celo. Zero intermediary delays, full cryptographic provenance.',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            children: [
              // Top Brand Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.mintPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.token_rounded,
                          color: AppColors.mintPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'DataMint',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const Spacer(),
              // Carousel
              SizedBox(
                height: 380,
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (idx) => setState(() => _currentIndex = idx),
                  itemCount: _pages.length,
                  itemBuilder: (context, idx) {
                    final item = _pages[idx];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.darkCard
                                : AppColors.mintPrimary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.mintPrimary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            item['icon'] as IconData,
                            size: 56,
                            color: AppColors.mintPrimary,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          item['title'] as String,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          item['description'] as String,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : AppColors.lightTextSecondary,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const Spacer(),
              // Page indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentIndex == index
                          ? AppColors.mintPrimary
                          : (isDark ? AppColors.darkBorder : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              // Action Buttons
              DataMintButton(
                label: _currentIndex == _pages.length - 1
                    ? 'Get Started'
                    : 'Continue',
                width: double.infinity,
                onPressed: () {
                  if (_currentIndex < _pages.length - 1) {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go('/register');
                  }
                },
              ),
              const SizedBox(height: 12),
              DataMintButton(
                label: 'Sign In to Existing Account',
                isOutlined: true,
                width: double.infinity,
                onPressed: () => context.go('/login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
