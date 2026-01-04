import 'package:flutter/material.dart';

class ProgressImportDialog extends StatelessWidget {
  final int total;
  final int current;

  const ProgressImportDialog({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Evita divisão por zero e valores fora do range [0,1]
    final double? progress = total <= 0
        ? null
        : (current / total).clamp(0.0, 1.0);

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 360,
          minWidth: 280,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Importando dados...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress, // null => indeterminado
                minHeight: 8,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  total > 0
                      ? 'Salvando $current de $total registros...'
                      : 'Preparando importação...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
