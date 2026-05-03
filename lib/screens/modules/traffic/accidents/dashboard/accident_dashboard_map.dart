// lib/screens/modules/traffic/accidents/dashboard/widgets/accident_dashboard_map.dart

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';
import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

import 'package:sipged/_widgets/map/map/map_change.dart';

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
        rotateLabel: false,
        labelPlacementCalculator: null,

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

      externalPolygons: styledPolys,
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
  }
}