import 'package:flutter/material.dart';

class BaseAvenueCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;
  final double? height;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final double borderRadius;
  final double accentBarWidth;

  const BaseAvenueCard({
    super.key,
    required this.child,
    required this.accentColor,
    this.height,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor,
    this.borderRadius = 20,
    this.accentBarWidth = 6,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? theme.cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: accentBarWidth,
                  color: accentColor,
                ),
                Expanded(
                  child: Padding(
                    padding: padding,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
