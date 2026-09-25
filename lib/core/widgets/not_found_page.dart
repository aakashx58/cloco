import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router/app_routes.dart';
import 'empty_state.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: EmptyState(
        icon: Icons.explore_off_outlined,
        title: 'Page not found',
        subtitle: message ?? "The page you're looking for doesn't exist.",
        action: FilledButton.icon(
          onPressed: () => context.go(AppRoutes.products),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Go to dashboard'),
        ),
      ),
    );
  }
}
