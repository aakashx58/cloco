import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../bloc/products_bloc.dart';
import 'product_actions.dart';
import 'widgets/product_card.dart';

/// Products tab of the dashboard: search, category filter, infinite list.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  ProductsBloc get _bloc => context.read<ProductsBloc>();

  /// Loads the next page near the end of the list — and also when the list
  /// is too short to scroll at all (large screens).
  void _maybeLoadMore() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      _bloc.add(const ProductsNextPageRequested());
    }
  }

  void _onSearchChanged(String value) {
    setState(() {}); // toggles the clear button
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _bloc.add(ProductsQueryChanged(value)),
    );
  }

  void _submitSearch(String value) {
    _debounce?.cancel();
    _bloc.add(ProductsQueryChanged(value));
  }

  void _clearSearch() {
    _searchController.clear();
    _submitSearch('');
    setState(() {});
  }

  void _selectCategory(String? slug) {
    _debounce?.cancel();
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      setState(() {});
    }
    _bloc.add(ProductsCategoryChanged(slug));
    if (_scrollController.hasClients) _scrollController.jumpTo(0);
  }

  Future<void> _refresh() {
    final completer = Completer<void>();
    _bloc.add(ProductsRefreshed(completer: completer));
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final padding = horizontalPaddingFor(MediaQuery.sizeOf(context).width);

    return BlocConsumer<ProductsBloc, ProductsState>(
      listenWhen: (previous, current) => previous.products != current.products,
      listener: (_, _) =>
          WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadMore()),
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 8.h, padding, 0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                onSubmitted: _submitSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search products, e.g. "laptop"',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: _clearSearch,
                        ),
                ),
              ),
            ),
            if (state.categories.isNotEmpty)
              _CategoryChips(
                state: state,
                padding: padding,
                onSelected: _selectCategory,
              ),
            _ResultSummary(state: state, padding: padding),
            Expanded(child: _buildBody(context, state, padding)),
          ],
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ProductsState state, double padding) {
    switch (state.status) {
      case ProductsStatus.initial:
      case ProductsStatus.loading:
        return ListView.separated(
          padding: EdgeInsets.fromLTRB(padding, 4.h, padding, 24.h),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 6,
          separatorBuilder: (_, _) => SizedBox(height: 10.h),
          itemBuilder: (_, _) => const ProductCardSkeleton(),
        );

      case ProductsStatus.failure:
        return EmptyState(
          icon: Icons.cloud_off_rounded,
          title: "Couldn't load products",
          subtitle: state.error,
          action: FilledButton.icon(
            onPressed: () => _bloc.add(const ProductsRefreshed()),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        );

      case ProductsStatus.success:
        if (state.products.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 40.h),
                const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No products found',
                  subtitle: 'Try a different search term or category.',
                ),
              ],
            ),
          );
        }

        final showFooter = state.hasMore || state.isLoadingMore;
        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(padding, 4.h, padding, 96.h),
            itemCount: state.products.length + (showFooter ? 1 : 0),
            separatorBuilder: (_, _) => SizedBox(height: 10.h),
            itemBuilder: (context, index) {
              if (index >= state.products.length) {
                return _ListFooter(
                  failed: state.loadMoreFailed,
                  onRetry: () =>
                      _bloc.add(const ProductsNextPageRequested(retry: true)),
                );
              }
              final product = state.products[index];
              return ProductCard(
                key: ValueKey(product.id),
                product: product,
                isDeleting: state.deletingIds.contains(product.id),
                onTap: () => openProductDetail(context, product),
                onEdit: () => openProductForm(context, product: product),
                onDelete: () => confirmDeleteProduct(context, product),
              );
            },
          ),
        );
    }
  }
}

class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.state,
    required this.padding,
    required this.onSelected,
  });

  final ProductsState state;
  final double padding;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final categories = state.categories;

    return SizedBox(
      height: 52.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.fromLTRB(padding, 12.h, padding, 0),
        itemCount: categories.length + 1,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final slug = index == 0 ? null : categories[index - 1].slug;
          final label = index == 0 ? 'All' : categories[index - 1].name;
          final selected = state.query.isEmpty && state.category == slug;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            showCheckmark: false,
            onSelected: (_) => onSelected(slug),
          );
        },
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({required this.state, required this.padding});

  final ProductsState state;
  final double padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String text;
    if (state.status != ProductsStatus.success) {
      text = state.status == ProductsStatus.failure ? '' : 'Loading…';
    } else if (state.query.isNotEmpty) {
      text = '${state.total} results for "${state.query}"';
    } else if (state.category != null) {
      text =
          '${state.total} products in ${state.categoryName(state.category!)}';
    } else {
      text = '${state.total} products';
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(padding + 4, 12.h, padding, 6.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.failed, required this.onRetry});

  final bool failed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Center(
        child: failed
            ? TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Load more failed — retry'),
              )
            : SizedBox.square(
                dimension: 24.r,
                child: const CircularProgressIndicator(strokeWidth: 2.4),
              ),
      ),
    );
  }
}
