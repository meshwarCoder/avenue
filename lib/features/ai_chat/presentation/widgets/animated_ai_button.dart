import 'package:flutter/material.dart';
import 'package:avenue/core/utils/constants.dart';

class AnimatedAIChatButton extends StatefulWidget {
  final bool visible;
  final VoidCallback onTap;

  const AnimatedAIChatButton({
    super.key,
    required this.visible,
    required this.onTap,
  });

  @override
  State<AnimatedAIChatButton> createState() => _AnimatedAIChatButtonState();
}

class _AnimatedAIChatButtonState extends State<AnimatedAIChatButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.visible ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _isPressed ? 0.92 : 1.0,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.salmonPink,
                    AppColors.salmonPink.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
