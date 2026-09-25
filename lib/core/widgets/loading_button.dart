import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Full-width primary button that shows a spinner and disables itself while
/// [loading] — prevents double submits.
class LoadingButton extends StatelessWidget {
  const LoadingButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox.square(
            dimension: 22.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Theme.of(context).colorScheme.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20.r),
                SizedBox(width: 8.w),
              ],
              Text(label),
            ],
          );

    return SizedBox(
      width: double.infinity,
      child: FilledButton(onPressed: loading ? null : onPressed, child: child),
    );
  }
}
