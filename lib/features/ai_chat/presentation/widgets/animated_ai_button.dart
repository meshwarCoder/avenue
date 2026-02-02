import 'package:flutter/material.dart';
import 'package:line/core/utils/constants.dart';

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

class _AnimatedAIChatButtonState extends State<AnimatedAIChatButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: widget.visible ? 1.0 : 0.0,
      child: Padding(
        padding: const EdgeInsets.only(right: 24),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: GestureDetector(
            onTap: widget.onTap,
            child: Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    AppColors.salmonPink,
                    Color(0xFFFF85A1), // Slightly lighter pink
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.salmonPink.withOpacity(0.4),
                    blurRadius: 18,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
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
