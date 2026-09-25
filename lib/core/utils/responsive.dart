import 'package:flutter/widgets.dart';

/// Sizing policy for flutter_screenutil.
///
/// The UI is designed on a 390pt-wide phone. Out of the box, screenutil
/// scales linearly with screen width, which blows a phone design up ~4× on a
/// desktop monitor and shrinks it ~50% on a landscape phone.
///
/// Instead, [designSizeFor] picks the design size *from the actual screen* so
/// that screenutil's width, height, radius and text factors all equal
/// [scaleFor]: one uniform zoom based on the shortest side, clamped to
/// [minScale]–[maxScale]. `.w` / `.h` / `.r` / `.sp` therefore behave the same
/// on every device class, and wide layouts are handled by breakpoints
/// (navigation rail, centred content) rather than by magnifying everything.
abstract final class Responsive {
  /// Shortest side of the reference design (iPhone 14/15).
  static const designShortestSide = 390.0;
  static const minScale = 0.85;
  static const maxScale = 1.3;

  static double scaleFor(Size screen) =>
      (screen.shortestSide / designShortestSide).clamp(minScale, maxScale);

  static Size designSizeFor(Size screen) {
    if (screen.isEmpty) return const Size(390, 844);
    final scale = scaleFor(screen);
    return Size(screen.width / scale, screen.height / scale);
  }
}
