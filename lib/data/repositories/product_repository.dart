import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../models/product.dart';
import '../models/product_category.dart';

class ProductPage {
  const ProductPage({
    required this.items,
    required this.nextSkip,
    required this.total,
    required this.hasMore,
  });

  final List<Product> items;
  final int nextSkip;
  final int total;
  final bool hasMore;
}

/// Talks to https://dummyjson.com/products.
///
/// dummyjson *simulates* POST/PUT/PATCH/DELETE: it returns a success response
/// but never changes its data. To make CRUD behave correctly in the UI, this
/// repository keeps a session-level overlay of created, edited and deleted
/// products and applies it to every fetch, so changes survive paging,
/// search, category switches and pull-to-refresh until the app restarts.
class ProductRepository {
  /// [_dio] is the shared client from DI (base URL, timeouts, logging).
  ProductRepository(this._dio);

  final Dio _dio;

  final List<Product> _created = [];
  final Map<int, Product> _edited = {};
  final Set<int> _deleted = {};

  // dummyjson returns the same id (total + 1) for every added product, so
  // locally created products get their own ids, well clear of the API's.
  int _nextLocalId = 1000000;

  /// GET /products, /products/search?q= or /products/category/{slug}.
  /// A search takes precedence over a category (the API cannot combine them).
  Future<ProductPage> fetchProducts({
    required int skip,
    required int limit,
    String query = '',
    String? category,
  }) async {
    final params = <String, dynamic>{'limit': limit, 'skip': skip};
    final String path;
    if (query.isNotEmpty) {
      path = '/products/search';
      params['q'] = query;
    } else if (category != null) {
      path = '/products/category/$category';
    } else {
      path = '/products';
    }

    final json = await _request('GET', path, query: params);
    return _parse(() {
      final map = json as Map<String, dynamic>;
      final raw = (map['products'] as List<dynamic>)
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList();
      final apiTotal = (map['total'] as num?)?.toInt() ?? raw.length;

      final items = raw
          .where((product) => !_deleted.contains(product.id))
          .map((product) => _edited[product.id] ?? product)
          .toList();
      final localMatches = _created
          .where((product) => _matchesLocal(product, query, category))
          .toList();
      final deletedCount = query.isEmpty && category == null
          ? _deleted.length
          : 0;

      return ProductPage(
        items: skip == 0 ? [...localMatches, ...items] : items,
        nextSkip: skip + raw.length,
        total: (apiTotal + localMatches.length - deletedCount).clamp(
          0,
          1 << 31,
        ),
        hasMore: raw.isNotEmpty && skip + raw.length < apiTotal,
      );
    });
  }

  /// GET /products/{id}
  Future<Product> fetchProduct(int id) async {
    final local = _created.where((product) => product.id == id).firstOrNull;
    if (local != null) return local;
    if (_deleted.contains(id)) {
      throw const ApiException('This product has been deleted');
    }
    // The server would return pre-edit data, so prefer our edited copy.
    final edited = _edited[id];
    if (edited != null) return edited;

    final json = await _request('GET', '/products/$id');
    return _parse(() => Product.fromJson(json as Map<String, dynamic>));
  }

  /// GET /products/categories
  Future<List<ProductCategory>> fetchCategories() async {
    final json = await _request('GET', '/products/categories');
    return _parse(
      () => (json as List<dynamic>).map(ProductCategory.fromJson).toList(),
    );
  }

  /// POST /products/add
  Future<Product> createProduct(Product draft) async {
    await _request('POST', '/products/add', body: draft.toApiJson());
    final saved = draft.copyWith(id: _nextLocalId++, isLocal: true);
    _created.insert(0, saved);
    return saved;
  }

  /// PUT /products/{id} — full replace of the editable fields.
  Future<Product> replaceProduct(Product product) async {
    if (product.isLocal) return _updateLocal(product);
    await _request('PUT', '/products/${product.id}', body: product.toApiJson());
    _edited[product.id] = product;
    return product;
  }

  /// PATCH /products/{id} — sends only [changes]; [product] is the full
  /// product with those changes already applied.
  Future<Product> patchProduct(
    Product product,
    Map<String, dynamic> changes,
  ) async {
    if (product.isLocal) return _updateLocal(product);
    await _request('PATCH', '/products/${product.id}', body: changes);
    _edited[product.id] = product;
    return product;
  }

  /// DELETE /products/{id}
  Future<void> deleteProduct(Product product) async {
    if (product.isLocal) {
      _created.removeWhere((item) => item.id == product.id);
      return;
    }
    await _request('DELETE', '/products/${product.id}');
    _deleted.add(product.id);
    _edited.remove(product.id);
  }

  // Locally created products do not exist on the server, so a PUT/PATCH for
  // them would 404 — they are updated in memory only.
  Product _updateLocal(Product product) {
    final index = _created.indexWhere((item) => item.id == product.id);
    if (index >= 0) _created[index] = product;
    return product;
  }

  bool _matchesLocal(Product product, String query, String? category) {
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      return product.title.toLowerCase().contains(q) ||
          (product.brand?.toLowerCase().contains(q) ?? false) ||
          product.description.toLowerCase().contains(q);
    }
    return category == null || product.category == category;
  }

  T _parse<T>(T Function() parse) {
    try {
      return parse();
    } on TypeError {
      throw const ApiException('Received unexpected data from the server.');
    }
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await _dio.request<dynamic>(
        path,
        data: body,
        queryParameters: query,
        options: Options(method: method),
      );
      return response.data;
    } on DioException catch (error) {
      throw error.toApiException();
    }
  }
}
