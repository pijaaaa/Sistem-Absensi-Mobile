import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final bool fullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final bool outline;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.fullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.outline = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveEnabled = enabled && !isLoading;

    if (outline) {
      return SizedBox(
        width: fullWidth ? double.infinity : null,
        child: OutlinedButton.icon(
          onPressed: effectiveEnabled ? onPressed : null,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            foregroundColor: backgroundColor ?? theme.colorScheme.primary,
            side: BorderSide(
              color: backgroundColor ?? theme.colorScheme.primary,
            ),
          ),
          icon: icon != null ? Icon(icon) : null,
          label: _buildChild(),
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: FilledButton.icon(
        onPressed: effectiveEnabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor ?? theme.colorScheme.primary,
          foregroundColor: textColor ?? Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: icon != null ? Icon(icon) : null,
        label: _buildChild(),
      ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Colors.white,
        ),
      );
    }
    if (icon != null) {
      return Text(text);
    }
    return Text(text);
  }
}
