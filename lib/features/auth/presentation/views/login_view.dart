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
                    AppLocalizations.of(context)!.passwordResetSuccess,
                  );
                }
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background Decorative Elements
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
                            AuthHeader(
                              title: AppLocalizations.of(context)!.appName,
                              subtitle: AppLocalizations.of(
                                context,
                              )!.authSubtitle,
                            ),
                            const SizedBox(height: 48),

                            // Email or Username Field
                            AuthTextField(
                              key: _emailFieldKey,
                              controller: _emailController,
                              label: AppLocalizations.of(context)!.emailOrUsername,
                              icon: Icons.person_outline_rounded,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return AppLocalizations.of(context)!.errEmailRequired;
                                }
                                return null;
                              },
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
                              validator: (v) =>
                                  Validation.validatePassword(context, v),
                            ),

                            // Forgot Password link
                            Align(
                              alignment: AlignmentDirectional.centerEnd,
                              child: TextButton(
                                onPressed: isLoading
                                    ? null
                                    : () => _showForgotPasswordDialog(context),
                                child: Text(
                                  AppLocalizations.of(context)!.forgotPassword,
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Login Button
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                return AuthActionButton(
                                  text: AppLocalizations.of(context)!.signIn,
                                  isLoading:
                                      state is AuthLoading &&
                                      state.source == AuthLoadingSource.email,
                                  onPressed: () {
                                    if (state is AuthLoading) return;
                                    if (_formKey.currentState!.validate()) {
                                      context.read<AuthCubit>().signIn(
                                        identifier: _emailController.text.trim(),
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

                            // Sign Up link
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
                                  child: Text(
                                    AppLocalizations.of(context)!.createAccount,
                                    style: const TextStyle(
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

  void _showForgotPasswordDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

        return BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.resetPassword,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.resetPasswordHint,
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 20),
                  AuthTextField(
                    controller: controller,
                    label: AppLocalizations.of(context)!.email,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => Validation.validateEmail(context, v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: textColor.withOpacity(0.6)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    context.read<AuthCubit>().sendPasswordResetOtp(
                      controller.text.trim(),
                    );
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmonPink,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.sendCode),
              ),
            ],
          ),
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
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

        return BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.verifyOtp,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.otpSentTo(email),
                    style: TextStyle(color: textColor.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 20),
                  AuthTextField(
                    controller: controller,
                    label: AppLocalizations.of(context)!.otpCode,
                    icon: Icons.pin_outlined,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.length != 6) {
                        return AppLocalizations.of(context)!.otpInvalid;
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  AppLocalizations.of(context)!.cancel,
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
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.salmonPink,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context)!.verify),
              ),
            ],
          ),
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
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : theme.colorScheme.onSurface;

        return BlocProvider.value(
          value: context.read<AuthCubit>(),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  AppLocalizations.of(this.context)!.newPassword,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(this.context)!.newPasswordHint,
                        style: TextStyle(color: textColor.withOpacity(0.8)),
                      ),
                      const SizedBox(height: 20),
                      AuthTextField(
                        controller: passwordController,
                        label: AppLocalizations.of(this.context)!.newPassword,
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
                        validator: (v) =>
                            Validation.validatePassword(this.context, v),
                      ),
                      const SizedBox(height: 16),
                      AuthTextField(
                        controller: confirmController,
                        label: AppLocalizations.of(
                          this.context,
                        )!.confirmPassword,
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
                        validator: (value) =>
                            Validation.validateConfirmPassword(
                              this.context,
                              value,
                              passwordController.text,
                            ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text(
                      AppLocalizations.of(this.context)!.cancel,
                      style: TextStyle(color: textColor.withOpacity(0.6)),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        this.context.read<AuthCubit>().resetPassword(
                          passwordController.text.trim(),
                        );
                        Navigator.pop(dialogContext);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.salmonPink,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      AppLocalizations.of(this.context)!.resetPassword,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
