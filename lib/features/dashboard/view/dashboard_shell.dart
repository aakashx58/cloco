import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/app_user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../products/bloc/products_bloc.dart';
import '../../products/view/product_actions.dart';
import '../../users/bloc/users_bloc.dart';
import '../../users/view/user_form_sheet.dart';

/// Tab chrome for `/products` and `/users` (a go_router
/// `StatefulShellRoute`, so each tab keeps its own scroll/search state).
class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = [
    (
      icon: Icons.shopping_bag_outlined,
      selectedIcon: Icons.shopping_bag_rounded,
      label: 'Products',
    ),
    (
      icon: Icons.group_outlined,
      selectedIcon: Icons.group_rounded,
      label: 'Users',
    ),
  ];

  void _selectTab(int index) => navigationShell.goBranch(
    index,
    // Tapping the active tab again returns it to its root.
    initialLocation: index == navigationShell.currentIndex,
  );

  Future<void> _logout(BuildContext context) async {
    final authBloc = context.read<AuthBloc>();
    final confirmed = await showConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to manage the catalogue.',
      confirmLabel: 'Log out',
      icon: Icons.logout_rounded,
    );
    // The router's auth guard takes care of navigating to /login.
    if (confirmed) authBloc.add(const AuthLogoutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final index = navigationShell.currentIndex;
    final user = context.select<AuthBloc, AppUser?>(
      (bloc) => switch (bloc.state) {
        Authenticated(:final user) => user,
        _ => null,
      },
    );
    final isWide = MediaQuery.sizeOf(context).width >= 840;

    return MultiBlocListener(
      listeners: [
        BlocListener<ProductsBloc, ProductsState>(
          listenWhen: (p, c) => p.message != c.message && c.message != null,
          listener: (context, state) =>
              showAppSnackBar(context, state.message!),
        ),
        BlocListener<UsersBloc, UsersState>(
          listenWhen: (p, c) => p.message != c.message && c.message != null,
          listener: (context, state) =>
              showAppSnackBar(context, state.message!),
        ),
        // The admin may have edited their own name/email.
        BlocListener<UsersBloc, UsersState>(
          listenWhen: (p, c) => p.users != c.users,
          listener: (context, _) =>
              context.read<AuthBloc>().add(const AuthUserRefreshed()),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 68.h,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _destinations[index].label,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (user != null)
                Text(
                  'Welcome back, ${Formatters.firstName(user.name)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          actions: [
            if (user != null)
              _AccountMenu(user: user, onLogout: () => _logout(context)),
            SizedBox(width: 12.w),
          ],
        ),
        body: isWide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: index,
                    onDestinationSelected: _selectTab,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selectedIcon),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: navigationShell),
                ],
              )
            : navigationShell,
        bottomNavigationBar: isWide
            ? null
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: _selectTab,
                destinations: [
                  for (final d in _destinations)
                    NavigationDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: d.label,
                    ),
                ],
              ),
        floatingActionButton: index == 0
            ? FloatingActionButton.extended(
                heroTag: 'add-product',
                onPressed: () => openProductForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add product'),
              )
            : FloatingActionButton.extended(
                heroTag: 'add-user',
                onPressed: () => openUserForm(context),
                icon: const Icon(Icons.person_add_alt_1_rounded),
                label: const Text('Add user'),
              ),
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.user, required this.onLogout});

  final AppUser user;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      offset: const Offset(0, 52),
      onSelected: (value) {
        if (value == 'logout') onLogout();
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          enabled: false,
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: UserAvatar(user: user, radius: 18),
            title: Text(user.name),
            subtitle: Text(user.email),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.logout_rounded),
            title: Text('Log out'),
          ),
        ),
      ],
      child: UserAvatar(user: user, radius: 20),
    );
  }
}
