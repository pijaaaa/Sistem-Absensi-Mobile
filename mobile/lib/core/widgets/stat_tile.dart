import 'package:flutter/material.dart';

class StatTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
  final bool showProgress;

  const StatTile({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.onTap,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        icon,
                        color: iconColor ?? theme.colorScheme.primary,
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (showProgress) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: null,
                  backgroundColor:
                      theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                  minHeight: 3,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
