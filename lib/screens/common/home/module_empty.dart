import 'package:flutter/material.dart';
class ModuleEmpty extends StatelessWidget {
  const ModuleEmpty({super.key,
    required this.isDark,
  });

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark ? Colors.white : Colors.black87;
    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : Colors.black54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_outline,
            size: 38,
            color: isDark
                ? Colors.white.withValues(alpha: 0.70)
                : Colors.black54,
          ),
          const SizedBox(height: 12),
          Text(
            'Nenhum módulo disponível',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Peça a um administrador para habilitar seus acessos.\nVocê verá aqui apenas os módulos permitidos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}