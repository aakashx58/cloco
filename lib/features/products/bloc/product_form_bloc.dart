import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/app_exception.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';

// ---- Events ----------------------------------------------------------------

final class ProductFormSubmitted extends Equatable {
  const ProductFormSubmitted(this.draft, {required this.isNew});

  final Product draft;
  final bool isNew;

  @override
  List<Object?> get props => [draft, isNew];
}

// ---- State -----------------------------------------------------------------

enum ProductFormStatus { idle, submitting, success, failure }

final class ProductFormState extends Equatable {
  const ProductFormState({
    this.status = ProductFormStatus.idle,
    this.saved,
    this.error,
  });

  final ProductFormStatus status;
  final Product? saved;
  final String? error;

  bool get isSubmitting => status == ProductFormStatus.submitting;

  @override
  List<Object?> get props => [status, saved, error];
}

// ---- Bloc ------------------------------------------------------------------

/// Create (POST /products/add) or update (PUT /products/{id}) a product.
class ProductFormBloc extends Bloc<ProductFormSubmitted, ProductFormState> {
  ProductFormBloc(this._repository) : super(const ProductFormState()) {
    on<ProductFormSubmitted>(_onSubmitted);
  }

  final ProductRepository _repository;

  Future<void> _onSubmitted(
    ProductFormSubmitted event,
    Emitter<ProductFormState> emit,
  ) async {
    if (state.isSubmitting) return;
    emit(const ProductFormState(status: ProductFormStatus.submitting));
    try {
      final saved = event.isNew
          ? await _repository.createProduct(event.draft)
          : await _repository.replaceProduct(event.draft);
      emit(ProductFormState(status: ProductFormStatus.success, saved: saved));
    } on ApiException catch (error) {
      emit(
        ProductFormState(
          status: ProductFormStatus.failure,
          error: error.message,
        ),
      );
    }
  }
}
