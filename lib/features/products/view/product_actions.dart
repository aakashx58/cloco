import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../data/models/product.dart';
import '../bloc/products_bloc.dart';

/// Opens the add (`/products/new`) or edit (`/products/:id/edit`) form.
/// Returns the saved product (already pushed into [ProductsBloc]) or null if
/// the admin cancelled.
Future<Product?> openProductForm(
  BuildContext context, {
  Product? product,
}) async {
  final productsBloc = context.read<ProductsBloc>();
  final saved = await context.push<Product>(
    product == null ? AppRoutes.productNew : AppRoutes.productEdit(product.id),
    extra: product,
  );
  if (saved != null) productsBloc.add(ProductSaved(saved));
  return saved;
}

/// `/products/:id` — the list item is passed as `extra` so the page renders
/// instantly; the page also works from a bare URL (it fetches by id).
Future<void> openProductDetail(BuildContext context, Product product) =>
    context.push(AppRoutes.productDetail(product.id), extra: product);

/// Asks for confirmation, then dispatches the delete. Returns true if the
/// admin confirmed.
Future<bool> confirmDeleteProduct(BuildContext context, Product product) async {
  final productsBloc = context.read<ProductsBloc>();
  final confirmed = await showConfirmDialog(
    context,
    title: 'Delete product?',
    message: '"${product.title}" will be removed from the catalogue.',
    confirmLabel: 'Delete',
    icon: Icons.delete_outline_rounded,
    destructive: true,
  );
  if (confirmed) productsBloc.add(ProductDeleteRequested(product));
  return confirmed;
}
