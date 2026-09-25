import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/ui_message.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/password_field.dart';
import '../bloc/auth_bloc.dart';
import 'widgets/auth_scaffold.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, state) => state is AuthRegistered || state is AuthFailure,
      listener: (context, state) {
        if (ModalRoute.of(context)?.isCurrent != true) return;
        switch (state) {
          case AuthRegistered(:final email):
            context.pop(email);
          case AuthFailure(:final message):
            showAppSnackBar(context, UiMessage(message, isError: true));
          default:
            break;
        }
      },
      child: AuthScaffold(
        showBack: true,
        title: 'Create account',
        subtitle: 'Register a new admin. You will sign in right after.',
        form: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: Validators.name,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                ),
                SizedBox(height: 16.h),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  validator: Validators.email,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                SizedBox(height: 16.h),
                PasswordField(
                  controller: _passwordController,
                  helperText: 'At least 6 characters',
                  validator: Validators.password,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                ),
                SizedBox(height: 16.h),
                PasswordField(
                  controller: _confirmController,
                  label: 'Confirm password',
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (value) => value != _passwordController.text
                      ? 'Passwords do not match'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                SizedBox(height: 24.h),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => LoadingButton(
                    label: 'Create account',
                    icon: Icons.person_add_alt_1_rounded,
                    loading: state is AuthLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
        footer: AuthFooterLink(
          prompt: 'Already have an account?',
          action: 'Sign in',
          onPressed: () => context.pop(),
        ),
      ),
    );
  }
}
