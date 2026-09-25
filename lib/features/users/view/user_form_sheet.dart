import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/password_field.dart';
import '../../../data/models/app_user.dart';
import '../../../data/repositories/user_repository.dart';
import '../bloc/users_bloc.dart';

/// Opens the add/edit bottom sheet and dispatches the result to [UsersBloc].
Future<void> openUserForm(BuildContext context, {AppUser? user}) async {
  final bloc = context.read<UsersBloc>();
  final takenEmails = bloc.state.users
      .where((u) => u.id != user?.id)
      .map((u) => u.email)
      .toSet();

  final result = await showModalBottomSheet<_UserFormResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxWidth: 560.w),
    builder: (_) => _UserFormSheet(user: user, takenEmails: takenEmails),
  );
  if (result == null) return;

  if (user == null) {
    bloc.add(
      UserCreated(
        name: result.name,
        email: result.email,
        password: result.password!,
      ),
    );
  } else {
    bloc.add(
      UserUpdated(
        id: user.id,
        name: result.name,
        email: result.email,
        newPassword: result.password,
      ),
    );
  }
}

Future<void> confirmDeleteUser(BuildContext context, AppUser user) async {
  final bloc = context.read<UsersBloc>();
  final confirmed = await showConfirmDialog(
    context,
    title: 'Delete user?',
    message:
        '${user.name} (${user.email}) will no longer be able to sign in. '
        'This cannot be undone.',
    confirmLabel: 'Delete',
    icon: Icons.person_remove_outlined,
    destructive: true,
  );
  if (confirmed) bloc.add(UserDeleted(user));
}

class _UserFormResult {
  const _UserFormResult(this.name, this.email, this.password);

  final String name;
  final String email;
  final String? password;
}

class _UserFormSheet extends StatefulWidget {
  const _UserFormSheet({required this.user, required this.takenEmails});

  final AppUser? user;
  final Set<String> takenEmails;

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.user?.name);
  late final _emailController = TextEditingController(text: widget.user?.email);
  final _passwordController = TextEditingController();

  bool get _isEdit => widget.user != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final error = Validators.email(value);
    if (error != null) return error;
    if (widget.takenEmails.contains(UserRepository.normalizeEmail(value!))) {
      return 'An account with this email already exists';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final password = _passwordController.text;
    Navigator.of(context).pop(
      _UserFormResult(
        _nameController.text,
        _emailController.text,
        password.isEmpty ? null : password,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 24.h),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit ? 'Edit user' : 'Add user',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                _isEdit
                    ? 'Update details. Leave the password blank to keep it.'
                    : 'New users can sign in with these credentials.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 20.h),
              TextFormField(
                controller: _nameController,
                autofocus: !_isEdit,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: Validators.name,
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              SizedBox(height: 14.h),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                validator: _validateEmail,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
              ),
              SizedBox(height: 14.h),
              PasswordField(
                controller: _passwordController,
                label: _isEdit ? 'New password (optional)' : 'Password',
                helperText: 'At least 6 characters',
                autofillHints: const [AutofillHints.newPassword],
                validator: _isEdit
                    ? Validators.optionalPassword
                    : Validators.password,
                onFieldSubmitted: (_) => _submit(),
              ),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submit,
                      child: Text(_isEdit ? 'Save changes' : 'Add user'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
