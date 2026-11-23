import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../app/theme/app_theme.dart';

// ==========================================
// 1. Signature Ridged "D" Coin
// ==========================================
class MintDCoin extends StatelessWidget {
  final double size;
  final bool animate;

  const MintDCoin({
    super.key,
    this.size = 120,
    this.animate = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ridged Rim
          CustomPaint(
            size: Size(size, size),
            painter: _CoinRidgesPainter(),
          ),
          // Radial Gradient Coin Face
          Container(
            width: size * 0.92,
            height: size * 0.92,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.36, -0.48),
                radius: 0.95,
                colors: [
                  Color(0xFFD9FFEE),
                  Color(0xFF74E3B6),
                  Color(0xFF2FBF8A),
                  Color(0xFF127E58),
                ],
                stops: [0.0, 0.36, 0.72, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: size * 0.22,
                  offset: Offset(0, size * 0.12),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Inner concentric highlight rings
                Container(
                  margin: EdgeInsets.all(size * 0.04),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF62DAAA),
                      width: size * 0.04,
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.all(size * 0.07),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.28),
                      width: size * 0.02,
                    ),
                  ),
                ),
                // Bold "D" Letter
                Text(
                  'D',
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: size * 0.52,
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                    color: const Color(0xFF0D5C41),
                    shadows: [
                      const Shadow(
                        color: Color(0x66FFFFFF),
                        offset: Offset(0, 3),
                        blurRadius: 0,
                      ),
                    ],
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

class _CoinRidgesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const totalSectors = 60;
    const sweep = (2 * math.pi) / totalSectors;

    final paint1 = Paint()
      ..color = const Color(0xFF46D3A1)
      ..style = PaintingStyle.fill;
    final paint2 = Paint()
      ..color = const Color(0xFF1C9A6E)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < totalSectors; i++) {
      final startAngle = i * sweep;
      final paint = (i % 2 == 0) ? paint1 : paint2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ==========================================
// 2. Buttons
// ==========================================
enum MintButtonVariant { primary, dark, ghost, text }

class MintButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final MintButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isSmall;
  final double? width;
  final bool enabled;

  const MintButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = MintButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isSmall = false,
    this.width,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Border? border;

    switch (variant) {
      case MintButtonVariant.primary:
        bg = AppColors.mint;
        fg = AppColors.ink;
        break;
      case MintButtonVariant.dark:
        bg = AppColors.ink;
        fg = Colors.white;
        break;
      case MintButtonVariant.ghost:
        bg = Colors.white;
        fg = AppColors.ink;
        border = Border.all(color: AppColors.line, width: 1.5);
        break;
      case MintButtonVariant.text:
        bg = Colors.transparent;
        fg = AppColors.ink;
        break;
    }

    final effectiveHeight = isSmall ? 40.0 : (variant == MintButtonVariant.text ? 48.0 : 56.0);
    final effectivePadding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 16)
        : const EdgeInsets.symmetric(horizontal: 24);

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: SizedBox(
        width: width ?? (isSmall ? null : double.infinity),
        height: effectiveHeight,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: (enabled && !isLoading) ? onPressed : null,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: effectivePadding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: border,
              ),
              alignment: Alignment.center,
              child: isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(fg),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: isSmall ? 18 : 22, color: fg),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: GoogleFonts.inter(
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: fg,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 3. Inputs
// ==========================================
class MintInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;
  final Widget? suffix;
  final String? errorText;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;

  const MintInput({
    super.key,
    this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.prefixIcon,
    this.suffix,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
  });

  @override
  State<MintInput> createState() => _MintInputState();
}

class _MintInputState extends State<MintInput> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hasError
                  ? AppColors.danger
                  : (_isFocused ? AppColors.ink : AppColors.line),
              width: 1.5,
            ),
            boxShadow: hasError
                ? [
                    BoxShadow(
                      color: AppColors.danger.withValues(alpha: 0.14),
                      blurRadius: 0,
                      spreadRadius: 4,
                    )
                  ]
                : (_isFocused
                    ? [
                        BoxShadow(
                          color: AppColors.mint.withValues(alpha: 0.5),
                          blurRadius: 0,
                          spreadRadius: 4,
                        )
                      ]
                    : null),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
          alignment: Alignment.center,
          child: Row(
            children: [
              if (widget.prefixIcon != null) ...[
                Icon(widget.prefixIcon, size: 22, color: AppColors.text),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  initialValue: widget.controller == null ? widget.initialValue : null,
                  focusNode: _focusNode,
                  readOnly: widget.readOnly,
                  onTap: widget.onTap,
                  onChanged: widget.onChanged,
                  keyboardType: widget.keyboardType,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    hintText: widget.hint,
                    hintStyle: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: AppColors.text.withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                  ),
                ),
              ),
              if (widget.suffix != null) widget.suffix!,
            ],
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Symbols.error, size: 18, color: AppColors.danger),
              const SizedBox(width: 6),
              Text(
                widget.errorText!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ==========================================
// 4. OTP Boxes
// ==========================================
class MintOtpBoxes extends StatelessWidget {
  final int length;
  final String value;
  final bool hasError;
  final ValueChanged<int>? onBoxTap;

  const MintOtpBoxes({
    super.key,
    this.length = 6,
    required this.value,
    this.hasError = false,
    this.onBoxTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(length, (index) {
        final char = index < value.length ? value[index] : '';
        final isFocused = index == value.length;

        return Expanded(
          child: GestureDetector(
            onTap: () => onBoxTap?.call(index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: hasError
                      ? AppColors.danger
                      : (isFocused ? AppColors.ink : AppColors.line),
                  width: 1.5,
                ),
                boxShadow: hasError
                    ? [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.14),
                          blurRadius: 0,
                          spreadRadius: 4,
                        )
                      ]
                    : (isFocused
                        ? [
                            BoxShadow(
                              color: AppColors.mint.withValues(alpha: 0.5),
                              blurRadius: 0,
                              spreadRadius: 4,
                            )
                          ]
                        : null),
              ),
              alignment: Alignment.center,
              child: Text(
                char,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: hasError ? AppColors.danger : AppColors.ink,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ==========================================
// 5. Segmented Control
// ==========================================
class MintSegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const MintSegmentedControl({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line, width: 1.0),
      ),
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = index == selectedIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.ink : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  options[index],
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.text,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ==========================================
// 6. Selectable Chip
// ==========================================
class MintChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData? icon;
  final VoidCallback onTap;

  const MintChip({
    super.key,
    required this.label,
    required this.isSelected,
    this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ink : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppColors.ink : AppColors.line,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.ink.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 7. Modality / Status Pill
// ==========================================
enum MintPillType { voice, image, text, paid, review }

class MintTypePill extends StatelessWidget {
  final MintPillType type;
  final String? customLabel;

  const MintTypePill({
    super.key,
    required this.type,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (type) {
      case MintPillType.voice:
        bg = AppColors.mint;
        fg = AppColors.ink;
        label = 'VOICE';
        break;
      case MintPillType.image:
        bg = AppColors.butter;
        fg = AppColors.ink;
        label = 'IMAGE';
        break;
      case MintPillType.text:
        bg = AppColors.sky;
        fg = AppColors.ink;
        label = 'TEXT';
        break;
      case MintPillType.paid:
        bg = AppColors.ink;
        fg = AppColors.mint;
        label = 'PAID';
        break;
      case MintPillType.review:
        bg = AppColors.peach;
        fg = AppColors.ink;
        label = 'REVIEW';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        customLabel ?? label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: fg,
        ),
      ),
    );
  }
}

// ==========================================
// 8. Back Button
// ==========================================
class MintBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color? color;

  const MintBackButton({super.key, this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed ?? () => Navigator.of(context).maybePop(),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.line, width: 1.0),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Symbols.arrow_back,
          size: 22,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

// ==========================================
// 9. Step Progress Bar
// ==========================================
class MintStepProgress extends StatelessWidget {
  final int totalSteps;
  final int currentStep; // 1-indexed

  const MintStepProgress({
    super.key,
    required this.totalSteps,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 6,
            decoration: BoxDecoration(
              color: isActive ? AppColors.ink : const Color(0xFFC9E6D8),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}

// ==========================================
// 10. Page Dots
// ==========================================
class MintPageDots extends StatelessWidget {
  final int count;
  final int activeIndex;

  const MintPageDots({
    super.key,
    required this.count,
    required this.activeIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? AppColors.ink : const Color(0xFFB5DCC9),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ==========================================
// 11. Numeric Keypad
// ==========================================
class MintNumericKeypad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final bool showDot;

  const MintNumericKeypad({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    this.showDot = true,
  });

  @override
  Widget build(BuildContext context) {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      showDot ? '.' : '', '0', 'backspace'
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 34),
      decoration: const BoxDecoration(
        color: Color(0xFFD6EFE2),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 12,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 2.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemBuilder: (context, index) {
          final k = keys[index];
          if (k.isEmpty) {
            return const SizedBox();
          }

          if (k == 'backspace') {
            return Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onBackspace,
                child: const Center(
                  child: Icon(Symbols.backspace, size: 24, color: AppColors.ink),
                ),
              ),
            );
          }

          return Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => onKeyPress(k),
              child: Center(
                child: Text(
                  k,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// 12. Floating Glass Tab Bar
// ==========================================
class MintFloatingTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const MintFloatingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'label': 'Home', 'icon': Symbols.home},
      {'label': 'Tasks', 'icon': Symbols.checklist},
      {'label': 'Wallet', 'icon': Symbols.account_balance_wallet},
      {'label': 'Profile', 'icon': Symbols.person},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 26),
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.16),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = index == currentIndex;
              final item = items[index];

              return GestureDetector(
                onTap: () => onTabSelected(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  height: 54,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.ink : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 22,
                        color: isSelected ? AppColors.mint : AppColors.text,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['label'] as String,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 13. Glass Card
// ==========================================
class MintGlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  final EdgeInsetsGeometry padding;
  final double radius;

  const MintGlassCard({
    super.key,
    required this.child,
    this.isDark = false,
    this.padding = const EdgeInsets.all(24),
    this.radius = 28,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: isDark
                ? AppColors.forest.withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.62),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.26)
                  : Colors.white.withValues(alpha: 0.85),
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ==========================================
// 14. Animated Waveform Widget
// ==========================================
class MintWaveform extends StatefulWidget {
  final bool isRecording;
  final int barCount;

  const MintWaveform({
    super.key,
    required this.isRecording,
    this.barCount = 28,
  });

  @override
  State<MintWaveform> createState() => _MintWaveformState();
}

class _MintWaveformState extends State<MintWaveform>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            final phase = (index / widget.barCount) * math.pi * 2;
            final progress = _controller.value;
            final scale = widget.isRecording
                ? (math.sin(progress * math.pi * 2 + phase).abs() * 0.75 + 0.25)
                : 0.25;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 4,
              height: 48 * scale,
              decoration: BoxDecoration(
                color: widget.isRecording
                    ? AppColors.ink
                    : const Color(0xFF9CBDAF),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
