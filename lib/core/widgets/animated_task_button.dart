import 'package:flutter/material.dart';
import '../../core/utils/constants.dart';

class AnimatedTaskButton extends StatefulWidget {
  final bool visible;
  final VoidCallback onTap;

  const AnimatedTaskButton({
    super.key,
    required this.visible,
    required this.onTap,
  });

  @override
  State<AnimatedTaskButton> createState() => _AnimatedTaskButtonState();
}

class _AnimatedTaskButtonState extends State<AnimatedTaskButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.visible ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.only(right: 30),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 150),
            scale: _isPressed ? 0.92 : 1.0,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.deepPurple,
                    AppColors.deepPurple.withOpacity(0.85),
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
                Icons.add_rounded,
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
