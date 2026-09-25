import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/product_image.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../data/models/product.dart';
import '../bloc/product_detail_bloc.dart';
import '../bloc/products_bloc.dart';
import 'product_actions.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key});

  Future<void> _edit(BuildContext context, Product product) async {
    final detailBloc = context.read<ProductDetailBloc>();
    final saved = await openProductForm(context, product: product);
    if (saved != null) detailBloc.add(ProductDetailReplaced(saved));
  }

  Future<void> _delete(BuildContext context, Product product) async {
    final router = GoRouter.of(context);
    final confirmed = await confirmDeleteProduct(context, product);
    if (!confirmed) return;
    // The list shows progress and the result snackbar.
    router.canPop() ? router.pop() : router.go(AppRoutes.products);
  }

  Future<void> _adjustStock(BuildContext context, Product product) async {
    final detailBloc = context.read<ProductDetailBloc>();
    final stock = await showDialog<int>(
      context: context,
      builder: (_) => _StockDialog(initial: product.stock),
    );
    if (stock != null) detailBloc.add(ProductStockUpdateRequested(stock));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ProductDetailBloc, ProductDetailState>(
          listenWhen: (previous, current) =>
              previous.message != current.message && current.message != null,
          listener: (context, state) =>
              showAppSnackBar(context, state.message!),
        ),
        // Keep the list in sync with fresh (GET) or patched (stock) data.
        BlocListener<ProductDetailBloc, ProductDetailState>(
          listenWhen: (previous, current) =>
              current.product != null && previous.product != current.product,
          listener: (context, state) => context.read<ProductsBloc>().add(
            ProductSaved(
              state.product!,
              announce: false,
              insertIfMissing: false,
            ),
          ),
        ),
      ],
      child: BlocBuilder<ProductDetailBloc, ProductDetailState>(
        builder: (context, state) {
          if (state.product != null) return _buildPage(context, state);
          return Scaffold(
            appBar: AppBar(),
            body: state.loadError == null
                ? const Center(child: CircularProgressIndicator())
                : EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: "Couldn't load this product",
                    subtitle: state.loadError,
                    action: FilledButton.icon(
                      onPressed: () => context.read<ProductDetailBloc>().add(
                        const ProductDetailRequested(),
                      ),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildPage(BuildContext context, ProductDetailState state) {
    final product = state.product!;
    final screen = MediaQuery.sizeOf(context);
    final width = screen.width;
    // Never let the image take over short (landscape) screens.
    final headerHeight = min((width > 700 ? 420 : 320).h, screen.height * 0.45);
    final padding = horizontalPaddingFor(width);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: headerHeight,
            actions: [
              if (state.isRefreshing)
                Padding(
                  padding: EdgeInsets.all(16.r),
                  child: SizedBox.square(
                    dimension: 18.r,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _ImageGallery(product: product),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(padding, 20.h, padding, 24.h),
            sliver: SliverToBoxAdapter(
              child: _DetailBody(
                product: product,
                isUpdatingStock: state.isUpdatingStock,
                onAdjustStock: () => _adjustStock(context, product),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(padding, 8.h, padding, 12.h),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _delete(context, product),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _edit(context, product),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.product,
    required this.isUpdatingStock,
    required this.onAdjustStock,
  });

  final Product product;
  final bool isUpdatingStock;
  final VoidCallback onAdjustStock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            StatusBadge(
              label: product.categoryLabel,
              color: scheme.primary,
              icon: Icons.sell_outlined,
            ),
            if (product.brand?.isNotEmpty ?? false)
              StatusBadge(
                label: product.brand!,
                color: scheme.tertiary,
                icon: Icons.verified_outlined,
              ),
            if (product.isLocal)
              StatusBadge(
                label: 'Local only',
                color: scheme.secondary,
                icon: Icons.cloud_off_rounded,
              ),
          ],
        ),
        SizedBox(height: 12.h),
        Text(
          product.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10.w,
          runSpacing: 4.h,
          children: [
            Text(
              Formatters.price(product.price),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (product.hasDiscount) ...[
              Text(
                Formatters.price(product.originalPrice),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              StatusBadge(
                label: '${product.discountPercentage.toStringAsFixed(1)}% off',
                color: scheme.error,
              ),
            ],
          ],
        ),
        SizedBox(height: 8.h),
        Row(
          children: [
            ...List.generate(5, (i) {
              final filled = product.rating >= i + 0.75;
              final half = !filled && product.rating >= i + 0.25;
              return Icon(
                filled
                    ? Icons.star_rounded
                    : half
                    ? Icons.star_half_rounded
                    : Icons.star_outline_rounded,
                size: 20.r,
                color: const Color(0xFFF59E0B),
              );
            }),
            SizedBox(width: 6.w),
            Text(
              '${product.rating.toStringAsFixed(1)} rating',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
        Card(
          child: ListTile(
            contentPadding: EdgeInsets.fromLTRB(16.w, 6.h, 8.w, 6.h),
            leading: CircleAvatar(
              backgroundColor: scheme.primaryContainer,
              child: Icon(
                Icons.inventory_2_outlined,
                color: scheme.onPrimaryContainer,
              ),
            ),
            title: const Text(
              'Inventory',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge.stock(product.stock),
              ),
            ),
            trailing: isUpdatingStock
                ? Padding(
                    padding: EdgeInsets.all(12.r),
                    child: SizedBox.square(
                      dimension: 20.r,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: onAdjustStock,
                    icon: Icon(Icons.tune_rounded, size: 18.r),
                    label: const Text('Adjust'),
                  ),
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          product.description.isEmpty
              ? 'No description provided.'
              : product.description,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ImageGallery extends StatefulWidget {
  const _ImageGallery({required this.product});

  final Product product;

  @override
  State<_ImageGallery> createState() => _ImageGalleryState();
}

class _ImageGalleryState extends State<_ImageGallery> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.product.galleryImages;
    final scheme = Theme.of(context).colorScheme;

    if (images.isEmpty) {
      return const ProductImage(url: '');
    }

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            itemCount: images.length,
            onPageChanged: (page) => setState(() => _page = page),
            itemBuilder: (_, index) => Padding(
              padding: EdgeInsets.fromLTRB(24.w, 72.h, 24.w, 32.h),
              child: ProductImage(url: images[index], fit: BoxFit.contain),
            ),
          ),
          if (images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (index) {
                  final active = index == _page;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.symmetric(horizontal: 3.w),
                    width: active ? 20 : 7,
                    height: 7.h,
                    decoration: BoxDecoration(
                      color: active ? scheme.primary : scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stock editor; the result is sent as PATCH { stock }.
class _StockDialog extends StatefulWidget {
  const _StockDialog({required this.initial});

  final int initial;

  @override
  State<_StockDialog> createState() => _StockDialogState();
}

class _StockDialogState extends State<_StockDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');

  int? get _value => int.tryParse(_controller.text);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _step(int delta) {
    final next = ((_value ?? widget.initial) + delta).clamp(0, 999999);
    setState(() => _controller.text = '$next');
  }

  @override
  Widget build(BuildContext context) {
    final valid = _value != null && _value! >= 0;

    return AlertDialog(
      icon: const Icon(Icons.inventory_2_outlined),
      title: const Text('Adjust stock'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Set the number of units available.'),
          SizedBox(height: 16.h),
          Row(
            children: [
              IconButton.filledTonal(
                tooltip: 'Decrease',
                onPressed: () => _step(-1),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() {}),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(width: 12.w),
              IconButton.filledTonal(
                tooltip: 'Increase',
                onPressed: () => _step(1),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: Size(64.w, 42.h)),
          onPressed: valid ? () => Navigator.of(context).pop(_value) : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
