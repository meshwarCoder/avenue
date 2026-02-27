import 'dart:math';
import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
  });

  @override
  State<AuthTextField> createState() => AuthTextFieldState();
}

class AuthTextFieldState extends State<AuthTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void shakeIfInvalid() {
    if (widget.validator != null) {
      final error = widget.validator!(widget.controller.text);
      if (error != null) {
        _animationController.forward(from: 0.0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final sineValue = sin(_animationController.value * 4 * pi);
        final amplitude = 8.0 * (1 - _animationController.value);
        return Transform.translate(
          offset: Offset(sineValue * amplitude, 0),
          child: child,
        );
      },
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        style: TextStyle(color: theme.colorScheme.onSurface),
        validator: widget.validator,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          prefixIcon: Icon(
            widget.icon,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
            size: 22,
          ),
          suffixIcon: widget.suffixIcon,
          filled: true,
          fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: theme.colorScheme.primary,
              width: 1.5,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
          ),
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
