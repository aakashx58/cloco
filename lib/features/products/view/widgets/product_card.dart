import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/product_image.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../data/models/product.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isDeleting = false,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isDeleting ? 0.45 : 1,
      child: AbsorbPointer(
        absorbing: isDeleting,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 12.h, 4.w, 12.h),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14.r),
                    child: ProductImage(
                      url: product.thumbnail,
                      width: 92.w,
                      height: 92.h,
                    ),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          [
                            if (product.brand?.isNotEmpty ?? false)
                              product.brand!,
                            product.categoryLabel,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        // Price group takes whatever the rating doesn't need
                        // and shrinks to fit on very narrow screens.
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        Formatters.price(product.price),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: scheme.primary,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                    ),
                                  ),
                                  if (product.hasDiscount) ...[
                                    SizedBox(width: 6.w),
                                    Text(
                                      '-${product.discountPercentage.round()}%',
                                      style: TextStyle(
                                        color: scheme.error,
                                        fontSize: 12.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Icon(
                              Icons.star_rounded,
                              size: 16.r,
                              color: const Color(0xFFF59E0B),
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              product.rating.toStringAsFixed(1),
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                        SizedBox(height: 6.h),
                        Wrap(
                          spacing: 6.w,
                          runSpacing: 4.h,
                          children: [
                            StatusBadge.stock(product.stock),
                            if (product.isLocal)
                              Tooltip(
                                message:
                                    'Created this session. dummyjson '
                                    'does not persist new products.',
                                child: StatusBadge(
                                  label: 'Local',
                                  color: scheme.secondary,
                                  icon: Icons.cloud_off_rounded,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isDeleting)
                    Padding(
                      padding: EdgeInsets.all(14.r),
                      child: SizedBox.square(
                        dimension: 20.r,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    PopupMenuButton<_ProductAction>(
                      tooltip: 'Actions',
                      onSelected: (action) => switch (action) {
                        _ProductAction.edit => onEdit(),
                        _ProductAction.delete => onDelete(),
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: _ProductAction.edit,
                          child: ListTile(
                            leading: Icon(Icons.edit_outlined),
                            title: Text('Edit'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: _ProductAction.delete,
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline_rounded,
                              color: scheme.error,
                            ),
                            title: Text(
                              'Delete',
                              style: TextStyle(color: scheme.error),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ProductAction { edit, delete }

/// Placeholder card shown while the first page loads.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;

    Widget bar(double widthFactor, double height) => FractionallySizedBox(
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6.r),
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.r),
        child: Row(
          children: [
            Container(
              width: 92.w,
              height: 92.h,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(0.75, 16),
                  SizedBox(height: 8.h),
                  bar(0.45, 12),
                  SizedBox(height: 14.h),
                  bar(0.3, 16),
                  SizedBox(height: 8.h),
                  bar(0.35, 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
