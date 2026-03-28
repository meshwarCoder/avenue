import 'package:flutter/material.dart';
import '../../data/models/inbox_item_model.dart';
import 'package:avenue/core/utils/constants.dart';
import 'package:avenue/core/widgets/base_avenue_card.dart';

class InboxItemCard extends StatelessWidget {
  final InboxItemModel item;
  final VoidCallback? onTap;

  const InboxItemCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getItemColor(item.type);

    return BaseAvenueCard(
      onTap: onTap,
      accentColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Badge
          _buildBadge(context, item.type.displayName, color),
          const SizedBox(height: 8),

          // Title
          Text(
            item.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Content (if available)
          if (item.content != null && item.content!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              item.content!,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // Deadline (if available)
          if (item.deadline != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  "Deadline: ${_formatDate(item.deadline!)}",
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  Color _getItemColor(InboxItemType type) {
    switch (type) {
      case InboxItemType.task:
        return AppColors.deepPurple;
      case InboxItemType.idea:
        return Colors.orange;
      case InboxItemType.note:
        return Colors.blue;
      case InboxItemType.brainDump:
        return Colors.teal;
    }
  }
}
