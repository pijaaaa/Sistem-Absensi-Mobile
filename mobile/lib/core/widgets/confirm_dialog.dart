import 'package:flutter/material.dart';

class ConfirmDialog extends StatelessWidget {
  final String title;
  final String content;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Konfirmasi',
    this.cancelText = 'Batal',
    this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
  });

  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText ?? 'Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor:
                  isDestructive ? Theme.of(context).colorScheme.error : null,
            ),
            child: Text(confirmText ?? 'Konfirmasi'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: onCancel ?? () => Navigator.pop(context, false),
          child: Text(cancelText ?? 'Batal'),
        ),
        TextButton(
          onPressed: onConfirm ?? () => Navigator.pop(context, true),
          style: TextButton.styleFrom(
            foregroundColor: isDestructive
                ? Theme.of(context).colorScheme.error
                : null,
          ),
          child: Text(confirmText ?? 'Konfirmasi'),
        ),
      ],
    );
  }
}
