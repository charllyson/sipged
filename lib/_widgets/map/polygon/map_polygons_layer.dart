// lib/_widgets/map/flutter_map/layers/map_polygons_layer.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed.dart';

class MapPolygonsLayer extends StatelessWidget {
  final MapController mapController;
  final List<PolygonChanged> polygons;

  final ValueListenable<Set<String>> selectedRegionsVN;
  final Map<String, Color>? polygonChangeColors;

  final String Function(String) norm;

  const MapPolygonsLayer({
    super.key,
    required this.mapController,
    required this.polygons,
    required this.selectedRegionsVN,
    required this.polygonChangeColors,
    required this.norm,
  });

  Color _resolveRegionColor(PolygonChanged entry) {
    final map = polygonChangeColors;
    if (map == null || map.isEmpty) return entry.normalFillColor;

    final t = entry.title;
    final kN = norm(t);
    return map[kN] ?? map[t] ?? map[t.toUpperCase()] ?? entry.normalFillColor;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<String>>(
      valueListenable: selectedRegionsVN,
      builder: (_, selected, __) {
        final map = polygonChangeColors;
        final hasExternalColors = map != null && map.isNotEmpty;

        final z = mapController.camera.zoom;
        final zoomFactor = (z / 12.0).clamp(0.85, 1.9);

        // OUTLINE por baixo para separar polígonos
        const outlineColor = Color(0xFF9CA3AF);
        const outlineOpacityNormal = 0.85;
        const outlineOpacitySelected = 0.95;

        final rendered = polygons.expand((entry) {
          final titleNorm = norm(entry.title);
          final isSelected = selected.contains(titleNorm);

          late final Color fillColor;
          late final Color borderColor;
          late final double borderWidth;

          if (hasExternalColors) {
            final base = _resolveRegionColor(entry);

            final fillOpacity = isSelected ? 0.40 : 0.18;
            final strokeOpacity = isSelected ? 0.98 : 0.75;

            fillColor = base.withValues(alpha: fillOpacity);
            borderColor = base.withValues(alpha: strokeOpacity);

            borderWidth = isSelected ? entry.selectedBorderWidth : entry.normalBorderWidth;
          } else {
            fillColor = isSelected ? entry.selectedFillColor : entry.normalFillColor;
            borderColor = isSelected ? entry.selectedBorderColor : entry.normalBorderColor;
            borderWidth = isSelected ? entry.selectedBorderWidth : entry.normalBorderWidth;
          }

          final outlineWidth = (borderWidth + 1) * zoomFactor;
          final realBorderWidth = borderWidth * zoomFactor;

          final outline = Polygon(
            points: entry.polygon.points,
            color: Colors.transparent,
            borderColor: outlineColor.withValues(
              alpha: isSelected ? outlineOpacitySelected : outlineOpacityNormal,
            ),
            borderStrokeWidth: outlineWidth,
          );

          final top = Polygon(
            points: entry.polygon.points,
            color: fillColor,
            borderColor: borderColor,
            borderStrokeWidth: realBorderWidth,
          );

          return [outline, top];
        }).toList(growable: false);

        return PolygonLayer(polygons: rendered);
      },
    );
  }
}
