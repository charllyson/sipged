// lib/screens/modules/traffic/accidents/dashboard/widgets/accident_dashboard_map.dart

import 'dart:math' as math;

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

import 'package:sipged/_utils/theme/sipged_theme.dart';

import 'package:sipged/_widgets/map/map/map_change.dart';
import 'package:sipged/_widgets/map/pin/pin_aureola.dart';

class AccidentDashboardMap extends StatelessWidget {
  final LatLng center;

  final List<AccidentsData> accidents;
  final void Function(AccidentsData acc) onTapMarker;

  final List<Polygon<Map<String, dynamic>>> polygonsChanged;

  final List<String>? selectedRegionNames;
  final void Function(String? region)? onRegionTap;

  const AccidentDashboardMap({
    super.key,
    required this.center,
    required this.accidents,
    required this.onTapMarker,
    required this.polygonsChanged,
    this.selectedRegionNames,
    this.onRegionTap,
  });

  String _norm(String s) {
    return removeDiacritics(s)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toUpperCase();
  }

  Set<String> _normSet(List<String> values) {
    return values.map(_norm).where((e) => e.isNotEmpty).toSet();
  }

  String _polygonTitle(Polygon<Map<String, dynamic>> polygon) {
    final hit = polygon.hitValue;

    final value = hit?['title'] ??
        hit?['nome'] ??
        hit?['name'] ??
        hit?['NM_MUN'] ??
        hit?['processo'] ??
        polygon.label;

    return value?.toString().trim() ?? '';
  }

  String _severityOf(AccidentsData a) {
    final death = a.death ?? 0;

    if (death > 0) return 'GRAVE';

    final victims = a.scoresVictims ?? 0;

    if (victims >= 3) return 'GRAVE';
    if (victims >= 1) return 'MODERADO';

    return 'LEVE';
  }

  String _labelOf(AccidentsData a) {
    final t = AccidentsData.canonicalType(a.typeOfAccident);
    final clean = t.replaceAll('COLISÃO ', '').replaceAll('COM ', '').trim();

    if (clean.isEmpty) return '—';

    return clean.substring(0, math.min(2, clean.length)).toUpperCase();
  }

  (_Bounds? bounds, bool any) _boundsFromPolygons(
      List<Polygon<Map<String, dynamic>>> polys, {
        int sampleTarget = 90,
      }) {
    if (polys.isEmpty) return (null, false);

    double minLat = 999.0;
    double maxLat = -999.0;
    double minLng = 999.0;
    double maxLng = -999.0;

    bool any = false;

    for (final polygon in polys) {
      final pts = polygon.points;

      if (pts.isEmpty) continue;

      final step = (pts.length / sampleTarget).ceil().clamp(1, 999999);

      for (int i = 0; i < pts.length; i += step) {
        final ll = pts[i];
        any = true;

        if (ll.latitude < minLat) minLat = ll.latitude;
        if (ll.latitude > maxLat) maxLat = ll.latitude;
        if (ll.longitude < minLng) minLng = ll.longitude;
        if (ll.longitude > maxLng) maxLng = ll.longitude;
      }

      final holes = polygon.holePointsList ?? const <List<LatLng>>[];

      for (final hole in holes) {
        if (hole.isEmpty) continue;

        final holeStep = (hole.length / sampleTarget).ceil().clamp(1, 999999);

        for (int i = 0; i < hole.length; i += holeStep) {
          final ll = hole[i];
          any = true;

          if (ll.latitude < minLat) minLat = ll.latitude;
          if (ll.latitude > maxLat) maxLat = ll.latitude;
          if (ll.longitude < minLng) minLng = ll.longitude;
          if (ll.longitude > maxLng) maxLng = ll.longitude;
        }
      }
    }

    if (!any) return (null, false);

    return (
    _Bounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    ),
    true,
    );
  }

  _Bounds _padBounds(_Bounds b, {double factor = 0.12}) {
    final latSpan = (b.maxLat - b.minLat).abs();
    final lngSpan = (b.maxLng - b.minLng).abs();

    final padLat = math.max(latSpan * factor, 0.05);
    final padLng = math.max(lngSpan * factor, 0.05);

    return _Bounds(
      minLat: b.minLat - padLat,
      maxLat: b.maxLat + padLat,
      minLng: b.minLng - padLng,
      maxLng: b.maxLng + padLng,
    );
  }

  LatLng _centerOfBounds(_Bounds b) {
    return LatLng(
      (b.minLat + b.maxLat) / 2.0,
      (b.minLng + b.maxLng) / 2.0,
    );
  }

  double _latRad(double lat) {
    final s = math.sin(lat * math.pi / 180.0);
    final radX2 = math.log((1 + s) / (1 - s)) / 2.0;

    return math.max(math.min(radX2, math.pi), -math.pi) / 2.0;
  }

  double _zoomForBounds({
    required _Bounds b,
    required double mapWidthPx,
    required double mapHeightPx,
    double tileSize = 256.0,
    double paddingPx = 40.0,
  }) {
    final width = math.max(1.0, mapWidthPx - paddingPx * 2);
    final height = math.max(1.0, mapHeightPx - paddingPx * 2);

    final lngSpan = (b.maxLng - b.minLng).abs().clamp(1e-6, 360.0);

    final latRadSpan =
    (_latRad(b.maxLat) - _latRad(b.minLat)).abs().clamp(1e-6, math.pi);

    final zoomLng =
        math.log((width * 360.0) / (tileSize * lngSpan)) / math.ln2;

    final zoomLat =
        math.log((height * math.pi) / (tileSize * latRadSpan)) / math.ln2;

    return math.min(zoomLng, zoomLat);
  }

  List<LatLng> _geometryPointsFromPolygons(
      List<Polygon<Map<String, dynamic>>> polygons,
      ) {
    if (polygons.isEmpty) return const <LatLng>[];

    final points = <LatLng>[];

    for (final polygon in polygons) {
      points.addAll(polygon.points);

      final holes = polygon.holePointsList ?? const <List<LatLng>>[];

      for (final hole in holes) {
        points.addAll(hole);
      }
    }

    return points;
  }

  List<Polygon<Map<String, dynamic>>> _applyAccidentsStyle({
    required List<Polygon<Map<String, dynamic>>> polys,
    required Map<String, Color> cityColorsNorm,
    required List<String> selectedNames,
  }) {
    if (polys.isEmpty) return polys;

    final normalizedColors = <String, Color>{};

    for (final entry in cityColorsNorm.entries) {
      normalizedColors[_norm(entry.key)] = entry.value;
    }

    final citiesWithData = normalizedColors.keys.toSet();
    final selected = _normSet(selectedNames);

    const noDataBase = Color(0xFF000000);
    const noDataBorderBase = Color(0xFF000000);

    const noDataAlpha = 0.05;
    const noDataBorderAlpha = 0.12;

    const dataAlpha = 0.55;
    const selectedAlpha = 0.68;

    const dataBorderWidth = 1.7;
    const noDataBorderWidth = 0.8;
    const selectedBorderWidth = 2.6;

    return polys.map((polygon) {
      final name = _polygonTitle(polygon);
      final nameNorm = _norm(name);

      final hasData = citiesWithData.contains(nameNorm);
      final isSelected = selected.contains(nameNorm);

      final dataBase = normalizedColors[nameNorm] ?? const Color(0xFF5AA7FF);

      final fill = isSelected
          ? dataBase.withValues(alpha: selectedAlpha)
          : hasData
          ? dataBase.withValues(alpha: dataAlpha)
          : noDataBase.withValues(alpha: noDataAlpha);

      final border = isSelected
          ? Colors.black.withValues(alpha: 0.88)
          : hasData
          ? dataBase
          : noDataBorderBase.withValues(alpha: noDataBorderAlpha);

      final hit = Map<String, dynamic>.from(polygon.hitValue ?? {});

      hit['title'] = hit['title'] ?? name;
      hit['nome'] = hit['nome'] ?? name;
      hit['processo'] = hit['processo'] ?? name;

      return Polygon<Map<String, dynamic>>(
        points: polygon.points,
        holePointsList: polygon.holePointsList ?? const <List<LatLng>>[],
        color: fill,
        borderColor: border,
        borderStrokeWidth: isSelected
            ? selectedBorderWidth
            : hasData
            ? dataBorderWidth
            : noDataBorderWidth,
        label: polygon.label,
        labelStyle: polygon.labelStyle,
        rotateLabel: polygon.rotateLabel,
        labelPlacementCalculator: polygon.labelPlacementCalculator,
        hitValue: hit,
      );
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final cityColors = AccidentsData.calculateColorsFilteredCity(accidents);

    final selectedNames = selectedRegionNames ?? const <String>[];

    final styledPolys = _applyAccidentsStyle(
      polys: polygonsChanged,
      cityColorsNorm: cityColors,
      selectedNames: selectedNames,
    );

    final markers = accidents
        .where((e) => e.latLng != null)
        .take(140)
        .map((acc) {
      final sev = _severityOf(acc);
      final color = SipGedTheme.severityColor(sev);

      return Marker(
        point: acc.latLng!,
        width: 52,
        height: 52,
        alignment: Alignment.center,
        child: GestureDetector(
          onTap: () => onTapMarker(acc),
          child: PinAureola(
            color: color,
            label: _labelOf(acc),
          ),
        ),
      );
    }).toList(growable: false);

    return LayoutBuilder(
      builder: (context, c) {
        final size = c.biggest;
        final w = size.width.isFinite ? size.width : 1000.0;
        final h = size.height.isFinite ? size.height : 700.0;

        final (rawBounds, any) = _boundsFromPolygons(styledPolys);

        LatLng effectiveCenter = center;
        double effectiveZoom = 10.5;

        if (any && rawBounds != null) {
          final padded = _padBounds(rawBounds, factor: 0.12);

          effectiveCenter = _centerOfBounds(padded);

          final z = _zoomForBounds(
            b: padded,
            mapWidthPx: w,
            mapHeightPx: h,
            paddingPx: 56,
          );

          effectiveZoom = z.clamp(5.0, 19.0);
        }

        final geometryPoints = _geometryPointsFromPolygons(styledPolys);

        return MapChange(
          key: ValueKey(
            'transitMap_${styledPolys.length}_${accidents.length}_${selectedNames.join('|')}',
          ),

          features: const <FeatureData>[],
          layersById: const <String, LayerData>{},
          orderedActiveLayerIds: const <String>[],

          selectedFeatureKey: null,
          loading: false,

          visualDataSignature: Object.hash(
            'accident-dashboard-map',
            styledPolys.length,
            accidents.length,
            selectedNames.join('|'),
          ),

          initialCenter: effectiveCenter,
          initialZoom: effectiveZoom,
          minZoom: 5,
          maxZoom: 19,

          showSearch: false,
          showControls: true,

          initialGeometryPoints:
          geometryPoints.isNotEmpty ? geometryPoints : <LatLng>[effectiveCenter],
          fitInitialGeometryOnce: geometryPoints.isNotEmpty,

          externalPolygons: styledPolys,
          externalMarkers: markers,

          onControllerReady: (_) {},

          onCameraChanged: (_, _) {},

          onFeatureTap: (_) {},

          onExternalPolygonTap: (polygon) {
            if (onRegionTap == null) return;

            if (polygon == null) {
              onRegionTap?.call(null);
              return;
            }

            final region = _polygonTitle(polygon);

            if (region.trim().isEmpty) {
              onRegionTap?.call(null);
              return;
            }

            onRegionTap?.call(region);
          },
        );
      },
    );
  }
}

class _Bounds {
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  const _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}