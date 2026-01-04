// lib/screens/sectors/actives/roads/road_map_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_blocs/actives/roads/active_road_style.dart';

import 'package:siged/_blocs/actives/roads/active_roads_data.dart';
import 'package:siged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';

class RoadDetailsMapSection extends StatefulWidget {
  final ActiveRoadsData? road;
  const RoadDetailsMapSection({super.key, this.road});

  @override
  State<RoadDetailsMapSection> createState() =>
      _RoadDetailsMapSectionState();
}

class _RoadDetailsMapSectionState extends State<RoadDetailsMapSection> {
  double _currentZoom = 12.0;
  double _centerLat = -9.65;
  MapController? _mapController;

  // ============================================================
  // 🔍 CALCULA ZOOM IDEAL PARA UMA POLYLINE
  // ============================================================
  double _computeIdealZoom(List<LatLng> pts) {
    if (pts.isEmpty) return 15.0;

    double minLat = pts.first.latitude;
    double maxLat = pts.first.latitude;
    double minLng = pts.first.longitude;
    double maxLng = pts.first.longitude;

    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final latDelta = (maxLat - minLat).abs();
    final lngDelta = (maxLng - minLng).abs();
    final delta = latDelta > lngDelta ? latDelta : lngDelta;

    if (delta < 0.002) return 17.0; // curtíssimo
    if (delta < 0.01) return 16.0;  // muito curto
    if (delta < 0.05) return 15.0;  // curto
    if (delta < 0.15) return 14.0;  // médio
    if (delta < 0.50) return 13.0;  // médio-longo
    if (delta < 1.00) return 12.0;  // longo
    return 11.0;                    // muito longo
  }

  // ============================================================
  // 🔧 BUILD POLYLINE DA RODOVIA COM ESTILO
  // ============================================================
  List<TappableChangedPolyline> _buildStyledPolylinesForRoad() {
    final road = widget.road;
    if (road == null) return const [];
    final pts = road.points;
    if (pts == null || pts.isEmpty) return const [];

    final code = (road.stateSurface ?? road.surface ?? road.state ?? '')
        .toUpperCase()
        .trim();

    final isDupla = ActiveRoadsData.isDupla(code);
    final isDash = ActiveRoadsData.isTracejada(code);

    final baseColor = ActiveRoadsStyle.colorForSurface(code);

    final lanePx = ActiveRoadsData.laneWidthForZoom(_currentZoom);
    final sepPx = ActiveRoadsData.laneSeparationPxForZoom(_currentZoom);
    final degPerPx =
    ActiveRoadsData.degreesPerPixel(_centerLat, _currentZoom);
    final deltaDeg = sepPx * degPerPx;

    final List<TappableChangedPolyline> lines = [];

    void add(List<LatLng> ptsLine) {
      lines.add(
        TappableChangedPolyline(
          points: ptsLine,
          tag: road.id ?? '',
          color: baseColor,
          defaultColor: baseColor,
          strokeWidth: lanePx,
          isDotted: isDash,
        ),
      );
    }

    if (isDupla) {
      add(
        ActiveRoadsData.deslocarPontos(pts,
            deslocamentoOrtogonal: -deltaDeg),
      );
      add(
        ActiveRoadsData.deslocarPontos(pts,
            deslocamentoOrtogonal: deltaDeg),
      );
    } else {
      add(pts);
    }

    return lines;
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.road?.points ?? const [];

    // ==========
    // 🎯 NOVO: calcula zoom ideal automaticamente
    // ==========
    final double idealZoom = _computeIdealZoom(points);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: MapInteractivePage<ActiveRoadsData>(
          key: const ValueKey('road-details-map'),

          // 🔥 AQUI ESTÁ O ZOOM AUTOMÁTICO 🔥
          initialZoom: idealZoom,

          activeMap: true,
          showLegend: false,
          showSearch: true,

          initialGeometryPoints: points,

          tappablePolylines: _buildStyledPolylinesForRoad(),

          onControllerReady: (c) {
            _mapController = c;
          },

          onCameraChanged: (z, center) {
            setState(() {
              _currentZoom = z;
              _centerLat = center.latitude;
            });
          },
        ),
      ),
    );
  }
}
