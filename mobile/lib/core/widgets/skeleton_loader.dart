import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.grey[800]!
        : Colors.grey[300]!;
    final highlightColor = isDark
        ? Colors.grey[700]!
        : Colors.grey[100]!;

    return Container(
      width: width,
      height: height ?? 16,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        gradient: LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          tileMode: TileMode.clamp,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
    );
  }
}

class SkeletonList extends StatelessWidget {
  final int count;
  final double height;
  final double spacing;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonList({
    super.key,
    this.count = 5,
    this.height = 16,
    this.spacing = 12,
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(count, (index) {
        return Padding(
          padding: EdgeInsets.only(bottom: spacing),
          child: SkeletonLoader(
            height: height,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            margin: margin,
          ),
        );
      }),
    );
  }
}
