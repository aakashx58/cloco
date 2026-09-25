import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  /// Colour-coded stock badge: out of stock / low stock / in stock.
  factory StatusBadge.stock(int stock) {
    if (stock <= 0) {
      return const StatusBadge(
        label: 'Out of stock',
        color: Color(0xFFDC2626),
        icon: Icons.remove_shopping_cart_outlined,
      );
    }
    if (stock < 10) {
      return StatusBadge(
        label: 'Low stock · $stock',
        color: const Color(0xFFD97706),
        icon: Icons.warning_amber_rounded,
      );
    }
    return StatusBadge(
      label: 'In stock · $stock',
      color: const Color(0xFF16A34A),
      icon: Icons.inventory_2_outlined,
    );
  }

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.r, color: color),
            SizedBox(width: 4.w),
          ],
          // Ellipsize rather than overflow in tight spots (list tiles,
          // narrow phones, large system text).
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
