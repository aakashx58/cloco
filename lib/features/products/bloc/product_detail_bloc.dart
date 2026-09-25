import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ui_message.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';

// ---- Events ----------------------------------------------------------------

sealed class ProductDetailEvent extends Equatable {
  const ProductDetailEvent();

  @override
  List<Object?> get props => [];
}

/// GET /products/{id}. When opened from the list the item is already shown
/// and this refreshes it; when opened from a URL this is the first load.
final class ProductDetailRequested extends ProductDetailEvent {
  const ProductDetailRequested();
}

/// PATCH /products/{id} with only the `stock` field.
final class ProductStockUpdateRequested extends ProductDetailEvent {
  const ProductStockUpdateRequested(this.stock);

  final int stock;

  @override
  List<Object?> get props => [stock];
}

/// The product was edited via the form page.
final class ProductDetailReplaced extends ProductDetailEvent {
  const ProductDetailReplaced(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

// ---- State -----------------------------------------------------------------

final class ProductDetailState extends Equatable {
  const ProductDetailState({
    required this.productId,
    this.product,
    this.isRefreshing = false,
    this.isUpdatingStock = false,
    this.loadError,
    this.message,
  });

  final int productId;

  /// Null until loaded when the page was opened from a URL.
  final Product? product;
  final bool isRefreshing;
  final bool isUpdatingStock;

  /// Set when the product could not be loaded at all (nothing to show).
  final String? loadError;
  final UiMessage? message;

  ProductDetailState copyWith({
    Product? product,
    bool? isRefreshing,
    bool? isUpdatingStock,
    String? loadError,
    bool clearLoadError = false,
    UiMessage? message,
  }) => ProductDetailState(
    productId: productId,
    product: product ?? this.product,
    isRefreshing: isRefreshing ?? this.isRefreshing,
    isUpdatingStock: isUpdatingStock ?? this.isUpdatingStock,
    loadError: clearLoadError ? null : (loadError ?? this.loadError),
    message: message ?? this.message,
  );

  @override
  List<Object?> get props => [
    productId,
    product,
    isRefreshing,
    isUpdatingStock,
    loadError,
    message,
  ];
}

// ---- Bloc ------------------------------------------------------------------

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc(
    this._repository, {
    required int productId,
    Product? initial,
  }) : super(ProductDetailState(productId: productId, product: initial)) {
    on<ProductDetailRequested>(_onRequested);
    on<ProductStockUpdateRequested>(_onStockUpdateRequested);
    on<ProductDetailReplaced>(
      (event, emit) => emit(state.copyWith(product: event.product)),
    );
  }

  final ProductRepository _repository;

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, clearLoadError: true));
    try {
      final product = await _repository.fetchProduct(state.productId);
      emit(state.copyWith(product: product, isRefreshing: false));
    } on ApiException catch (error) {
      if (state.product == null) {
        emit(state.copyWith(isRefreshing: false, loadError: error.message));
      } else {
        // Keep showing the list's copy; just report the failed refresh.
        emit(
          state.copyWith(
            isRefreshing: false,
            message: UiMessage(
              'Could not refresh details: ${error.message}',
              isError: true,
            ),
          ),
        );
      }
    }
  }

  Future<void> _onStockUpdateRequested(
    ProductStockUpdateRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    final product = state.product;
    if (product == null ||
        event.stock == product.stock ||
        state.isUpdatingStock) {
      return;
    }
    emit(state.copyWith(isUpdatingStock: true));
    try {
      final updated = await _repository.patchProduct(
        product.copyWith(stock: event.stock),
        {'stock': event.stock},
      );
      emit(
        state.copyWith(
          product: updated,
          isUpdatingStock: false,
          message: UiMessage('Stock updated to ${event.stock}'),
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          isUpdatingStock: false,
          message: UiMessage(error.message, isError: true),
        ),
      );
    }
  }
}
