import 'package:flutter/material.dart';
import 'package:sipged/_widgets/cards/glass/glass_container.dart';

class GlassProgressCard extends StatelessWidget {
  const GlassProgressCard({
    super.key,
    required this.icon,
    required this.message,
    this.details,
    this.progress,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.gradient,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.blurSigmaX = 10,
    this.blurSigmaY = 10,
  });

  final IconData icon;
  final String message;
  final String? details;
  final double? progress;

  final double? width;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;
  final BorderRadius borderRadius;
  final double blurSigmaX;
  final double blurSigmaY;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final normalizedProgress = progress == null
        ? null
        : progress!.clamp(0.0, 1.0);

    final Widget indicator = normalizedProgress == null
        ? const SizedBox(
      width: 22,
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
            child: LinearProgressIndicator(
              value: normalizedProgress,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(normalizedProgress * 100).toStringAsFixed(0)}%',
            style: theme.textTheme.labelMedium,
          ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: width ?? 420,
      ),
      child: GlassContainer(
        padding: padding,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        boxShadow: boxShadow,
        gradient: gradient,
        blurSigmaX: blurSigmaX,
        blurSigmaY: blurSigmaY,
        child: DefaultTextStyle(
          style: theme.textTheme.bodyMedium ?? const TextStyle(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (details != null && details!.trim().isNotEmpty) ...[
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