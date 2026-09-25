import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../ui_message.dart';

void showAppSnackBar(BuildContext context, UiMessage message) {
  final scheme = Theme.of(context).colorScheme;
  final foreground = message.isError
      ? scheme.onErrorContainer
      : scheme.onInverseSurface;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: message.isError ? scheme.errorContainer : null,
        content: Row(
          children: [
            Icon(
              message.isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: foreground,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(message.text, style: TextStyle(color: foreground)),
            ),
          ],
        ),
      ),
    );
}

Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  IconData? icon,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: icon == null
          ? null
          : Icon(icon, color: destructive ? scheme.error : scheme.primary),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: Size(64.w, 42.h),
            backgroundColor: destructive ? scheme.error : null,
            foregroundColor: destructive ? scheme.onError : null,
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
