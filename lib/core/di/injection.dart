import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/product.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/products/bloc/product_detail_bloc.dart';
import '../../features/products/bloc/product_form_bloc.dart';
import '../../features/products/bloc/products_bloc.dart';
import '../../features/users/bloc/users_bloc.dart';
import '../network/dio_client.dart';

/// Global service locator.
final getIt = GetIt.instance;

/// Registers every dependency. Lifetimes:
/// - **Singletons**: infrastructure, repositories and the app-wide [AuthBloc]
///   (the router listens to it for redirects).
/// - **Factories**: screen/session blocs. `get_it` only constructs them; the
///   widget tree owns their lifecycle through `BlocProvider`, which closes
///   them when their screen/session goes away.
///
/// [httpAdapter] lets tests fake the API transport while keeping the real
/// Dio configuration.
Future<void> configureDependencies({HttpClientAdapter? httpAdapter}) async {
  final prefs = await SharedPreferences.getInstance();

  getIt
    // Infrastructure
    ..registerSingleton<SharedPreferences>(prefs)
    ..registerLazySingleton<Dio>(
      () => createDio(
        adapter: httpAdapter,
        logging: kDebugMode && httpAdapter == null,
      ),
      dispose: (dio) => dio.close(),
    )
    // Repositories
    ..registerLazySingleton<UserRepository>(() => UserRepository(getIt()))
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepository(getIt(), getIt()),
    )
    ..registerLazySingleton<ProductRepository>(() => ProductRepository(getIt()))
    // App-wide bloc: restores the session as soon as it is created.
    ..registerLazySingleton<AuthBloc>(
      () => AuthBloc(getIt())..add(const AuthStarted()),
      dispose: (bloc) => bloc.close(),
    )
    // Session / screen blocs
    ..registerFactory<UsersBloc>(() => UsersBloc(getIt()))
    ..registerFactory<ProductsBloc>(() => ProductsBloc(getIt()))
    ..registerFactory<ProductFormBloc>(() => ProductFormBloc(getIt()))
    ..registerFactoryParam<ProductDetailBloc, int, Product?>(
      (productId, initial) =>
          ProductDetailBloc(getIt(), productId: productId, initial: initial),
    );
}
