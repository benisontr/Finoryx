import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class FinoryxCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final Gradient? gradient;

  const FinoryxCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.onTap,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.lg;
    final defaultBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderCol = borderColor ?? (isDark ? AppColors.darkBorder : AppColors.lightBorder);

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderCol, width: 0.8),
    );

    if (gradient != null) {
      final container = Container(
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderCol, width: 0.8),
        ),
        child: child,
      );

      if (onTap != null) {
        return Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(radius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(radius),
            child: container,
          ),
        );
      }
      return container;
    }

    final cardContent = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      child: child,
    );

    return Container(
      margin: margin,
      child: Material(
        color: backgroundColor ?? defaultBg,
        shape: cardShape,
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                child: cardContent,
              )
            : cardContent,
      ),
    );
  }
}
