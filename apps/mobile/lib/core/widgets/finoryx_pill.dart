import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum FinoryxPillVariant {
  primary,
  ai,
  income,
  expense,
  warning,
  neutral,
}

class FinoryxPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final FinoryxPillVariant variant;
  final Color? customColor;
  final VoidCallback? onTap;

  const FinoryxPill({
    super.key,
    required this.label,
    this.icon,
    this.variant = FinoryxPillVariant.neutral,
    this.customColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    if (customColor != null) {
      bg = customColor!.withValues(alpha: isDark ? 0.2 : 0.12);
      fg = customColor!;
    } else {
      switch (variant) {
        case FinoryxPillVariant.primary:
          bg = isDark ? AppColors.primaryContainerDark : AppColors.primaryContainer;
          fg = isDark ? AppColors.primaryLight : AppColors.primary;
          break;
        case FinoryxPillVariant.ai:
          bg = isDark ? AppColors.aiContainerDark : AppColors.aiContainer;
          fg = isDark ? const Color(0xFFC084FC) : AppColors.aiAccent;
          break;
        case FinoryxPillVariant.income:
          bg = isDark ? const Color(0xFF064E3B) : AppColors.incomeContainer;
          fg = isDark ? const Color(0xFF34D399) : const Color(0xFF065F46);
          break;
        case FinoryxPillVariant.expense:
          bg = isDark ? const Color(0xFF7F1D1D) : AppColors.expenseContainer;
          fg = isDark ? const Color(0xFFF87171) : const Color(0xFF991B1B);
          break;
        case FinoryxPillVariant.warning:
          bg = isDark ? const Color(0xFF78350F) : AppColors.warningContainer;
          fg = isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E);
          break;
        case FinoryxPillVariant.neutral:
          bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
          fg = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
          break;
      }
    }

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return content;
  }
}
