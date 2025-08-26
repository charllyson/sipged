import 'package:flutter/material.dart';

class MapLegendLayer extends StatelessWidget {
  final Map<String, Color> regionColors;

  const MapLegendLayer({
    super.key,
    this.regionColors = const {},
  });

  @override
  Widget build(BuildContext context) {
    // Não pode ocupar largura infinita dentro de Positioned.
    return IgnorePointer(
      ignoring: true, // legenda apenas visual
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 3,
          color: Colors.white70,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 6,
              children: regionColors.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 14, height: 14, color: entry.value),
                    const SizedBox(width: 6),
                    Text(entry.key, style: const TextStyle(fontSize: 11)),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
