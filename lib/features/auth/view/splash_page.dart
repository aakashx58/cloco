import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'widgets/auth_scaffold.dart';

/// Shown while the saved session is checked (`AuthStarted` is dispatched when
/// the AuthBloc is created). The router's auth guard then moves on to the
/// dashboard (logged in) or the login page (spec 3.1.2).
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandMark(onDark: false),
            SizedBox(height: 32.h),
            SizedBox.square(
              dimension: 28.r,
              child: const CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}
