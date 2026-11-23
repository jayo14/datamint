import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/mint_components.dart';

class TextTaskScreen extends StatefulWidget {
  const TextTaskScreen({super.key});

  @override
  State<TextTaskScreen> createState() => _TextTaskScreenState();
}

class _TextTaskScreenState extends State<TextTaskScreen> {
  final TextEditingController _translationController =
      TextEditingController(text: 'How much dis one be?');

  @override
  void dispose() {
    _translationController.dispose();
    super.dispose();
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
                          '0.40 cUSD',
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

              const MintTypePill(type: MintPillType.text),
              const SizedBox(height: 12),
              Text(
                'Translate this phrase',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 31,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                  letterSpacing: -0.9,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 20),

              // Source Phrase Card
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
                      '“How much does this cost?”',
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 26,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Translate from English to Nigerian Pidgin.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Translation Input Field
              MintInput(
                label: 'Your translation',
                controller: _translationController,
              ),
              const SizedBox(height: 14),

              // Quick helper chips
              Wrap(
                spacing: 8,
                children: [
                  _buildHelperChip('Dis one'),
                  _buildHelperChip('Wetin be'),
                  _buildHelperChip('How much'),
                ],
              ),

              const Spacer(),

              MintButton(
                label: 'Next phrase',
                icon: Symbols.arrow_forward,
                onPressed: () => context.go('/tasks/validating'),
              ),
              const SizedBox(height: 8),
              MintButton(
                label: 'Skip this phrase',
                variant: MintButtonVariant.text,
                onPressed: () => context.go('/home'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelperChip(String text) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _translationController.text = '${_translationController.text} $text'.trim();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.line),
        ),
        child: Text(
          '+ $text',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ),
    );
  }
}
