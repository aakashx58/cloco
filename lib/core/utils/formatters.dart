import 'dart:math';

import 'package:flutter_screenutil/flutter_screenutil.dart';

class Formatters {
  const Formatters._();

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String price(double value) => '\$${value.toStringAsFixed(2)}';

  static String date(DateTime date) =>
      '${date.day} ${_months[date.month - 1]} ${date.year}';

  /// `mens-shirts` → `Mens Shirts`
  static String humanize(String slug) => slug
      .split(RegExp(r'[-_\s]+'))
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');

  static String firstName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? name : parts.first;
  }
}

/// Side padding that keeps content readable on tablets/desktop by centering
/// it at [maxContentWidth], while phones get a normal 16dp gutter (both scaled
/// through flutter_screenutil).
double horizontalPaddingFor(double width, {double maxContentWidth = 760}) =>
    max(16.w, (width - maxContentWidth.w) / 2);
