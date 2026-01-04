// lib/screens/actives/oaes/network/panel_header.dart
import 'package:flutter/material.dart';

class PanelHeader extends StatelessWidget {
  const PanelHeader({
    super.key,
    this.title,
    this.onClose,
  });

  final String? title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title ?? 'Detalhes',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Fechar',
            icon: const Icon(Icons.close_rounded),
            onPressed: onClose,
          ),
        ],
      ),
    );
  }
}
