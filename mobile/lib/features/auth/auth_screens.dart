import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';
import '../../shared/providers/app_providers.dart';

// ==========================================
// 1. Auth 1 · Welcome Screen
// ==========================================
class AuthWelcomeScreen extends ConsumerWidget {
  const AuthWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              // Visual Card
              Container(
                height: 312,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(44),
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 0.2),
                    radius: 0.9,
                    colors: [
                      AppColors.mint.withValues(alpha: 0.4),
                      AppColors.forest,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: 22,
                      top: 22,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.mint,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'D',
                              style: GoogleFonts.bricolageGrotesque(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'datamint',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Center(
                      child: Transform.rotate(
                        angle: -12 * math.pi / 180,
                        child: const MintDCoin(size: 150),
                      ),
                    ),
                    Positioned(
                      left: 22,
                      bottom: 26,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Symbols.mic, size: 20, color: AppColors.ink),
                            const SizedBox(width: 8),
                            Text(
                              'Voice',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      right: 22,
                      bottom: 50,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            const Icon(Symbols.photo_camera, size: 20, color: AppColors.ink),
                            const SizedBox(width: 8),
                            Text(
                              'Image',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Copy Block
              Text(
                'Earn while you teach AI.',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to start finishing short tasks and getting paid in cUSD.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Action Buttons
              MintButton(
                label: 'Continue with MiniPay',
                icon: Symbols.account_balance_wallet,
                onPressed: () {
                  ref.read(walletServiceProvider).connect();
                  context.go('/auth/profile');
                },
              ),
              const SizedBox(height: 10),
              MintButton(
                label: 'Connect another wallet',
                icon: Symbols.link,
                variant: MintButtonVariant.ghost,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AuthWalletSheet(),
                  );
                },
              ),
              const SizedBox(height: 10),
              MintButton(
                label: 'Use phone or email',
                variant: MintButtonVariant.text,
                onPressed: () => context.go('/auth/phone'),
              ),
              const SizedBox(height: 12),
              Text(
                'By continuing you agree to the Terms and Privacy Policy.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.text,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. Auth 2 · Phone Screen
// ==========================================
class AuthPhoneScreen extends StatefulWidget {
  const AuthPhoneScreen({super.key});

  @override
  State<AuthPhoneScreen> createState() => _AuthPhoneScreenState();
}

class _AuthPhoneScreenState extends State<AuthPhoneScreen> {
  int _authMethod = 0; // 0 = Phone, 1 = Email
  final TextEditingController _phoneController =
      TextEditingController(text: '803 123 4567');
  final TextEditingController _emailController =
      TextEditingController(text: 'amina@datamint.io');

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Progress Strip (Step 1 of 3)
              Row(
                children: [
                  MintBackButton(
                    onPressed: () => context.go('/auth/welcome'),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: MintStepProgress(totalSteps: 3, currentStep: 1),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                _authMethod == 0
                    ? 'What’s your phone number?'
                    : 'What’s your email address?',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _authMethod == 0
                    ? 'We’ll text you a 6-digit code. No passwords to remember.'
                    : 'We’ll email you a 6-digit verification code.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 28),

              // Segmented Control
              MintSegmentedControl(
                options: const ['Phone', 'Email'],
                selectedIndex: _authMethod,
                onSelected: (index) => setState(() => _authMethod = index),
              ),
              const SizedBox(height: 20),

              // Input field
              if (_authMethod == 0) ...[
                Text(
                  'Phone number',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.line, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'NG +234',
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Symbols.expand_more, size: 20, color: AppColors.ink),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MintInput(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Standard message rates may apply.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                ),
              ] else ...[
                Text(
                  'Email address',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 8),
                MintInput(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Symbols.mail,
                ),
              ],

              const SizedBox(height: 32),

              // Divider "or"
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'or',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.line, thickness: 1)),
                ],
              ),
              const SizedBox(height: 14),

              MintButton(
                label: 'Continue with a wallet',
                icon: Symbols.account_balance_wallet,
                variant: MintButtonVariant.ghost,
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AuthWalletSheet(),
                  );
                },
              ),
              const SizedBox(height: 12),

              MintButton(
                label: 'Send code',
                onPressed: () => context.go('/auth/otp'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. Auth 3 · OTP Screen
// ==========================================
class AuthOtpScreen extends StatefulWidget {
  const AuthOtpScreen({super.key});

  @override
  State<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends State<AuthOtpScreen> {
  String _code = '482';

  void _onKeyPress(String key) {
    if (_code.length < 6) {
      setState(() => _code += key);
      if (_code.length == 6) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) context.go('/auth/profile');
        });
      }
    }
  }

  void _onBackspace() {
    if (_code.isNotEmpty) {
      setState(() => _code = _code.substring(0, _code.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      MintBackButton(
                        onPressed: () => context.go('/auth/phone'),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: MintStepProgress(totalSteps: 3, currentStep: 1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Enter the 6-digit code',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 31,
                      fontWeight: FontWeight.w500,
                      height: 1.1,
                      letterSpacing: -0.9,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        'Sent to +234 803 123 4567. ',
                        style: GoogleFonts.inter(fontSize: 16, color: AppColors.text),
                      ),
                      GestureDetector(
                        onTap: () => context.go('/auth/phone'),
                        child: Text(
                          'Edit',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.mintDeep,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // 6 OTP boxes
                  GestureDetector(
                    onTap: () => context.go('/auth/profile'),
                    child: MintOtpBoxes(
                      length: 6,
                      value: _code,
                    ),
                  ),
                  const SizedBox(height: 18),

                  Row(
                    children: [
                      const Icon(Symbols.schedule, size: 20, color: AppColors.text),
                      const SizedBox(width: 8),
                      Text(
                        'Resend code in 0:24',
                        style: GoogleFonts.inter(fontSize: 15, color: AppColors.text),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  MintGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Symbols.sms, size: 22, color: AppColors.mintDeep),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Codes fill in automatically when your SMS arrives.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.ink,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),

            // Custom Numeric Keypad
            MintNumericKeypad(
              showDot: false,
              onKeyPress: _onKeyPress,
              onBackspace: _onBackspace,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. Auth 4 · Wallet Bottom Sheet
// ==========================================
class AuthWalletSheet extends ConsumerWidget {
  const AuthWalletSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFC9DFD4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Connect a wallet',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 26,
              fontWeight: FontWeight.w500,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Choose where your cUSD earnings should land.',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 20),

          // MiniPay Row
          GestureDetector(
            onTap: () {
              ref.read(walletServiceProvider).connect();
              Navigator.pop(context);
              context.go('/auth/profile');
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.mint.withValues(alpha: 0.5),
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Symbols.account_balance_wallet,
                        size: 24, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MiniPay',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Fastest option on Celo',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const MintTypePill(
                    type: MintPillType.voice,
                    customLabel: 'RECOMMENDED',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Other Celo Wallets
          GestureDetector(
            onTap: () {
              ref.read(walletServiceProvider).connect();
              Navigator.pop(context);
              context.go('/auth/profile');
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.butter,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Symbols.hub, size: 24, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Other Celo wallets',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'Connect with WalletConnect',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Symbols.chevron_right, size: 22, color: AppColors.text),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Scan QR Code
          GestureDetector(
            onTap: () {
              ref.read(walletServiceProvider).connect();
              Navigator.pop(context);
              context.go('/auth/profile');
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.line, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.sky,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Symbols.qr_code_scanner,
                        size: 24, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan a QR code',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                        Text(
                          'From a wallet on another device',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Symbols.chevron_right, size: 22, color: AppColors.text),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.mist,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Symbols.shield_lock, size: 22, color: AppColors.mintDeep),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'DataMint never asks for your seed phrase or private keys.',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.ink,
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
}

// ==========================================
// 5. Auth 5 · Profile Setup Screen
// ==========================================
class AuthProfileScreen extends StatefulWidget {
  const AuthProfileScreen({super.key});

  @override
  State<AuthProfileScreen> createState() => _AuthProfileScreenState();
}

class _AuthProfileScreenState extends State<AuthProfileScreen> {
  final TextEditingController _nameController =
      TextEditingController(text: 'Amina');
  final Set<String> _selectedLanguages = {'English', 'Yoruba', 'Pidgin'};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleLanguage(String lang) {
    setState(() {
      if (_selectedLanguages.contains(lang)) {
        _selectedLanguages.remove(lang);
      } else {
        _selectedLanguages.add(lang);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const allLanguages = ['English', 'Yoruba', 'Igbo', 'Hausa', 'Pidgin'];

    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Progress Strip (Step 2 of 3)
              Row(
                children: [
                  MintBackButton(
                    onPressed: () => context.go('/auth/welcome'),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: MintStepProgress(totalSteps: 3, currentStep: 2),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text(
                'Tell us how you speak',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'We match you with tasks you’ll ace, like the accents and dialects AI still gets wrong.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 28),

              // Display Name
              MintInput(
                label: 'Display name',
                controller: _nameController,
              ),
              const SizedBox(height: 20),

              // Country Picker
              Text(
                'Country',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.line, width: 1.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nigeria',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: AppColors.ink,
                      ),
                    ),
                    const Icon(Symbols.expand_more, size: 22, color: AppColors.ink),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Languages Selection
              Text(
                'Languages you speak',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 10,
                children: [
                  ...allLanguages.map((lang) {
                    final isSel = _selectedLanguages.contains(lang);
                    return MintChip(
                      label: lang,
                      isSelected: isSel,
                      icon: isSel ? Symbols.check : null,
                      onTap: () => _toggleLanguage(lang),
                    );
                  }),
                  MintChip(
                    label: 'Add',
                    isSelected: false,
                    icon: Symbols.add,
                    onTap: () {},
                  ),
                ],
              ),

              const SizedBox(height: 32),

              MintButton(
                label: 'Continue',
                icon: Symbols.arrow_forward,
                onPressed: () => context.go('/auth/permissions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 6. Auth 6 · Permissions Screen
// ==========================================
class AuthPermissionsScreen extends StatefulWidget {
  const AuthPermissionsScreen({super.key});

  @override
  State<AuthPermissionsScreen> createState() => _AuthPermissionsScreenState();
}

class _AuthPermissionsScreenState extends State<AuthPermissionsScreen> {
  bool _micAllowed = true;
  bool _cameraAllowed = false;
  bool _notificationsAllowed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mist,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MintBackButton(
                    onPressed: () => context.go('/auth/profile'),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: MintStepProgress(totalSteps: 3, currentStep: 3),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text(
                'Two quick permissions',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'So tasks work the moment you open one. Change these anytime in Settings.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 28),

              // Microphone
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.mint,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Symbols.mic, size: 24, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Microphone',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'For voice tasks. Audio is only sent when you submit.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _micAllowed = !_micAllowed),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _micAllowed ? AppColors.mint : AppColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            if (_micAllowed) ...[
                              const Icon(Symbols.check, size: 18, color: AppColors.ink),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _micAllowed ? 'Allowed' : 'Allow',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _micAllowed ? AppColors.ink : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Camera
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.peach,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Symbols.photo_camera, size: 24, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Camera',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'For photo tasks. You review every shot first.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _cameraAllowed = !_cameraAllowed),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _cameraAllowed ? AppColors.mint : AppColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            if (_cameraAllowed) ...[
                              const Icon(Symbols.check, size: 18, color: AppColors.ink),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _cameraAllowed ? 'Allowed' : 'Allow',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _cameraAllowed ? AppColors.ink : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Notifications
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.line, width: 1),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.butter,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Symbols.notifications, size: 24, color: AppColors.ink),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notifications',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Know the second a task is approved and paid.',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => setState(() => _notificationsAllowed = !_notificationsAllowed),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: _notificationsAllowed ? AppColors.mint : AppColors.ink,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            if (_notificationsAllowed) ...[
                              const Icon(Symbols.check, size: 18, color: AppColors.ink),
                              const SizedBox(width: 4),
                            ],
                            Text(
                              _notificationsAllowed ? 'Allowed' : 'Allow',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _notificationsAllowed ? AppColors.ink : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              MintButton(
                label: 'Continue',
                onPressed: () => context.go('/auth/success'),
              ),
              const SizedBox(height: 8),
              MintButton(
                label: 'Not now',
                variant: MintButtonVariant.text,
                onPressed: () => context.go('/auth/success'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 7. Auth 7 · Success Screen
// ==========================================
class AuthSuccessScreen extends StatelessWidget {
  const AuthSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forest,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.28),
                  radius: 0.8,
                  colors: [
                    AppColors.mint.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.52],
                ),
              ),
            ),
          ),

          // Floating D Coin
          Positioned(
            left: 0,
            right: 0,
            top: 180,
            child: Center(
              child: Transform.rotate(
                angle: -12 * math.pi / 180,
                child: const MintDCoin(size: 150),
              ),
            ),
          ),

          // Title & Copy
          Positioned(
            left: 24,
            right: 24,
            top: 388,
            child: Column(
              children: [
                Text(
                  'You’re in, Amina.',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                    letterSpacing: -1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your wallet is connected. Start with a quick one.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: const Color(0xFFB7D6C9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // First Task Offer Card
          Positioned(
            left: 24,
            right: 24,
            top: 520,
            child: MintGlassCard(
              isDark: true,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.mint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Symbols.mic, size: 24, color: AppColors.ink),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Say a short phrase',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Voice · about 30 seconds',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFCFE6DC),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '0.50',
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions
          Positioned(
            left: 24,
            right: 24,
            bottom: 34,
            child: Column(
              children: [
                MintButton(
                  label: 'Try my first task',
                  icon: Symbols.arrow_forward,
                  onPressed: () => context.go('/tasks/task-detail'),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Explore the app',
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
}
