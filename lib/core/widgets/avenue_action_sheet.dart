import 'package:flutter/material.dart';

class AvenueAction {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;
  final bool isDestructive;

  const AvenueAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.color,
    this.isDestructive = false,
  });
}

class AvenueActionSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final List<AvenueAction> actions;

  const AvenueActionSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
          ],
          if (subtitle != null) ...[
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (title != null || subtitle != null) const Divider(height: 32),

          // Actions
          ...actions.map((action) => _buildActionRow(context, action)),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, AvenueAction action) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = action.color ?? (action.isDestructive ? Colors.redAccent : theme.primaryColor);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.pop(context);
          action.onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isDark ? 0.12 : 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(action.icon, color: color, size: 24),
              const SizedBox(width: 16),
              Text(
                action.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: color.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
