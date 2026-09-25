import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Shared layout for login/register: gradient backdrop, brand mark and a
/// centred card holding the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.form,
    required this.footer,
    this.showBack = false,
  });

  final String title;
  final String subtitle;
  final Widget form;
  final Widget footer;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, scheme.tertiary, 0.7)!,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 24.h),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 440.w),
                    child: Column(
                      children: [
                        const BrandMark(),
                        SizedBox(height: 24.h),
                        Card(
                          elevation: 6,
                          shadowColor: Colors.black26,
                          child: Padding(
                            padding: EdgeInsets.all(24.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  subtitle,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                form,
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),
                        footer,
                      ],
                    ),
                  ),
                ),
              ),
              if (showBack)
                const Positioned(
                  left: 4,
                  top: 4,
                  child: BackButton(color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.onDark = true});

  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = onDark ? Colors.white : scheme.primary;

    return Column(
      children: [
        Container(
          width: 64.w,
          height: 64.h,
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: onDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(Icons.inventory_2_rounded, color: foreground, size: 32.r),
        ),
        SizedBox(height: 12.h),
        Text(
          'Product Manager',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: foreground,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        Text(
          'Admin console',
          style: TextStyle(color: foreground.withValues(alpha: 0.8)),
        ),
      ],
    );
  }
}

/// Footer line on the gradient, e.g. "Don't have an account? Create one".
class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    super.key,
    required this.prompt,
    required this.action,
    required this.onPressed,
  });

  final String prompt;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: const TextStyle(color: Colors.white70)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(foregroundColor: Colors.white),
          child: Text(
            action,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              decoration: TextDecoration.underline,
              decorationColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
