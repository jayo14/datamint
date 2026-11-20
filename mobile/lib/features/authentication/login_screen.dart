import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../../core/errors/app_exception.dart';
import '../../core/widgets/common_widgets.dart';
import '../../shared/providers/app_providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'contributor'; // 'contributor' or 'creator'
  bool _isLoading = false;
  bool _isSiweLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final user = await authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      ref.read(currentUserProvider.notifier).setUser(user);
      if (mounted) {
        context.go('/home');
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() =>
          _errorMessage = 'Authentication failed. Please verify credentials.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSiweLogin() async {
    setState(() {
      _isSiweLoading = true;
      _errorMessage = null;
    });

    try {
      final walletService = ref.read(walletServiceProvider);
      final authService = ref.read(authServiceProvider);

      // 1. Connect wallet if not already connected
      final address = await walletService.connect();

      // 2. Request SIWE challenge from backend
      final challenge = await authService.getSiweChallenge(address: address);
      final message = challenge['message'] as String;

      // 3. Contributor/Creator signs challenge message with their private key
      final signature = await walletService.signPersonalMessage(message);

      // 4. Submit to backend for verification and JWT generation
      final user = await authService.verifySiwe(
        message: message,
        signature: signature,
      );

      ref.read(currentUserProvider.notifier).setUser(user);
      ref.read(walletStateProvider.notifier).refreshBalances(address);

      if (mounted) {
        context.go('/home');
      }
    } on AppException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Wallet sign-in failed: $e');
    } finally {
      if (mounted) setState(() => _isSiweLoading = false);
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
                            context.go('/onboarding');
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(
                                color: AppColors.mintActive,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'CELO L2',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
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
                              text: 'Decentralized Identity',
                              icon: Icons.lock_outline_rounded,
                              badgeColor: AppColors.mintBg,
                              borderColor: AppColors.mintBorder,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Header Title
                          Center(
                            child: Text(
                              'Welcome to DataMint',
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
                              'Sign in to contribute data, manage datasets, and claim instant escrow payouts on Celo.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: AppColors.textMuted,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Role Selector Tabs (Contributor vs Creator)
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.mintBg,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.mintBorder.withValues(alpha: 0.7),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedRole = 'contributor'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == 'contributor'
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _selectedRole == 'contributor'
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.ink.withValues(alpha: 0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.paid_rounded,
                                            size: 16,
                                            color: _selectedRole == 'contributor'
                                                ? AppColors.mintActive
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Contributor',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _selectedRole == 'contributor'
                                                  ? AppColors.ink
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _selectedRole = 'creator'),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedRole == 'creator'
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _selectedRole == 'creator'
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.ink.withValues(alpha: 0.06),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.psychology_rounded,
                                            size: 16,
                                            color: _selectedRole == 'creator'
                                                ? AppColors.mintActive
                                                : AppColors.textMuted,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'AI Creator',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: _selectedRole == 'creator'
                                                  ? AppColors.ink
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Web3 SIWE Wallet Button (Outlined pill)
                          DataMintButton(
                            label: 'Sign In with Celo Wallet (SIWE)',
                            isOutlined: true,
                            icon: Icons.account_balance_wallet_outlined,
                            color: AppColors.celoGold,
                            width: double.infinity,
                            isLoading: _isSiweLoading,
                            onPressed: _handleSiweLogin,
                          ),
                          const SizedBox(height: 18),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                child: Divider(
                                  color: AppColors.mintBorder,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  'OR CONTINUE WITH EMAIL',
                                  style: TextStyle(
                                    color: AppColors.textMuted.withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                              const Expanded(
                                child: Divider(
                                  color: AppColors.mintBorder,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

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
                                    onPressed: () => setState(() => _errorMessage = null),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email Field
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
                              hintText: 'contributor@datamint.ai',
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

                          // Password Field
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
                              hintText: '••••••••',
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
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),

                          // Primary Sign In Button
                          DataMintButton(
                            label: 'Sign In',
                            icon: Icons.login_rounded,
                            width: double.infinity,
                            isLoading: _isLoading,
                            onPressed: _handleEmailLogin,
                          ),
                          const SizedBox(height: 18),

                          // Footer Links
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  "Don't have an account?",
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/register'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.mintActive,
                                    textStyle: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  child: const Text('Create Account'),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),
                          Divider(
                            color: AppColors.mintBorder.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 8),

                          Center(
                            child: Text(
                              'By signing in, you agree to the DataMint Smart Escrow Terms and AI Verification Guidelines.',
                              style: TextStyle(
                                color: AppColors.textMuted.withValues(alpha: 0.75),
                                fontSize: 11,
                                height: 1.35,
                              ),
                              textAlign: TextAlign.center,
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
}
