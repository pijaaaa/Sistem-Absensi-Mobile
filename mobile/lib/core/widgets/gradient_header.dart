import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_colors.dart';
import 'package:mobile/core/theme/app_theme.dart';

class GradientHeader extends StatelessWidget {
  final Widget child;
  final double height;
  final bool showAccentLine;
  final double accentWidth;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? colorOverride;

  const GradientHeader({
    super.key,
    required this.child,
    this.height = 200,
    this.showAccentLine = true,
    this.accentWidth = 48,
    this.borderRadius,
    this.padding,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Gradient gradient = colorOverride != null
        ? LinearGradient(colors: [colorOverride!, colorOverride!])
        : isDark
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                ],
              );

    final widget = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(0),
      ),
      child: Stack(
        children: [
          if (showAccentLine)
            Positioned(
              top: 16,
              left: 0,
              child: Container(
                width: accentWidth,
                height: 3,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.accent : AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          Padding(
            padding: padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                  vertical: 16,
                ),
            child: child,
          ),
        ],
      ),
    );

    return widget;
  }
}
