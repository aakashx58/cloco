part of 'products_bloc.dart';

sealed class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Loads categories and the first page.
final class ProductsStarted extends ProductsEvent {
  const ProductsStarted();
}

/// Pull-to-refresh; [completer] finishes the RefreshIndicator spinner.
final class ProductsRefreshed extends ProductsEvent {
  const ProductsRefreshed({this.completer});

  final Completer<void>? completer;

  @override
  List<Object?> get props => [completer];
}

final class ProductsNextPageRequested extends ProductsEvent {
  const ProductsNextPageRequested({this.retry = false});

  /// True when the user taps "Retry" after a failed page load.
  final bool retry;

  @override
  List<Object?> get props => [retry];
}

final class ProductsQueryChanged extends ProductsEvent {
  const ProductsQueryChanged(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ProductsCategoryChanged extends ProductsEvent {
  const ProductsCategoryChanged(this.slug);

  /// Null means "All".
  final String? slug;

  @override
  List<Object?> get props => [slug];
}

/// A product was created or updated elsewhere (form/detail page).
final class ProductSaved extends ProductsEvent {
  const ProductSaved(
    this.product, {
    this.announce = true,
    this.insertIfMissing = true,
  });

  final Product product;
  final bool announce;

  /// False for background syncs (e.g. a product opened from a URL that is
  /// not in the loaded list) — only update it if it is already listed.
  final bool insertIfMissing;

  @override
  List<Object?> get props => [product, announce, insertIfMissing];
}

final class ProductDeleteRequested extends ProductsEvent {
  const ProductDeleteRequested(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}
