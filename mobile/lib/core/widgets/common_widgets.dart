import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../app/theme/app_theme.dart';
import '../constants/app_constants.dart';
import 'mint_components.dart';

export 'mint_components.dart';

class DataMintButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final Color? color;
  final double? width;

  const DataMintButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.color,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return MintButton(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      icon: icon,
      variant: isOutlined ? MintButtonVariant.ghost : MintButtonVariant.primary,
      width: width,
    );
  }
}

class DataMintLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final Color? textColor;

  const DataMintLogo({
    super.key,
    this.size = 38,
    this.showText = true,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.mint,
            borderRadius: BorderRadius.circular(size * 0.34),
            boxShadow: [
              BoxShadow(
                color: AppColors.mint.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            'D',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: size * 0.55,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
              height: 1,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 8),
          Text(
            'datamint',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: size * 0.55,
              fontWeight: FontWeight.w700,
              color: textColor ?? AppColors.ink,
              letterSpacing: -0.6,
            ),
          ),
        ],
      ],
    );
  }
}

class PillBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color? badgeColor;
  final Color? textColor;
  final Color? borderColor;

  const PillBadge({
    super.key,
    required this.text,
    this.icon,
    this.badgeColor,
    this.textColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: badgeColor ?? Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: borderColor ?? AppColors.mintBorder.withValues(alpha: 0.8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: textColor ?? AppColors.mintActive),
            const SizedBox(width: 6),
          ] else ...[
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.mintActive,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor ?? AppColors.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingCoinGlow extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;

  const FloatingCoinGlow({
    super.key,
    this.size = 140,
    this.color = AppColors.mint,
    this.opacity = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity * 0.7),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color text;
    final normalized = status.toUpperCase();

    switch (normalized) {
      case 'APPROVED':
      case 'PAID':
      case 'ACTIVE':
      case 'PASSED':
        bg = AppColors.success.withValues(alpha: 0.15);
        text = AppColors.success;
        break;
      case 'PENDING_VALIDATION':
      case 'VALIDATING':
      case 'SUBMITTED':
        bg = AppColors.info.withValues(alpha: 0.15);
        text = AppColors.info;
        break;
      case 'HUMAN_REVIEW':
      case 'APPEALED':
      case 'WARNING':
        bg = AppColors.warning.withValues(alpha: 0.15);
        text = AppColors.warning;
        break;
      case 'REJECTED':
      case 'FAILED':
      case 'ERROR':
        bg = AppColors.error.withValues(alpha: 0.15);
        text = AppColors.error;
        break;
      case 'DRAFT':
      default:
        bg = Colors.grey.withValues(alpha: 0.2);
        text = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        normalized.replaceAll('_', ' '),
        style: TextStyle(
          color: text,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class ModalityBadge extends StatelessWidget {
  final String dataType;

  const ModalityBadge({super.key, required this.dataType});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    final modality = DataModalityExt.fromString(dataType);

    switch (modality) {
      case DataModality.text:
        icon = Icons.text_snippet_rounded;
        color = const Color(0xFF3B82F6);
        break;
      case DataModality.voice:
        icon = Icons.mic_rounded;
        color = const Color(0xFF8B5CF6);
        break;
      case DataModality.image:
        icon = Icons.image_rounded;
        color = AppColors.mintActive;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            modality.name.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.mintBorder,
                  width: 1.2,
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? AppColors.darkTextMuted : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              DataMintButton(
                label: actionLabel!,
                onPressed: onAction,
                isOutlined: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
