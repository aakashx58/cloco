import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';

abstract final class ApiConfig {
  static const baseUrl = 'https://dummyjson.com';
  static const timeout = Duration(seconds: 15);
}

/// Builds the app's single [Dio] instance (registered in get_it).
///
/// [adapter] replaces the HTTP transport, which is how tests fake the API
/// while keeping the real base URL, headers, timeouts and error mapping.
Dio createDio({HttpClientAdapter? adapter, bool logging = kDebugMode}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.timeout,
      receiveTimeout: ApiConfig.timeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json'},
    ),
  );
  if (adapter != null) dio.httpClientAdapter = adapter;
  if (logging) {
    dio.interceptors.add(
      LogInterceptor(
        requestHeader: false,
        responseHeader: false,
        requestBody: true,
        logPrint: (line) => debugPrint(line.toString()),
      ),
    );
  }
  return dio;
}

extension DioExceptionMapper on DioException {
  /// Converts transport/HTTP failures into a user-facing [ApiException].
  ApiException toApiException() {
    switch (type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.badResponse:
        final status = response?.statusCode;
        final data = response?.data;
        final message = data is Map && data['message'] is String
            ? data['message'] as String
            : 'Request failed${status == null ? '' : ' ($status)'}';
        return ApiException(message, statusCode: status);
      case DioExceptionType.cancel:
        return const ApiException('The request was cancelled.');
      case DioExceptionType.badCertificate:
        return const ApiException('Secure connection to the server failed.');
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'Network error. Please check your internet connection.',
        );
    }
  }
}
