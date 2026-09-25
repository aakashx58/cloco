import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/formatters.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/app_user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../bloc/users_bloc.dart';
import 'user_form_sheet.dart';

/// Users tab of the dashboard (the FAB lives in the dashboard scaffold).
class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filter(List<AppUser> users) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return users;
    return users
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = horizontalPaddingFor(MediaQuery.sizeOf(context).width);
    final currentUserId = context.select<AuthBloc, String?>(
      (bloc) => switch (bloc.state) {
        Authenticated(:final user) => user.id,
        _ => null,
      },
    );

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        if (state.status == UsersStatus.loading) {
          return const Center(child: CircularProgressIndicator());
        }
        final users = _filter(state.users);

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(padding, 8.h, padding, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Search by name or email',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(padding + 4, 14.h, padding, 6.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _query.isEmpty
                      ? '${state.users.length} registered '
                            '${state.users.length == 1 ? 'user' : 'users'}'
                      : '${users.length} of ${state.users.length} users',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            Expanded(
              child: users.isEmpty
                  ? EmptyState(
                      icon: Icons.person_search_outlined,
                      title: 'No users found',
                      subtitle: _query.isEmpty
                          ? 'Add a user to get started.'
                          : 'Try a different name or email.',
                    )
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(padding, 4.h, padding, 96.h),
                      itemCount: users.length,
                      separatorBuilder: (_, _) => SizedBox(height: 10.h),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _UserTile(
                          user: user,
                          isCurrentUser: user.id == currentUserId,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  const _UserTile({required this.user, required this.isCurrentUser});

  final AppUser user;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: EdgeInsets.fromLTRB(16.w, 8.h, 4.w, 8.h),
        onTap: () => openUserForm(context, user: user),
        leading: UserAvatar(user: user),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            if (isCurrentUser) ...[
              SizedBox(width: 8.w),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  'You',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${user.email}\nJoined ${Formatters.date(user.createdAt)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: PopupMenuButton<_UserAction>(
          tooltip: 'Actions',
          onSelected: (action) => switch (action) {
            _UserAction.edit => openUserForm(context, user: user),
            _UserAction.delete => confirmDeleteUser(context, user),
          },
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: _UserAction.edit,
              child: ListTile(
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem(
              value: _UserAction.delete,
              // Deleting yourself would leave the session pointing nowhere.
              enabled: !isCurrentUser,
              child: ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: isCurrentUser ? null : scheme.error,
                ),
                title: Text(
                  isCurrentUser ? "Can't delete yourself" : 'Delete',
                  style: TextStyle(color: isCurrentUser ? null : scheme.error),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _UserAction { edit, delete }
