import 'package:flutter/material.dart';

class SchedulePercent extends StatelessWidget {
  const SchedulePercent({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
    this.compactBreakpoint = 720.0,
  });

  final Color color;
  final String label;
  final double value;
  final double percent;

  /// Abaixo dessa largura, exibe somente:
  /// container de cor + percentual.
  final double compactBreakpoint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;

    final isCompact = screenWidth < compactBreakpoint;
    final safePercent = percent.isFinite ? percent : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 3.0 : 4.0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: isCompact ? 13.0 : 16.0,
            height: isCompact ? 13.0 : 16.0,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          SizedBox(width: isCompact ? 5.0 : 8.0),
          if (!isCompact) ...<Widget>[
            Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: false,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8.0),
          ],
          Text(
            '${safePercent.toStringAsFixed(1)}%',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: isCompact ? 13.0 : 16.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}