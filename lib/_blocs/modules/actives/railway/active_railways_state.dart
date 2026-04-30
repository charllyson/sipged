// lib/_blocs/modules/actives/railway/active_railways_state.dart
import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/railway/active_railway_data.dart';
import 'package:sipged/_blocs/modules/actives/railway/active_railways_style.dart';
import 'package:sipged/_utils/geometry/sipged_poly_simplify.dart';
import 'package:sipged/screens/modules/actives/railways/network/railway_ties.dart';

enum ActiveRailwaysLoadStatus { idle, loading, success, failure }

class ActiveRailwaysState extends Equatable {
  static const _unset = Object();

  static final SipGedPolyline _simplifier = SipGedPolyline(
    maxCacheEntries: 120,
    metersPerPixelFn: RailwayTies.metersPerPixel,
  );

  final bool initialized;
  final ActiveRailwaysLoadStatus loadStatus;
  final String? error;
  final List<ActiveRailwayData> all;

  final String? selectedPolylineId;

  final int? selectedPieIndexFilter;
  final String? selectedRegionFilter;
  final String? selectedStatusFilter;

  final bool savingOrImporting;

  /// Zoom atual do mapa.
  final double mapZoom;

  /// Labels de região vindos do setup.
  final List<String> regionLabels;

  const ActiveRailwaysState({
    this.initialized = false,
    this.loadStatus = ActiveRailwaysLoadStatus.idle,
    this.error,
    this.all = const [],
    this.selectedPolylineId,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,
    this.selectedStatusFilter,
    this.savingOrImporting = false,
    this.mapZoom = 12.0,
    this.regionLabels = const [],
  });

  ActiveRailwaysState copyWith({
    bool? initialized,
    ActiveRailwaysLoadStatus? loadStatus,
    String? error,
    List<ActiveRailwayData>? all,
    Object? selectedPolylineId = _unset,
    Object? selectedPieIndexFilter = _unset,
    Object? selectedRegionFilter = _unset,
    Object? selectedStatusFilter = _unset,
    bool? savingOrImporting,
    double? mapZoom,
    List<String>? regionLabels,
  }) {
    return ActiveRailwaysState(
      initialized: initialized ?? this.initialized,
      loadStatus: loadStatus ?? this.loadStatus,
      error: error,
      all: all ?? this.all,
      selectedPolylineId: identical(selectedPolylineId, _unset)
          ? this.selectedPolylineId
          : selectedPolylineId as String?,
      selectedPieIndexFilter: identical(selectedPieIndexFilter, _unset)
          ? this.selectedPieIndexFilter
          : selectedPieIndexFilter as int?,
      selectedRegionFilter: identical(selectedRegionFilter, _unset)
          ? this.selectedRegionFilter
          : selectedRegionFilter as String?,
      selectedStatusFilter: identical(selectedStatusFilter, _unset)
          ? this.selectedStatusFilter
          : selectedStatusFilter as String?,
      savingOrImporting: savingOrImporting ?? this.savingOrImporting,
      mapZoom: mapZoom ?? this.mapZoom,
      regionLabels: regionLabels ?? this.regionLabels,
    );
  }

  String _canonRegion(String? s) {
    return ActiveRailwayData.canonRegion(s, regionLabels);
  }

  int? indexOfRegionNormalized(String? label) {
    if (label == null) return null;

    final c = _canonRegion(label);

    return regionLabels.indexWhere((r) {
      return _canonRegion(r) == c;
    });
  }

  String _statusCodeOf(ActiveRailwayData r) {
    return ActiveRailwayData.statusCodeOf(r.status);
  }

  List<String> get _statusOrder {
    return ActiveRailwayData.statusOrder;
  }

  String _labelForStatus(String code) {
    return ActiveRailwayData.labelForStatus(code);
  }

  Map<String, double> get _sumExtByStatus {
    final map = <String, double>{
      for (final s in _statusOrder) s: 0.0,
    };

    for (final f in all) {
      final code = _statusCodeOf(f);
      final km = (f.extensao ?? 0.0).toDouble();

      map[code] = (map[code] ?? 0.0) + km;
    }

    return map;
  }

  List<({String code, Color color, String labelText, double value})>
  get _pieItems {
    final sums = _sumExtByStatus;

    return _statusOrder.map((code) {
      final km = sums[code] ?? 0.0;

      return (
      code: code,
      labelText: _labelForStatus(code),
      value: km,
      color: ActiveRailwaysStyle.colorForStatus(code),
      );
    }).toList(growable: false);
  }

  List<String> get pieLabelsForChart {
    return _pieItems.map((e) => e.labelText).toList(growable: false);
  }

  List<double> get pieValuesForChart {
    return _pieItems.map((e) => e.value).toList(growable: false);
  }

  List<Color> get pieColorsForChart {
    return _pieItems.map((e) => e.color).toList(growable: false);
  }

  double get pieTotal {
    return _pieItems.fold<double>(0.0, (s, e) => s + e.value);
  }

  String statusCodeFromPieChartIndex(int i) {
    final items = _pieItems;

    if (i < 0 || i >= items.length) return 'OUTRO';

    return items[i].code;
  }

  List<double> regionSumsKm() {
    final values = <double>[];

    final statusFilter = selectedPieIndexFilter == null
        ? null
        : statusCodeFromPieChartIndex(selectedPieIndexFilter!);

    for (final label in regionLabels) {
      final labelC = _canonRegion(label);

      final sumKm = all.where((f) {
        final regRaw = (f.municipio ?? f.uf ?? f.nome ?? '').toString();

        if (_canonRegion(regRaw) != labelC) return false;

        if (statusFilter == null) return true;

        return _statusCodeOf(f) == statusFilter;
      }).fold<double>(0.0, (acc, f) {
        return acc + (f.extensao ?? 0.0);
      });

      values.add(sumKm);
    }

    return values;
  }

  List<Color> regionBarColors(int? selectedRegionIndex) {
    final values = regionSumsKm();

    return List<Color>.generate(values.length, (i) {
      if (values[i] == 0.0) return Colors.grey.shade300;

      return selectedRegionIndex != null && selectedRegionIndex == i
          ? Colors.orangeAccent
          : Colors.blueAccent;
    });
  }

  String? get _statusFilterFromPieOrNull {
    return selectedPieIndexFilter == null
        ? null
        : statusCodeFromPieChartIndex(selectedPieIndexFilter!);
  }

  List<ActiveRailwayData> get filteredAll {
    final regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);

    final statusCode = _statusFilterFromPieOrNull ?? selectedStatusFilter;

    return all.where((f) {
      if (regionFilterC != null) {
        final regRaw = (f.municipio ?? f.uf ?? f.nome ?? '').toString();

        if (_canonRegion(regRaw) != regionFilterC) return false;
      }

      if (statusCode != null && statusCode.isNotEmpty) {
        if (_statusCodeOf(f) != statusCode) return false;
      }

      return true;
    }).toList(growable: false);
  }

  List<String>? get selectedRegionNamesForMap {
    return selectedRegionFilter == null ? null : [selectedRegionFilter!];
  }

  List<LatLng> _simplifyForZoom(
      List<LatLng> seg,
      double zoom,
      ) {
    return _simplifier.simplifyAdaptive(
      seg,
      zoom: zoom,
      tolerancePxFar: 5.5,
      tolerancePxMid: 3.5,
      minAngleDeg: 18,
      maxSegmentMeters: 120,
      metersPerPixelFn: RailwayTies.metersPerPixel,
    );
  }

  Polyline<Object> _buildPolyline({
    required List<LatLng> points,
    required Color color,
    required double strokeWidth,
    Object? hitValue,
  }) {
    return Polyline<Object>(
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      hitValue: hitValue,
    );
  }

  /// Retorna polylines nativas do flutter_map.
  ///
  /// O antigo `PolylineData.tag` foi substituído por `Polyline.hitValue`.
  /// Linhas decorativas, como halos e dormentes, ficam sem `hitValue`.
  List<Polyline<Object>> buildStyledPolylines({double? zoom}) {
    final z = zoom ?? mapZoom;
    final lines = <Polyline<Object>>[];

    final m = RailwayTies.metricsForZoom(z);

    for (final fer in filteredAll) {
      if (fer.id == null) continue;

      final tagId = fer.id!;
      final statusCode = ActiveRailwayData.statusCodeOf(fer.status);
      final estiloCamadas = ActiveRailwaysStyle.styleLane(statusCode, z);

      final isSelected =
          selectedPolylineId != null && selectedPolylineId == tagId;

      for (final rawSeg in fer.getSegments()) {
        if (rawSeg.length < 2) continue;

        final seg = _simplifyForZoom(rawSeg, z);

        if (seg.length < 2) continue;

        for (final entry in estiloCamadas.asMap().entries) {
          final idx = entry.key;
          final camada = entry.value;

          final ptsMain = ActiveRailwayData.deslocarPontos(
            seg,
            deslocamentoOrtogonal: (idx * 0.00003) + camada.dx,
          );

          if (ptsMain.length < 2) continue;

          final baseStrokeWidth = math.max(
            camada.strokeWidth,
            m.railStrokePx,
          );

          final selectedStrokeWidth = camada.strokeWidth + 2;

          if (m.outlinePx > 0) {
            lines.add(
              _buildPolyline(
                points: ptsMain,
                color: Colors.white.withValues(alpha: 0.95),
                strokeWidth:
                (isSelected ? selectedStrokeWidth : camada.strokeWidth) +
                    m.outlinePx * 2,
              ),
            );
          }

          lines.add(
            _buildPolyline(
              points: ptsMain,
              color: isSelected ? Colors.redAccent : camada.color,
              strokeWidth: isSelected ? selectedStrokeWidth : baseStrokeWidth,
              hitValue: tagId,
            ),
          );
        }

        if (m.showTies) {
          final ties = RailwayTies.generateTiesPx(
            seg,
            z,
            spacingPx: m.spacingPx,
            lengthPx: m.lengthPx,
          );

          const maxTiesPerSeg = 220;

          final usable = ties.length > maxTiesPerSeg
              ? [
            for (
            var i = 0;
            i < ties.length;
            i += (ties.length / maxTiesPerSeg).ceil()
            )
              ties[i],
          ]
              : ties;

          for (final t in usable) {
            if (t.length < 2) continue;

            if (m.tieHaloPx > 0) {
              lines.add(
                _buildPolyline(
                  points: t,
                  color: Colors.white,
                  strokeWidth: m.tieStrokePx + m.tieHaloPx * 2,
                ),
              );
            }

            lines.add(
              _buildPolyline(
                points: t,
                color: Colors.black,
                strokeWidth: m.tieStrokePx,
              ),
            );
          }
        }
      }
    }

    return lines;
  }

  @override
  List<Object?> get props => [
    initialized,
    loadStatus,
    error,
    all,
    selectedPolylineId,
    selectedPieIndexFilter,
    selectedRegionFilter,
    selectedStatusFilter,
    savingOrImporting,
    mapZoom,
    regionLabels,
  ];
}