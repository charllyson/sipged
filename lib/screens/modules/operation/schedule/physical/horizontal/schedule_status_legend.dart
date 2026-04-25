// lib/screens/modules/operation/schedule/road/schedule_status_legend.dart
import 'package:flutter/material.dart';

class ScheduleStatusLegend extends StatelessWidget {
  final Color color;
  final String label;
  final double value;
  final double percent;

  const ScheduleStatusLegend({
    super.key,
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontSize: 12, // 👈 bem grande
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontSize: 12, // 👈 idem
            ),
          ),
        ],
      ),
    );
  }
}
