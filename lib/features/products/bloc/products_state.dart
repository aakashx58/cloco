part of 'products_bloc.dart';

enum ProductsStatus { initial, loading, success, failure }

final class ProductsState extends Equatable {
  const ProductsState({
    this.status = ProductsStatus.initial,
    this.products = const [],
    this.categories = const [],
    this.category,
    this.query = '',
    this.total = 0,
    this.nextSkip = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
    this.deletingIds = const {},
    this.error,
    this.message,
  });

  final ProductsStatus status;
  final List<Product> products;
  final List<ProductCategory> categories;

  /// Selected category slug; null = all.
  final String? category;
  final String query;
  final int total;

  /// API offset for the next page (independent of local inserts/deletes).
  final int nextSkip;
  final bool hasMore;
  final bool isLoadingMore;
  final bool loadMoreFailed;
  final Set<int> deletingIds;
  final String? error;
  final UiMessage? message;

  String categoryName(String slug) =>
      categories.where((c) => c.slug == slug).firstOrNull?.name ??
      Formatters.humanize(slug);

  ProductsState copyWith({
    ProductsStatus? status,
    List<Product>? products,
    List<ProductCategory>? categories,
    String? category,
    bool clearCategory = false,
    String? query,
    int? total,
    int? nextSkip,
    bool? hasMore,
    bool? isLoadingMore,
    bool? loadMoreFailed,
    Set<int>? deletingIds,
    String? error,
    UiMessage? message,
  }) => ProductsState(
    status: status ?? this.status,
    products: products ?? this.products,
    categories: categories ?? this.categories,
    category: clearCategory ? null : (category ?? this.category),
    query: query ?? this.query,
    total: total ?? this.total,
    nextSkip: nextSkip ?? this.nextSkip,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    deletingIds: deletingIds ?? this.deletingIds,
    error: error ?? this.error,
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [
    status,
    products,
    categories,
    category,
    query,
    total,
    nextSkip,
    hasMore,
    isLoadingMore,
    loadMoreFailed,
    deletingIds,
    error,
    message,
  ];
}
