import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum FinoryxButtonVariant {
  primary,
  secondary,
  outline,
  destructive,
  ai,
}

class FinoryxButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback? onPressed;
  final FinoryxButtonVariant variant;
  final bool isLoading;
  final double? height;

  const FinoryxButton({
    super.key,
    required this.text,
    this.icon,
    this.onPressed,
    this.variant = FinoryxButtonVariant.primary,
    this.isLoading = false,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case FinoryxButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white;
        break;
      case FinoryxButtonVariant.secondary:
        bg = isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        break;
      case FinoryxButtonVariant.outline:
        bg = Colors.transparent;
        fg = isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
        border = BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1);
        break;
      case FinoryxButtonVariant.destructive:
        bg = AppColors.expenseContainer;
        fg = AppColors.expense;
        break;
      case FinoryxButtonVariant.ai:
        bg = AppColors.aiAccent;
        fg = Colors.white;
        break;
    }

    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          side: border,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(fg),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
