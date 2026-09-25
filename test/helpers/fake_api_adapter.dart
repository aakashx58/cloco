import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Fake HTTP transport for Dio: routes each request to [handler], which
/// returns `(statusCode, jsonBody)`. Every request is recorded in [requests]
/// (with `data` still the un-encoded body map) for assertions.
class FakeApiAdapter implements HttpClientAdapter {
  FakeApiAdapter(this.handler);

  final FutureOr<(int, Object?)> Function(RequestOptions request) handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final (status, body) = await handler(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Map<String, dynamic> fakeProductJson(int id, String title) => {
  'id': id,
  'title': title,
  'description': '$title description',
  'price': 100,
  'discountPercentage': 10,
  'rating': 4.2,
  'stock': 25,
  'brand': 'Acme',
  'category': 'smartphones',
  'thumbnail': '',
  'images': <String>[],
};

/// Mimics dummyjson: writes "succeed" but reads always return the same data.
FakeApiAdapter fakeDummyJson() => FakeApiAdapter((request) {
  final path = request.uri.path;
  if (request.method == 'GET' && path == '/products') {
    return (
      200,
      {
        'products': [
          fakeProductJson(1, 'Phone X'),
          fakeProductJson(2, 'Laptop Pro'),
        ],
        'total': 2,
        'skip': 0,
        'limit': 10,
      },
    );
  }
  if (path == '/products/categories') {
    return (
      200,
      [
        {'slug': 'smartphones', 'name': 'Smartphones', 'url': ''},
      ],
    );
  }
  if (path == '/products/add') return (201, {'id': 195});
  if (path == '/products/1') return (200, fakeProductJson(1, 'Phone X'));
  if (path == '/products/2') return (200, fakeProductJson(2, 'Laptop Pro'));
  return (404, {'message': "Product with id '$path' not found"});
});
