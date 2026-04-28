import 'package:flutter/material.dart';

class BalloonEmpty extends StatelessWidget {
  const BalloonEmpty({
    super.key,
    this.icon = Icons.notifications_off_outlined,
    this.message = 'Nenhum item encontrado.',
    this.iconColor = Colors.black38,
    this.textColor = Colors.black54,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
  });

  /// Pode ser null para não exibir ícone.
  final IconData? icon;

  final String message;

  final Color iconColor;
  final Color textColor;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final cleanMessage = message.trim();

    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              color: iconColor,
              size: 32,
            ),
          if (icon != null && cleanMessage.isNotEmpty)
            const SizedBox(height: 8),
          if (cleanMessage.isNotEmpty)
            Text(
              cleanMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
              ),
            ),
        ],
      ),
    );
  }
}