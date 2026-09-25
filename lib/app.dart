import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/responsive.dart';
import 'features/auth/bloc/auth_bloc.dart';

class ProductManagerApp extends StatefulWidget {
  const ProductManagerApp({super.key});

  @override
  State<ProductManagerApp> createState() => _ProductManagerAppState();
}

class _ProductManagerAppState extends State<ProductManagerApp> {
  final _authBloc = getIt<AuthBloc>();
  late final _appRouter = AppRouter(_authBloc);

  @override
  void dispose() {
    _appRouter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds on resize/rotation: the design size is derived from the
    // screen so screenutil's scale stays a bounded, uniform zoom
    // (see Responsive).
    final screen = MediaQuery.sizeOf(context);

    return ScreenUtilInit(
      designSize: Responsive.designSizeFor(screen),
      minTextAdapt: true,
      fontSizeResolver: FontSizeResolvers.radius,
      // The theme uses `.sp`/`.r`, so it must be built inside the builder,
      // after ScreenUtil has been configured.
      builder: (context, _) => BlocProvider.value(
        // AuthBloc is a DI singleton (the router needs it too), so it is
        // exposed with `.value`: get_it owns its lifecycle, not this widget.
        value: _authBloc,
        child: MaterialApp.router(
          title: 'Product Manager',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: _appRouter.router,
        ),
      ),
    );
  }
}
