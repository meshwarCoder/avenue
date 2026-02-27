import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/utils/constants.dart';
import '../widgets/social_login_row.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_action_button.dart';
import '../../../../core/widgets/avenue_loading.dart';
import '../../../../core/widgets/offline_banner.dart';
import '../../../../core/utils/validation.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFieldKey = GlobalKey<AuthTextFieldState>();
  final _passwordFieldKey = GlobalKey<AuthTextFieldState>();
  final _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidateMode = AutovalidateMode.disabled;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    // Don't show snackbar if offline banner is already visible
    if (GlobalConnectivity.offline) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final shouldShowOverlay =
            state is AuthLoading && state.source == AuthLoadingSource.other;

        return AvenueLoadingOverlay(
          isLoading: shouldShowOverlay,
          child: Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is Authenticated) {
                  context.go('/schedule');
                } else if (state is AuthError) {
                  _showErrorSnackBar(state.message);
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Decorative Elements
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (isDark
                                    ? AppColors.slatePurple
                                    : AppColors.creamTan)
                                .withOpacity(0.08),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -150,
                    left: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            (isDark
                                    ? AppColors.salmonPink
                                    : AppColors.deepPurple)
                                .withOpacity(0.05),
                      ),
                    ),
                  ),

                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(32, 60, 32, 32),
                      child: Form(
                        key: _formKey,
                        autovalidateMode: _autoValidateMode,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AuthHeader(
                              title: "Avenue",
                              subtitle: "Your productivity companion",
                            ),
                            const SizedBox(height: 48),

                            // Email Field
                            AuthTextField(
                              key: _emailFieldKey,
                              controller: _emailController,
                              label: "Email",
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: Validation.validateEmail,
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            AuthTextField(
                              key: _passwordFieldKey,
                              controller: _passwordController,
                              label: "Password",
                              icon: Icons.lock_outline_rounded,
                              obscureText: _obscurePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_rounded
                                      : Icons.visibility_rounded,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.6),
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                              validator: Validation.validatePassword,
                            ),

                            const SizedBox(height: 32),

                            // Login Button
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                return AuthActionButton(
                                  text: "Sign In",
                                  isLoading:
                                      state is AuthLoading &&
                                      state.source == AuthLoadingSource.email,
                                  onPressed: () {
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AuthCubit>().signIn(
                                        email: _emailController.text.trim(),
                                        password: _passwordController.text
                                            .trim(),
                                      );
                                    } else {
                                      _emailFieldKey.currentState
                                          ?.shakeIfInvalid();
                                      _passwordFieldKey.currentState
                                          ?.shakeIfInvalid();
                                      setState(() {
                                        _autoValidateMode =
                                            AutovalidateMode.onUserInteraction;
                                      });
                                    }
                                  },
                                );
                              },
                            ),

                            const SizedBox(height: 24),

                            // Divider
                            Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.1),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    "OR",
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.5),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.1),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 24),

                            // Social Login Row (Google, Apple, Facebook)
                            const SocialLoginRow(),

                            const SizedBox(height: 24),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "New to Avenue?",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/register'),
                                  child: const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      color: AppColors.salmonPink,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
