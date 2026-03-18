import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed_data.dart';

class PolygonChangedLayer extends StatelessWidget {
  final MapController mapController;
  final List<PolygonChangedData> polygons;
  final ValueListenable<Set<String>> selectedRegionsVN;
  final Map<String, Color>? polygonChangeColors;
  final String Function(String) norm;

  const PolygonChangedLayer({
    super.key,
    required this.mapController,
    required this.polygons,
    required this.selectedRegionsVN,
    required this.polygonChangeColors,
    required this.norm,
  });

  Color _resolveRegionColor(PolygonChangedData entry) {
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
      builder: (_, selected, _) {
        final map = polygonChangeColors;
        final hasExternalColors = map != null && map.isNotEmpty;

        final z = mapController.camera.zoom;
        final zoomFactor = (z / 12.0).clamp(0.85, 1.9);

        const outlineColor = Color(0xFF9CA3AF);
        const outlineOpacityNormal = 0.85;
        const outlineOpacitySelected = 0.95;

        final rendered = <Polygon>[];

        for (final entry in polygons) {
          final titleNorm = norm(entry.title);
          final isSelected = selected.contains(titleNorm);

          late final Color fillColor;
          late final Color borderColor;
          late final double borderWidth;

          if (hasExternalColors) {
            final base = _resolveRegionColor(entry);

            fillColor = base.withValues(alpha: isSelected ? 0.40 : 0.18);
            borderColor = base.withValues(alpha: isSelected ? 0.98 : 0.75);
            borderWidth =
            isSelected ? entry.selectedBorderWidth : entry.normalBorderWidth;
          } else {
            fillColor =
            isSelected ? entry.selectedFillColor : entry.normalFillColor;
            borderColor =
            isSelected ? entry.selectedBorderColor : entry.normalBorderColor;
            borderWidth =
            isSelected ? entry.selectedBorderWidth : entry.normalBorderWidth;
          }

          final outlineWidth = (borderWidth + 1) * zoomFactor;
          final realBorderWidth = borderWidth * zoomFactor;

          rendered.add(
            Polygon(
              points: entry.polygon.points,
              color: Colors.transparent,
              borderColor: outlineColor.withValues(
                alpha: isSelected ? outlineOpacitySelected : outlineOpacityNormal,
              ),
              borderStrokeWidth: outlineWidth,
            ),
          );

          rendered.add(
            Polygon(
              points: entry.polygon.points,
              color: fillColor,
              borderColor: borderColor,
              borderStrokeWidth: realBorderWidth,
            ),
          );
        }

        return RepaintBoundary(
          child: PolygonLayer(polygons: rendered),
        );
      },
    );
  }
}