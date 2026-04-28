import 'package:flutter/material.dart';

class BalloonHeader extends StatelessWidget {
  const BalloonHeader({
    super.key,
    this.title,
    this.icon,
    this.iconColor = const Color(0xFF1B2031),
    this.titleColor = const Color(0xFF1B2031),
    this.height = 40,
    this.padding = const EdgeInsets.only(left: 14, right: 8),
    this.actionLabel,
    this.showAction = false,
    this.onAction,
  });

  final String? title;
  final IconData? icon;

  final Color iconColor;
  final Color titleColor;

  final double height;
  final EdgeInsetsGeometry padding;

  final String? actionLabel;
  final bool showAction;
  final VoidCallback? onAction;

  bool get _hasAction {
    final cleanActionLabel = (actionLabel ?? '').trim();

    return showAction && cleanActionLabel.isNotEmpty && onAction != null;
  }

  @override
  Widget build(BuildContext context) {
    final cleanTitle = (title ?? '').trim();
    final cleanActionLabel = (actionLabel ?? '').trim();

    return Container(
      height: height,
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
            if (cleanTitle.isNotEmpty || _hasAction)
              const SizedBox(width: 8),
          ],
          if (cleanTitle.isNotEmpty)
            Expanded(
              child: Text(
                cleanTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                ),
              ),
            )
          else
            const Spacer(),
          if (_hasAction)
            TextButton(
              onPressed: onAction,
              child: Text(
                cleanActionLabel,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}