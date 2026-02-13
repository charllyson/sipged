import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? details;
  final double? progress;

  final Color glassFill;
  final Color glassBorder;
  final List<BoxShadow> shadows;

  const GlassCard({super.key,
    required this.icon,
    required this.message,
    required this.details,
    required this.progress,
    required this.glassFill,
    required this.glassBorder,
    required this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final indicator = (progress == null)
        ? const SizedBox(
      width: 22, // menor, mais delicado
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 2.5),
    )
        : SizedBox(
      width: 180,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(value: progress!.clamp(0.0, 1.0)),
          ),
          const SizedBox(height: 8),
          Text('${(progress! * 100).clamp(0, 100).toStringAsFixed(0)}%',
              style: theme.textTheme.labelMedium),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Container(
        decoration: BoxDecoration(
          color: glassFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: glassBorder),
          boxShadow: shadows,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium!,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (details != null) ...[
                const SizedBox(height: 6),
                Text(
                  details!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              indicator,
            ],
          ),
        ),
      ),
    );
  }
}