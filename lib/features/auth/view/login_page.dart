import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/ui_message.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/loading_button.dart';
import '../../../core/widgets/password_field.dart';
import '../bloc/auth_bloc.dart';
import 'widgets/auth_scaffold.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        email: _emailController.text,
        password: _passwordController.text,
      ),
    );
  }

  Future<void> _openRegister() async {
    final email = await context.push<String>(AppRoutes.register);
    if (!mounted || email == null) return;
    // Spec 3.1.1: after registering, the admin lands back here to log in.
    _emailController.text = email;
    _passwordController.clear();
    showAppSnackBar(context, UiMessage('Account created! Please sign in.'));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (_, state) => state is AuthFailure,
      listener: (context, state) {
        // Register page may be on top and handles its own errors.
        if (ModalRoute.of(context)?.isCurrent != true) return;
        showAppSnackBar(
          context,
          UiMessage((state as AuthFailure).message, isError: true),
        );
      },
      child: AuthScaffold(
        title: 'Welcome back',
        subtitle: 'Sign in to manage users and products.',
        form: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              children: [
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
                  validator: (value) => value == null || value.isEmpty
                      ? 'Password is required'
                      : null,
                  onFieldSubmitted: (_) => _submit(),
                ),
                SizedBox(height: 24.h),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) => LoadingButton(
                    label: 'Sign in',
                    icon: Icons.login_rounded,
                    loading: state is AuthLoading,
                    onPressed: _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
        footer: AuthFooterLink(
          prompt: "Don't have an account?",
          action: 'Create one',
          onPressed: _openRegister,
        ),
      ),
    );
  }
}
