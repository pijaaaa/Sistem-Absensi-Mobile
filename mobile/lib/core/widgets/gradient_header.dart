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
        : AppTheme.brandGradient(Theme.of(context).brightness);

    final radius = borderRadius ??
        const BorderRadius.only(
          bottomLeft: Radius.circular(AppTheme.radiusXL),
          bottomRight: Radius.circular(AppTheme.radiusXL),
        );

    return ClipRRect(
      borderRadius: radius,
      child: Container(
        height: height,
        decoration: BoxDecoration(gradient: gradient),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -30,
              child: _DecorativeCircle(
                size: 140,
                color: Colors.white.withValues(alpha: isDark ? 0.04 : 0.06),
              ),
            ),
            Positioned(
              bottom: -60,
              left: -20,
              child: _DecorativeCircle(
                size: 180,
                color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.05),
              ),
            ),
            if (showAccentLine)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 3,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent,
                        AppColors.accent,
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLG,
                    vertical: AppTheme.spacingMD,
                  ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
