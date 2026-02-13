// lib/_widgets/menu/tab/tab_blocked.dart
import 'package:flutter/material.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';

class TabBlocked extends StatelessWidget {
  final String message;

  /// Título opcional (ex.: "Etapa indisponível")
  final String? title;

  /// Ícone exibido acima do título
  final IconData icon;

  const TabBlocked({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.lock_outline,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: SipGedTheme.primaryColor,
              ),
              const SizedBox(height: 12),
              Text(
                title ?? 'Acesso bloqueado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: SipGedTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
