import '../../features/auth/bloc/auth_bloc.dart';

/// Route paths, in one place so screens never hard-code URLs.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/login/register';
  static const products = '/products';
  static const users = '/users';
  static const productNew = '/products/new';

  static String productDetail(int id) => '/products/$id';
  static String productEdit(int id) => '/products/$id/edit';

  static const fromParam = 'from';

  /// Auth guard used by the router's top-level `redirect`. A pure function
  /// of the auth state and the requested location, so it is unit-testable.
  ///
  /// - Session not checked yet → splash (remembering the requested page).
  /// - Signed out → login, except on login/register.
  /// - Signed in → away from splash/login to the remembered page or products.
  static String? redirect(AuthState auth, Uri location) {
    final path = location.path;
    final isSplash = path == splash;
    final isAuthPage = path == login || path.startsWith('$login/');
    final from = _safeFrom(location.queryParameters[fromParam]);

    if (auth is AuthInitial) {
      if (isSplash) return null;
      return _withFrom(splash, isAuthPage ? null : location.toString());
    }

    if (auth is Authenticated) {
      return isSplash || isAuthPage ? (from ?? products) : null;
    }

    // Signed out (also covers loading/failure/registered on the auth pages).
    if (isAuthPage) return null;
    return _withFrom(login, isSplash ? from : location.toString());
  }

  static String _withFrom(String path, String? from) => from == null
      ? path
      : Uri(path: path, queryParameters: {fromParam: from}).toString();

  /// Only same-app paths, and never back into splash/login (no loops or
  /// open redirects).
  static String? _safeFrom(String? from) {
    if (from == null || !from.startsWith('/') || from.startsWith('//')) {
      return null;
    }
    if (from.startsWith(splash) || from.startsWith(login)) return null;
    return from;
  }
}
