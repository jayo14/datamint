import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../constants/app_constants.dart';

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
    final effectiveColor = color ?? AppColors.mintPrimary;

    final Widget childContent = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(label),
        ],
      ],
    );

    final button = isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: effectiveColor),
              foregroundColor: effectiveColor,
            ),
            child: childContent,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: effectiveColor,
              foregroundColor: Colors.black,
            ),
            child: childContent,
          );

    if (width != null) {
      return SizedBox(width: width, child: button);
    }
    return button;
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
        color = const Color(0xFF60A5FA); // Sky blue
        break;
      case DataModality.voice:
        icon = Icons.mic_rounded;
        color = const Color(0xFFA78BFA); // Purple
        break;
      case DataModality.image:
        icon = Icons.image_rounded;
        color = const Color(0xFF34D399); // Emerald
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
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
                color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: isDark ? AppColors.darkTextMuted : Colors.grey.shade400,
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
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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
