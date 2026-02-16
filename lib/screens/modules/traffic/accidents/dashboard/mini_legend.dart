import 'package:flutter/material.dart';
import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:sipged/screens/modules/traffic/accidents/dashboard/legend_item.dart';


class MiniLegend extends StatelessWidget {
  final List<LegendItem> items;
  const MiniLegend({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? Colors.black.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.85),
        border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _legendRow(theme, 'Leve', SipGedTheme.severityColor('LEVE')),
          const SizedBox(height: 6),
          _legendRow(theme, 'Moderado', SipGedTheme.severityColor('MODERADO')),
          const SizedBox(height: 6),
          _legendRow(theme, 'Grave', SipGedTheme.severityColor('GRAVE')),
        ],
      ),
    );
  }

  Widget _legendRow(ThemeData theme, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}