import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/product.dart';
import '../../features/auth/bloc/auth_bloc.dart';
import '../../features/auth/view/login_page.dart';
import '../../features/auth/view/register_page.dart';
import '../../features/auth/view/splash_page.dart';
import '../../features/dashboard/view/dashboard_shell.dart';
import '../../features/dashboard/view/session_scope.dart';
import '../../features/products/bloc/product_detail_bloc.dart';
import '../../features/products/bloc/product_form_bloc.dart';
import '../../features/products/bloc/products_bloc.dart';
import '../../features/products/view/product_detail_page.dart';
import '../../features/products/view/product_form_page.dart';
import '../../features/products/view/products_page.dart';
import '../../features/users/view/users_page.dart';
import '../di/injection.dart';
import '../widgets/not_found_page.dart';
import 'app_routes.dart';
import 'stream_listenable.dart';

/// Route tree:
///
/// ```text
/// /splash
/// /login
///   └ register
/// [SessionScope shell]            ← Users/Products blocs live here
///   ├ [Dashboard tabs shell]      ← bottom nav / rail
///   │   ├ /products
///   │   └ /users
///   ├ /products/new               ← full screen, covers the tabs
///   ├ /products/:id/edit
///   └ /products/:id
/// ```
class AppRouter {
  AppRouter(this._authBloc);

  final AuthBloc _authBloc;

  final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final _sessionNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'session');

  /// Refresh routing only when the signed-in status actually changes.
  /// Transient states (loading, failure, registered) must not trigger a
  /// refresh: one racing a `pop` (register → login) would restore the stale
  /// location and re-show the page that was just closed.
  late final StreamListenable _authChanges = StreamListenable(
    _authBloc.stream.map(_sessionStatus).distinct(),
  );

  static _SessionStatus _sessionStatus(AuthState state) => switch (state) {
    AuthInitial() => _SessionStatus.unknown,
    Authenticated() => _SessionStatus.signedIn,
    _ => _SessionStatus.signedOut,
  };

  late final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.products,
    refreshListenable: _authChanges,
    redirect: (context, state) =>
        AppRoutes.redirect(_authBloc.state, state.uri),
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _fade(state, const SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _fade(state, const LoginPage()),
        routes: [
          GoRoute(
            path: 'register',
            builder: (context, state) => const RegisterPage(),
          ),
        ],
      ),
      // Everything below requires a session. Leaving this shell (logout)
      // disposes the session blocs, so the next login starts fresh.
      ShellRoute(
        navigatorKey: _sessionNavigatorKey,
        pageBuilder: (context, state, child) =>
            _fade(state, SessionScope(child: child)),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                DashboardShell(navigationShell: navigationShell),
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.products,
                    builder: (context, state) => const ProductsPage(),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: AppRoutes.users,
                    builder: (context, state) => const UsersPage(),
                  ),
                ],
              ),
            ],
          ),
          // Order matters: `new` and `:id/edit` before `:id`.
          GoRoute(
            path: AppRoutes.productNew,
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: BlocProvider(
                create: (_) => getIt<ProductFormBloc>(),
                child: Builder(
                  builder: (context) => ProductFormPage(
                    categories: context.read<ProductsBloc>().state.categories,
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/products/:id/edit',
            // The form needs the product; without it (e.g. a browser
            // refresh on the edit URL) fall back to the detail page.
            redirect: (context, state) => state.extra is Product
                ? null
                : AppRoutes.productDetail(
                    int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
                  ),
            pageBuilder: (context, state) => MaterialPage(
              key: state.pageKey,
              fullscreenDialog: true,
              child: BlocProvider(
                create: (_) => getIt<ProductFormBloc>(),
                child: Builder(
                  builder: (context) => ProductFormPage(
                    product: state.extra! as Product,
                    categories: context.read<ProductsBloc>().state.categories,
                  ),
                ),
              ),
            ),
          ),
          GoRoute(
            path: '/products/:id',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '');
              if (id == null) {
                return const NotFoundPage(message: 'Invalid product id.');
              }
              final extra = state.extra;
              return BlocProvider(
                create: (_) => getIt<ProductDetailBloc>(
                  param1: id,
                  param2: extra is Product ? extra : null,
                )..add(const ProductDetailRequested()),
                child: const ProductDetailPage(),
              );
            },
          ),
        ],
      ),
    ],
  );

  void dispose() {
    router.dispose();
    _authChanges.dispose();
  }

  static Page<void> _fade(GoRouterState state, Widget child) =>
      CustomTransitionPage<void>(
        key: state.pageKey,
        child: child,
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      );
}

enum _SessionStatus { unknown, signedIn, signedOut }
