import 'dart:async';
import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/ui_message.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/models/product_category.dart';
import '../../../data/repositories/product_repository.dart';

part 'products_event.dart';
part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  ProductsBloc(this._repository) : super(const ProductsState()) {
    on<ProductsStarted>(_onStarted);
    on<ProductsRefreshed>(_onRefreshed);
    on<ProductsNextPageRequested>(_onNextPageRequested);
    on<ProductsQueryChanged>(_onQueryChanged);
    on<ProductsCategoryChanged>(_onCategoryChanged);
    on<ProductSaved>(_onSaved);
    on<ProductDeleteRequested>(_onDeleteRequested);
  }

  static const pageSize = 10;

  final ProductRepository _repository;

  /// Incremented per first-page load; responses from an outdated
  /// search/category are dropped so fast typing never shows stale results.
  int _requestId = 0;

  Future<void> _onStarted(
    ProductsStarted event,
    Emitter<ProductsState> emit,
  ) async {
    await Future.wait([_loadCategories(emit), _loadFirstPage(emit)]);
  }

  Future<void> _onRefreshed(
    ProductsRefreshed event,
    Emitter<ProductsState> emit,
  ) async {
    try {
      await _loadFirstPage(emit, showLoading: state.products.isEmpty);
      if (state.categories.isEmpty) await _loadCategories(emit);
    } finally {
      event.completer?.complete();
    }
  }

  Future<void> _onNextPageRequested(
    ProductsNextPageRequested event,
    Emitter<ProductsState> emit,
  ) async {
    final canLoad =
        state.status == ProductsStatus.success &&
        state.hasMore &&
        !state.isLoadingMore &&
        (!state.loadMoreFailed || event.retry);
    if (!canLoad) return;

    final requestId = _requestId;
    emit(state.copyWith(isLoadingMore: true, loadMoreFailed: false));
    try {
      final page = await _repository.fetchProducts(
        skip: state.nextSkip,
        limit: pageSize,
        query: state.query,
        category: state.category,
      );
      if (requestId != _requestId) return;
      final known = state.products.map((product) => product.id).toSet();
      emit(
        state.copyWith(
          products: [
            ...state.products,
            ...page.items.where((product) => !known.contains(product.id)),
          ],
          nextSkip: page.nextSkip,
          hasMore: page.hasMore,
          isLoadingMore: false,
        ),
      );
    } on ApiException catch (error) {
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          isLoadingMore: false,
          loadMoreFailed: true,
          message: UiMessage(error.message, isError: true),
        ),
      );
    }
  }

  /// Searching clears the category filter (dummyjson cannot combine them).
  Future<void> _onQueryChanged(
    ProductsQueryChanged event,
    Emitter<ProductsState> emit,
  ) async {
    final query = event.query.trim();
    if (query == state.query && state.status != ProductsStatus.failure) {
      return;
    }
    emit(state.copyWith(query: query, clearCategory: true));
    await _loadFirstPage(emit);
  }

  /// Picking a category clears the search.
  Future<void> _onCategoryChanged(
    ProductsCategoryChanged event,
    Emitter<ProductsState> emit,
  ) async {
    if (event.slug == state.category && state.query.isEmpty) return;
    emit(
      state.copyWith(
        category: event.slug,
        clearCategory: event.slug == null,
        query: '',
      ),
    );
    await _loadFirstPage(emit);
  }

  void _onSaved(ProductSaved event, Emitter<ProductsState> emit) {
    final products = [...state.products];
    final index = products.indexWhere((p) => p.id == event.product.id);
    final isNew = index < 0;
    if (isNew && !event.insertIfMissing) return;
    if (isNew) {
      products.insert(0, event.product);
    } else {
      products[index] = event.product;
    }
    emit(
      state.copyWith(
        products: products,
        total: isNew ? state.total + 1 : state.total,
        message: event.announce
            ? UiMessage(
                isNew
                    ? '"${event.product.title}" added'
                    : '"${event.product.title}" updated',
              )
            : null,
      ),
    );
  }

  Future<void> _onDeleteRequested(
    ProductDeleteRequested event,
    Emitter<ProductsState> emit,
  ) async {
    final id = event.product.id;
    if (state.deletingIds.contains(id)) return;
    emit(state.copyWith(deletingIds: {...state.deletingIds, id}));
    try {
      await _repository.deleteProduct(event.product);
      emit(
        state.copyWith(
          products: state.products.where((p) => p.id != id).toList(),
          total: max(0, state.total - 1),
          deletingIds: {...state.deletingIds}..remove(id),
          message: UiMessage('"${event.product.title}" deleted'),
        ),
      );
    } on ApiException catch (error) {
      emit(
        state.copyWith(
          deletingIds: {...state.deletingIds}..remove(id),
          message: UiMessage(error.message, isError: true),
        ),
      );
    }
  }

  Future<void> _loadCategories(Emitter<ProductsState> emit) async {
    try {
      final categories = await _repository.fetchCategories();
      emit(state.copyWith(categories: categories));
    } on ApiException {
      // Non-critical: the chips row is simply hidden; retried on refresh.
    }
  }

  Future<void> _loadFirstPage(
    Emitter<ProductsState> emit, {
    bool showLoading = true,
  }) async {
    final requestId = ++_requestId;
    if (showLoading) {
      emit(
        state.copyWith(
          status: ProductsStatus.loading,
          products: const [],
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      );
    }
    try {
      final page = await _repository.fetchProducts(
        skip: 0,
        limit: pageSize,
        query: state.query,
        category: state.category,
      );
      if (requestId != _requestId) return;
      emit(
        state.copyWith(
          status: ProductsStatus.success,
          products: page.items,
          total: page.total,
          nextSkip: page.nextSkip,
          hasMore: page.hasMore,
          isLoadingMore: false,
          loadMoreFailed: false,
        ),
      );
    } on ApiException catch (error) {
      if (requestId != _requestId) return;
      if (state.products.isEmpty) {
        emit(
          state.copyWith(status: ProductsStatus.failure, error: error.message),
        );
      } else {
        // Keep showing the current list; just report the failed refresh.
        emit(state.copyWith(message: UiMessage(error.message, isError: true)));
      }
    }
  }
}
