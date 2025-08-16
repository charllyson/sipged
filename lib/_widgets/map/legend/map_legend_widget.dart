import 'package:flutter/material.dart';

class MapLegendLayer extends StatelessWidget {
  final Map<String, Color> regionColors;

  const MapLegendLayer({
    super.key,
    this.regionColors = const {},
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.white70,
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        children: regionColors.entries.map((entry) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 14, height: 14, color: entry.value),
              const SizedBox(width: 4),
              Text(entry.key, style: const TextStyle(fontSize: 10)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
