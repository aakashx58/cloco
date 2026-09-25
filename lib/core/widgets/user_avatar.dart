import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/app_user.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key, required this.user, this.radius = 22});

  final AppUser user;
  final double radius;

  static const _palette = [
    Color(0xFF4F46E5),
    Color(0xFF0891B2),
    Color(0xFF059669),
    Color(0xFFD97706),
    Color(0xFFDB2777),
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
  ];

  @override
  Widget build(BuildContext context) {
    // Stable colour per user (String.hashCode is not stable across runs).
    final seed = user.email.codeUnits.fold<int>(0, (sum, c) => sum + c);
    final color = _palette[seed % _palette.length];

    return CircleAvatar(
      radius: radius.r,
      backgroundColor: color.withValues(alpha: 0.16),
      child: Text(
        user.initials,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: (radius * 0.72).sp,
        ),
      ),
    );
  }
}
