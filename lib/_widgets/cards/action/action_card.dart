import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/action/action_item.dart';
import 'package:sipged/_widgets/cards/basic/basic_card.dart';
import 'package:sipged/_widgets/cards/glass/glass_card.dart';

class ActionCard extends StatelessWidget {
  const ActionCard({
    super.key,
    required this.item,
    required this.onTap,
  });

  final ActionItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return BasicCard(
      onTap: onTap,
      isDark: false,
      child: Row(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, size: 28, color: item.color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.blueGrey.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.blueGrey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}