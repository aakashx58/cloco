import 'package:cloco/core/errors/app_exception.dart';
import 'package:cloco/core/network/dio_client.dart';
import 'package:cloco/data/models/product.dart';
import 'package:cloco/data/repositories/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_api_adapter.dart';

const _draft = Product(
  id: 0,
  title: 'Tablet',
  description: '',
  price: 99,
  discountPercentage: 0,
  rating: 0,
  stock: 3,
  category: 'tablets',
  thumbnail: '',
);

void main() {
  late FakeApiAdapter api;
  late ProductRepository repository;

  setUp(() {
    api = fakeDummyJson();
    repository = ProductRepository(createDio(adapter: api, logging: false));
  });

  test('sends paging as query parameters to the dummyjson base URL', () async {
    await repository.fetchProducts(skip: 0, limit: 10);

    final uri = api.requests.single.uri;
    expect(uri.host, 'dummyjson.com');
    expect(uri.scheme, 'https');
    expect(uri.queryParameters, {'limit': '10', 'skip': '0'});
  });

  test(
    'created products appear on the first page with a unique local id',
    () async {
      final saved = await repository.createProduct(_draft);
      final page = await repository.fetchProducts(skip: 0, limit: 10);

      expect(saved.isLocal, isTrue);
      expect(saved.id, isNot(195));
      expect(page.items.first.title, 'Tablet');
      expect(page.total, 3);
    },
  );

  test('deleted products stay hidden after a refetch', () async {
    final first = await repository.fetchProducts(skip: 0, limit: 10);
    await repository.deleteProduct(first.items.first);
    final again = await repository.fetchProducts(skip: 0, limit: 10);

    expect(api.requests.any((r) => r.method == 'DELETE'), isTrue);
    expect(again.items.map((p) => p.id), [2]);
  });

  test(
    'PATCH sends only the changed fields and the edit survives a refetch',
    () async {
      final first = await repository.fetchProducts(skip: 0, limit: 10);
      final product = first.items.first;
      await repository.patchProduct(product.copyWith(stock: 7), {'stock': 7});

      final patch = api.requests.singleWhere((r) => r.method == 'PATCH');
      expect(patch.data, {'stock': 7});

      final again = await repository.fetchProducts(skip: 0, limit: 10);
      expect(again.items.first.stock, 7);
    },
  );

  test(
    'local products are updated in memory without calling the API',
    () async {
      final saved = await repository.createProduct(_draft);
      await repository.replaceProduct(saved.copyWith(stock: 50));

      expect(api.requests.any((r) => r.method == 'PUT'), isFalse);
      final fetched = await repository.fetchProduct(saved.id);
      expect(fetched.stock, 50);
    },
  );

  test('HTTP errors surface the API message as an ApiException', () async {
    await expectLater(
      repository.fetchProduct(999),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.message, 'message', contains('not found')),
      ),
    );
  });
}
