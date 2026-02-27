import 'package:flutter/material.dart';
import '../../../../core/utils/constants.dart';
import '../../../../core/widgets/offline_banner.dart';

/// A specialized action button for authentication screens with offline-aware
/// shake animation.
///
/// When pressed while offline:
/// - Plays a 300ms shake animation
/// - Does NOT trigger onPressed callback
/// - Does NOT show snackbar
///
/// When pressed while online:
/// - Triggers onPressed normally
class AuthActionButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AuthActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AuthActionButton> createState() => _AuthActionButtonState();
}

class _AuthActionButtonState extends State<AuthActionButton>
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

  void _handlePress() {
    // Check global connectivity state
    if (GlobalConnectivity.offline) {
      // Shake but don't trigger action
      _shakeController.forward(from: 0.0);
      return;
    }

    // Normal press behavior
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeAnimation.value, 0),
          child: child,
        );
      },
      child: ElevatedButton(
        onPressed: widget.isLoading ? null : _handlePress,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? AppColors.creamTan,
          foregroundColor: widget.foregroundColor ?? AppColors.deepPurple,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: widget.isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.foregroundColor ?? AppColors.deepPurple,
                  ),
                ),
              )
            : Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}
