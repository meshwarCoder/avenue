import 'package:flutter/material.dart';
import 'package:avenue/l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/utils/constants.dart';
import '../widgets/social_login_row.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_text_field.dart';
import '../widgets/auth_action_button.dart';
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
        final isLoading = state is AuthLoading;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: ConnectivityBannerWrapper(
            child: BlocListener<AuthCubit, AuthState>(
              listener: (context, state) {
                if (state is Authenticated) {
                  context.go('/schedule');
                } else if (state is AuthError) {
                  _showErrorSnackBar(state.message);
                } else if (state is PasswordResetOtpSent) {
                  _showOtpVerificationDialog(context, state.email);
                } else if (state is PasswordResetOtpVerified) {
                  _showResetPasswordDialog(context, state.email, state.otp);
                } else if (state is PasswordResetSuccess) {
                  _showSuccessSnackBar(
                    "Password reset successfully! You can now sign in.",
                  );
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Decorative Elements
                  Positioned(
                    top: -100,
                    right: -100,
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    top: -100,
                    end: -100,
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
                  Positioned.directional(
                    textDirection: Directionality.of(context),
                    bottom: -150,
                    start: -100,
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
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        32,
                        60,
                        32,
                        32,
                      ),
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
                            AuthHeader(
                              title: AppLocalizations.of(context)!.appName,
                              subtitle: AppLocalizations.of(
                                context,
                              )!.authSubtitle,
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

                            AuthTextField(
                              key: _passwordFieldKey,
                              controller: _passwordController,
                              label: "Password",
                              label: AppLocalizations.of(context)!.email,
                              icon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  Validation.validateEmail(context, v),
                            ),
                            const SizedBox(height: 20),

                            // Password Field
                            AuthTextField(
                              key: _passwordFieldKey,
                              controller: _passwordController,
                              label: AppLocalizations.of(context)!.password,
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

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _showForgotPasswordDialog(context),
                                child: Text(
                                  "Forgot Password?",
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              validator: (v) =>
                                  Validation.validatePassword(context, v),
                            ),

                            const SizedBox(height: 24),
                            const SizedBox(height: 32),

                            // Login Button
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                return AuthActionButton(
                                  text: "Sign In",
                                  text: AppLocalizations.of(context)!.signIn,
                                  isLoading:
                                      state is AuthLoading &&
                                      state.source == AuthLoadingSource.email,
                                  onPressed: () {
                                    if (state is AuthLoading) {
                                      return;
                                    }
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
                                    AppLocalizations.of(context)!.orDivider,
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
                            Wrap(
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.newToAvenue,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.6),
                                  ),
                                ),
                                TextButton(
                                  onPressed: isLoading
                                      ? null
                                      : () => context.push('/register'),
                                  child: const Text(
                                    "Create Account",
                                  child: Text(
                                    AppLocalizations.of(context)!.createAccount,
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showForgotPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

        return AlertDialog(
          title: Text(
            "Reset Password",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter your email to receive an 8-digit OTP code.",
                  style: TextStyle(color: textColor.withOpacity(0.8)),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: controller,
                  label: "Email",
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validation.validateEmail,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: textColor.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<AuthCubit>().sendPasswordResetOtp(
                    controller.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmonPink,
                foregroundColor: Colors.white,
              ),
              child: const Text("Send Code"),
            ),
          ],
        );
      },
    );
  }

  void _showOtpVerificationDialog(BuildContext context, String email) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

        return AlertDialog(
          title: Text(
            "Verify OTP",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Enter the 8-digit code sent to $email",
                  style: TextStyle(color: textColor.withOpacity(0.8)),
                ),
                const SizedBox(height: 20),
                AuthTextField(
                  controller: controller,
                  label: "OTP Code",
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.length != 8) {
                      return "Enter a valid 8-digit code";
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: TextStyle(color: textColor.withOpacity(0.6)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  context.read<AuthCubit>().verifyPasswordResetOtp(
                    email,
                    controller.text.trim(),
                  );
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.salmonPink,
                foregroundColor: Colors.white,
              ),
              child: const Text("Verify"),
            ),
          ],
        );
      },
    );
  }

  void _showResetPasswordDialog(
    BuildContext context,
    String email,
    String otp,
  ) {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                "New Password",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Enter your new password and confirm it.",
                      style: TextStyle(color: textColor.withOpacity(0.8)),
                    ),
                    const SizedBox(height: 20),
                    AuthTextField(
                      controller: passwordController,
                      label: "New Password",
                      icon: Icons.lock_outline,
                      obscureText: obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: textColor.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                          () => obscurePassword = !obscurePassword,
                        ),
                      ),
                      validator: Validation.validatePassword,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: confirmController,
                      label: "Confirm Password",
                      icon: Icons.lock_reset_rounded,
                      obscureText: obscureConfirm,
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirm
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: textColor.withOpacity(0.6),
                          size: 20,
                        ),
                        onPressed: () => setDialogState(
                          () => obscureConfirm = !obscureConfirm,
                        ),
                      ),
                      validator: (value) => Validation.validateConfirmPassword(
                        value,
                        passwordController.text,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: textColor.withOpacity(0.6)),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      context.read<AuthCubit>().resetPassword(
                        passwordController.text.trim(),
                      );
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.salmonPink,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Reset Password"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
