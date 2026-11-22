import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/providers/app_providers.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _walletController = TextEditingController();

  String _selectedRole = 'BOTH';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _walletController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        displayName: _displayNameController.text.trim().isNotEmpty
            ? _displayNameController.text.trim()
            : null,
        walletAddress: _walletController.text.trim().isNotEmpty
            ? _walletController.text.trim()
            : null,
      );

      ref.read(currentUserProvider.notifier).setUser(user);
      if (mounted) {
        context.go('/home');
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Registration failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mintBg,
      body: Stack(
        children: [
          // Ambient background glow circles matching landing hero
          const Positioned(
            top: -40,
            left: -40,
            child: FloatingCoinGlow(
              size: 220,
              color: AppColors.mint,
              opacity: 0.45,
            ),
          ),
          const Positioned(
            bottom: -50,
            right: -40,
            child: FloatingCoinGlow(
              size: 240,
              color: AppColors.yellowAccent,
              opacity: 0.35,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  // Top Navigation Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/login');
                          }
                        },
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.ink,
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.8),
                          side: const BorderSide(
                            color: AppColors.mintBorder,
                            width: 1.2,
                          ),
                        ),
                      ),
                      const DataMintLogo(size: 32),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.mintBorder,
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Step 1 of 2',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Main White Auth Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.mintBorder,
                        width: 1.4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.ink.withValues(alpha: 0.07),
                          blurRadius: 30,
                          offset: const Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pill Badge
                          const Center(
                            child: PillBadge(
                              text: 'Decentralized Protocol',
                              icon: Icons.verified_user_outlined,
                              badgeColor: AppColors.mintBg,
                              borderColor: AppColors.mintBorder,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Header Title
                          Center(
                            child: Text(
                              'Join DataMint',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.ink,
                                letterSpacing: -0.6,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle
                          Center(
                            child: Text(
                              'Participate in the decentralized AI data economy on Celo',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.error.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 16),
                                    color: AppColors.error,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        setState(() => _errorMessage = null),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Role Selector Cards
                          const Text(
                            'Account Capability',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 3 Role Cards
                          _buildRoleOption(
                            roleKey: 'BOTH',
                            title: 'Dual Role (Recommended)',
                            subtitle:
                                'Earn cUSD for data & publish dataset campaigns',
                            icon: Icons.all_inclusive_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildRoleOption(
                            roleKey: 'CONTRIBUTOR',
                            title: 'Contributor',
                            subtitle:
                                'Earn instant Celo cUSD by providing voice, image & text data',
                            icon: Icons.paid_rounded,
                          ),
                          const SizedBox(height: 8),
                          _buildRoleOption(
                            roleKey: 'CREATOR',
                            title: 'AI Creator / Team',
                            subtitle:
                                'Publish data requests, fund escrow & export AI datasets',
                            icon: Icons.psychology_rounded,
                          ),
                          const SizedBox(height: 18),

                          // Display Name
                          const Text(
                            'Display Name (Optional)',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _displayNameController,
                            decoration: const InputDecoration(
                              hintText: 'Alex Rivera',
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                size: 20,
                                color: AppColors.mintActive,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Email
                          const Text(
                            'Email Address',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'alex@datamint.ai',
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                size: 20,
                                color: AppColors.mintActive,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password
                          const Text(
                            'Password',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText:
                                  'Minimum ${AppConstants.minPasswordLength} characters',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: AppColors.mintActive,
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  size: 20,
                                  color: AppColors.textMuted,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < AppConstants.minPasswordLength) {
                                return 'Password must be at least ${AppConstants.minPasswordLength} characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Celo Wallet Address
                          const Text(
                            'Celo Wallet Address (Optional)',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _walletController,
                            decoration: const InputDecoration(
                              hintText: '0x...',
                              prefixIcon: Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 20,
                                color: AppColors.mintActive,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Register Button
                          DataMintButton(
                            label: 'Create Account',
                            icon: Icons.how_to_reg_rounded,
                            width: double.infinity,
                            isLoading: _isLoading,
                            onPressed: _handleRegister,
                          ),
                          const SizedBox(height: 18),

                          // Footer Links
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.mintActive,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  child: const Text('Sign In'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOption({
    required String roleKey,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == roleKey;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = roleKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.mintBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.mintActive : AppColors.mintBorder,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.mintActive.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.mintActive : AppColors.mintBg,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : AppColors.mintActive,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.mintActive,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
