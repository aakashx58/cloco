import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import '../../products/bloc/products_bloc.dart';
import '../../users/bloc/users_bloc.dart';

/// Provides the blocs shared by every signed-in screen (dashboard tabs,
/// product detail and forms). Mounted by the session `ShellRoute`, so the
/// blocs are created on login and closed on logout.
class SessionScope extends StatelessWidget {
  const SessionScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UsersBloc>(
          create: (_) => getIt<UsersBloc>()..add(const UsersRequested()),
        ),
        BlocProvider<ProductsBloc>(
          create: (_) => getIt<ProductsBloc>()..add(const ProductsStarted()),
        ),
      ],
      child: child,
    );
  }
}
