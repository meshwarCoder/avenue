import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../../../../core/widgets/offline_banner.dart';

class SocialLoginRow extends StatelessWidget {
  const SocialLoginRow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google (Functional)
            _SocialButton(
              onTap: isLoading
                  ? null
                  : () {
                      context.read<AuthCubit>().signInWithGoogle();
                    },
              assetPath: "assets/icon/google.svg",
              isLoading:
                  state is AuthLoading &&
                  state.source == AuthLoadingSource.google,
            ),

            const SizedBox(width: 20),

            // Facebook (Functional)
            _SocialButton(
              onTap: isLoading
                  ? null
                  : () {
                      context.read<AuthCubit>().signInWithFacebook();
                    },
              assetPath: "assets/icon/facebook.svg",
              isLoading:
                  state is AuthLoading &&
                  state.source == AuthLoadingSource.facebook,
            ),
          ],
        );
      },
    );
  }
}

/// Individual social button with offline-aware shake animation.
class _SocialButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String assetPath;
  final bool isLoading;

  const _SocialButton({
    required this.onTap,
    required this.assetPath,
    this.isLoading = false,
  });

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: -8.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -8.0,
          end: 8.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 8.0,
          end: -6.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -6.0,
          end: 6.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 2,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 6.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 1,
      ),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Check global connectivity state
    if (GlobalConnectivity.offline) {
      // Shake but don't trigger action
      _shakeController.forward(from: 0.0);
      return;
    }

    // Normal tap behavior
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: InkWell(
        onTap: widget.isLoading ? null : _handleTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 60,
          height: 60,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : SvgPicture.asset(widget.assetPath, width: 32, height: 32),
        ),
      ),
    );
  }
}
