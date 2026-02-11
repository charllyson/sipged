// lib/_blocs/modules/actives/roads/active_roads_state.dart
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:siged/_blocs/modules/actives/roads/active_road_style.dart';
import 'package:siged/_widgets/map/markers/tagged_marker.dart';
import 'package:siged/_widgets/map/polylines/tappable_changed_polyline.dart';
import 'package:siged/_widgets/map/roads/road_label_circle.dart';

import '../../../../_widgets/map/roads/gauge_vm.dart';

enum ActiveRoadsLoadStatus { idle, loading, success, failure }

/// Geometria já simplificada (por bucket), com segmentos preservados.
class ActiveRoadMapGeom {
  final String id;
  final ActiveRoadsData road;
  final List<List<LatLng>> segments;

  const ActiveRoadMapGeom({
    required this.id,
    required this.road,
    required this.segments,
  });
}

class ActiveRoadsState extends Equatable {
  static const _unset = Object();

  final bool initialized;
  final ActiveRoadsLoadStatus loadStatus;
  final String? error;

  /// Dados “raw” (doc -> campos)
  final List<ActiveRoadsData> all;

  /// Seleção visual no mapa (id/tag da polyline)
  final String? selectedPolylineId;

  /// >>> FILTROS <<<
  final int? selectedPieIndexFilter;
  final String? selectedRegionFilter;
  final String? selectedSurfaceFilter;

  final bool savingOrImporting;

  /// Labels de região vindos dos dados (regional / metadata['regional']) ou do Setup.
  final List<String> regionLabels;

  // ✅ Cache aplicado (bucket) + geoms simplificados
  final int? activeBucket;
  final List<ActiveRoadMapGeom> mapGeoms;

  /// 🔹 Força emits mesmo com Equatable (geoms não entram em props)
  final int geomVersion;

  const ActiveRoadsState({
    this.initialized = false,
    this.loadStatus = ActiveRoadsLoadStatus.idle,
    this.error,
    this.all = const [],
    this.selectedPolylineId,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,
    this.selectedSurfaceFilter,
    this.savingOrImporting = false,
    this.regionLabels = const [],
    this.activeBucket,
    this.mapGeoms = const [],
    this.geomVersion = 0,
  });

  ActiveRoadsState copyWith({
    bool? initialized,
    ActiveRoadsLoadStatus? loadStatus,
    String? error,
    List<ActiveRoadsData>? all,
    Object? selectedPolylineId = _unset,
    Object? selectedPieIndexFilter = _unset,
    Object? selectedRegionFilter = _unset,
    Object? selectedSurfaceFilter = _unset,
    bool? savingOrImporting,
    List<String>? regionLabels,
    int? activeBucket,
    List<ActiveRoadMapGeom>? mapGeoms,
    int? geomVersion,
  }) {
    return ActiveRoadsState(
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
      selectedSurfaceFilter: identical(selectedSurfaceFilter, _unset)
          ? this.selectedSurfaceFilter
          : selectedSurfaceFilter as String?,
      savingOrImporting: savingOrImporting ?? this.savingOrImporting,
      regionLabels: regionLabels ?? this.regionLabels,
      activeBucket: activeBucket ?? this.activeBucket,
      mapGeoms: mapGeoms ?? this.mapGeoms,
      geomVersion: geomVersion ?? this.geomVersion,
    );
  }

  // ===========================================================================
  // Normalização/canonização de REGIÕES
  // ===========================================================================
  String _stripDiacritics(String s) {
    const map = {
      'Á': 'A',
      'À': 'A',
      'Â': 'A',
      'Ã': 'A',
      'Ä': 'A',
      'É': 'E',
      'È': 'E',
      'Ê': 'E',
      'Ë': 'E',
      'Í': 'I',
      'Ì': 'I',
      'Î': 'I',
      'Ï': 'I',
      'Ó': 'O',
      'Ò': 'O',
      'Ô': 'O',
      'Õ': 'O',
      'Ö': 'O',
      'Ú': 'U',
      'Ù': 'U',
      'Û': 'U',
      'Ü': 'U',
      'Ç': 'C',
    };
    final buf = StringBuffer();
    for (final r in s.runes) {
      final ch = String.fromCharCode(r);
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }

  String _normRegion(String? s) {
    if (s == null) return '';
    var t = s.toUpperCase().trim();
    t = t.replaceAll(RegExp(r'\s+'), ' ');
    t = _stripDiacritics(t);
    return t;
  }

  String _canonRegion(String? s) {
    final n = _normRegion(s);
    if (n.isEmpty) return n;

    for (final label in regionLabels) {
      final ln = _normRegion(label);
      if (n == ln) return ln;
    }

    if (n.contains('MUNDAU')) return _normRegion('VALE DO MUNDAÚ');
    if (n.contains('PARAIBA')) return _normRegion('VALE DO PARAÍBA');

    return n;
  }

  int? indexOfRegionNormalized(String? label) {
    if (label == null) return null;
    final selC = _canonRegion(label);
    return regionLabels.indexWhere((r) => _canonRegion(r) == selC);
  }

  // ===========================================================================
  // Status/Superfície
  // ===========================================================================
  List<String> get _surfaceCodesOrder =>
      const <String>['DUP', 'EOD', 'PAV', 'EOP', 'IMP', 'EOI', 'PLA', 'LEN', 'OUTRO'];

  String _labelForSurface(String code) {
    switch (code) {
      case 'DUP':
        return 'Duplicada';
      case 'EOD':
        return 'Em obra (duplicação)';
      case 'PAV':
        return 'Pavimentada';
      case 'EOP':
        return 'Em obra (pavim.)';
      case 'IMP':
        return 'Implantada';
      case 'EOI':
        return 'Em obra (impl.)';
      case 'PLA':
        return 'Planejada';
      case 'LEN':
        return 'Leito natural';
      default:
        return 'Outro';
    }
  }

  String _surfaceCodeOf(ActiveRoadsData r) {
    final raw = (r.stateSurface ?? r.surface ?? r.state ?? '').toString().trim().toUpperCase();
    if (raw.isEmpty) return 'OUTRO';
    if (_surfaceCodesOrder.contains(raw)) return raw;

    if (raw.contains('DUP')) return 'DUP';
    if (raw.contains('OBRA') && raw.contains('DUP')) return 'EOD';
    if (raw.contains('PAV') && raw.contains('OBRA')) return 'EOP';
    if (raw.contains('PAV')) return 'PAV';
    if (raw.contains('IMPL')) return 'IMP';
    if (raw.contains('OBRA') && raw.contains('IMP')) return 'EOI';
    if (raw.contains('PLAN')) return 'PLA';
    if (raw.contains('LEITO') || raw.contains('NAT')) return 'LEN';
    return 'OUTRO';
  }

  // ===========================================================================
  // Coleções derivadas para CHARTS (base já filtrada por REGIÃO)
  // ===========================================================================
  List<ActiveRoadsData> get _baseForCharts {
    final regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);
    if (regionFilterC == null) return all;

    return all.where((r) {
      final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
      return _canonRegion(regRaw) == regionFilterC;
    }).toList(growable: false);
  }

  Map<String, double> get _sumExtBySurfaceInRegion {
    final src = _baseForCharts;
    final map = <String, double>{for (final s in _surfaceCodesOrder) s: 0.0};
    for (final r in src) {
      final code = _surfaceCodeOf(r);
      final extKm = (r.extension ?? 0.0).toDouble();
      map[code] = (map[code] ?? 0.0) + extKm;
    }
    return map;
  }

  List<({String code, Color color, String labelText, double value})> get _pieItems {
    final sums = _sumExtBySurfaceInRegion;
    return _surfaceCodesOrder.map((code) {
      final km = (sums[code] ?? 0.0);
      return (
      code: code,
      labelText: _labelForSurface(code),
      value: km,
      color: ActiveRoadsStyle.colorForSurface(code),
      );
    }).toList(growable: false);
  }

  List<String> get pieLabelsForChart =>
      _pieItems.map((e) => e.labelText).toList(growable: false);
  List<double> get pieValuesForChart =>
      _pieItems.map((e) => e.value).toList(growable: false);
  List<Color> get pieColorsForChart =>
      _pieItems.map((e) => e.color).toList(growable: false);
  double get pieTotal => _pieItems.fold<double>(0.0, (sum, e) => sum + e.value);

  String surfaceCodeFromPieChartIndex(int pieIndex) {
    final items = _pieItems;
    if (pieIndex < 0 || pieIndex >= items.length) return 'OUTRO';
    return items[pieIndex].code;
  }

  // ===========================================================================
  // GAUGE — percentual de km (considera PIE + REGIÃO)
  // ===========================================================================
  GaugeVM gaugeForCurrentFilters() {
    final String? codeFilter = _surfaceFilterFromPieOrNull;
    final String? regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);

    double sumKm({String? regionC, String? surfaceCode}) {
      return all.where((r) {
        if (regionC != null) {
          final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
          if (_canonRegion(regRaw) != regionC) return false;
        }
        if (surfaceCode != null) {
          return _surfaceCodeOf(r) == surfaceCode;
        }
        return true;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));
    }

    final double totalKm = sumKm(regionC: regionFilterC);
    final double countKm = sumKm(regionC: regionFilterC, surfaceCode: codeFilter);

    if (totalKm <= 0) {
      return const GaugeVM(label: 'Total', count: 0, total: 0, percent: 0);
    }

    final String label = (codeFilter != null) ? _labelForSurface(codeFilter) : 'Total';
    return GaugeVM(
      label: label,
      count: countKm,
      total: totalKm,
      percent: (countKm / totalKm).clamp(0.0, 1.0),
    );
  }

  // ===========================================================================
  // REGIÕES — soma de extensão (km)
  // ===========================================================================
  List<double> get regionSumsKm {
    final values = <double>[];
    for (final label in regionLabels) {
      final labelC = _canonRegion(label);
      final sumKm = all.where((r) {
        final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
        return _canonRegion(regRaw) == labelC;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));
      values.add(sumKm);
    }
    return values;
  }

  List<double> regionCountsFilteredByPie() {
    final values = <double>[];
    final codeFilter = _surfaceFilterFromPieOrNull;

    for (final label in regionLabels) {
      final labelC = _canonRegion(label);
      final sumKm = all.where((r) {
        final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
        if (_canonRegion(regRaw) != labelC) return false;
        if (codeFilter == null) return true;
        return _surfaceCodeOf(r) == codeFilter;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));
      values.add(sumKm);
    }
    return values;
  }

  List<Color> regionBarColors(int? selectedRegionIndex) {
    final values = regionSumsKm;
    return List<Color>.generate(values.length, (i) {
      final v = values[i];
      if (v == 0.0) return Colors.grey.shade300;
      return (selectedRegionIndex != null && selectedRegionIndex == i)
          ? Colors.orangeAccent
          : Colors.blueAccent;
    });
  }

  // ===========================================================================
  // FILTROS aplicados (para mapa e UIs)
  // ===========================================================================
  String? get _surfaceFilterFromPieOrNull {
    if (selectedPieIndexFilter == null) return null;
    return surfaceCodeFromPieChartIndex(selectedPieIndexFilter!);
  }

  List<ActiveRoadsData> get filteredAll {
    final regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);
    final codeFilter = _surfaceFilterFromPieOrNull;
    final fallbackText = selectedSurfaceFilter?.toUpperCase();

    return all.where((r) {
      if (regionFilterC != null) {
        final regRaw = (r.regional ?? r.metadata?['regional'] ?? '').toString();
        if (_canonRegion(regRaw) != regionFilterC) return false;
      }
      if (codeFilter != null) return _surfaceCodeOf(r) == codeFilter;
      if (fallbackText != null && fallbackText.isNotEmpty) {
        final raw = (r.stateSurface ?? r.surface ?? r.state ?? '')
            .toString()
            .toUpperCase();
        return raw.contains(fallbackText);
      }
      return true;
    }).toList(growable: false);
  }

  List<String>? get selectedRegionNamesForMap =>
      selectedRegionFilter == null ? null : [selectedRegionFilter!];

  // ===========================================================================
  // MAPA — polylines estilizadas usando SEGMENTOS SIMPLIFICADOS (mapGeoms)
  // ===========================================================================
  List<TappableChangedPolyline> buildStyledPolylines({
    required double zoom,
    required double centerLatitude,
  }) {
    final List<TappableChangedPolyline> lines = [];

    final lanePx = ActiveRoadsData.laneWidthForZoom(zoom);
    final sepPx = ActiveRoadsData.laneSeparationPxForZoom(zoom);
    final degPerPx = ActiveRoadsData.degreesPerPixel(centerLatitude, zoom);
    final deltaDeg = sepPx * degPerPx;

    // ✅ aplica filtros em cima de mapGeoms (cache por bucket)
    final regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);
    final codeFilter = _surfaceFilterFromPieOrNull;
    final fallbackText = selectedSurfaceFilter?.toUpperCase();

    bool passFilters(ActiveRoadsData road) {
      if (regionFilterC != null) {
        final regRaw = (road.regional ?? road.metadata?['regional'] ?? '').toString();
        if (_canonRegion(regRaw) != regionFilterC) return false;
      }

      if (codeFilter != null) return _surfaceCodeOf(road) == codeFilter;

      if (fallbackText != null && fallbackText.isNotEmpty) {
        final raw = (road.stateSurface ?? road.surface ?? road.state ?? '')
            .toString()
            .toUpperCase();
        return raw.contains(fallbackText);
      }

      return true;
    }

    for (final g in mapGeoms) {
      final road = g.road;
      final id = g.id;
      if (!passFilters(road)) continue;

      final code = _surfaceCodeOf(road);
      final dupla = ActiveRoadsData.isDupla(code);
      final dash = ActiveRoadsData.isTracejada(code);

      final baseColor = ActiveRoadsStyle.colorForSurface((code == 'OUTRO') ? '' : code);

      final isSelected = (selectedPolylineId != null && selectedPolylineId == id);
      final displayColor = isSelected ? Colors.orangeAccent : baseColor;

      final bool drawHalo = isSelected;
      final Color haloColor = Colors.white.withOpacity(0.95);
      final double haloExtra = 3.0;

      final w = isSelected ? (lanePx + 2) : lanePx;

      void addTrack({required List<LatLng> points}) {
        if (drawHalo) {
          lines.add(
            TappableChangedPolyline(
              points: points,
              tag: id,
              color: haloColor,
              defaultColor: haloColor,
              strokeWidth: w + haloExtra,
              isDotted: false,
              hitTestable: false,
            ),
          );
        }
        lines.add(
          TappableChangedPolyline(
            points: points,
            tag: id,
            color: displayColor,
            defaultColor: baseColor,
            strokeWidth: w,
            isDotted: dash,
            hitTestable: true,
          ),
        );
      }

      for (final seg in g.segments) {
        if (seg.length < 2) continue;

        if (dupla) {
          final left = ActiveRoadsData.deslocarPontos(
            seg,
            deslocamentoOrtogonal: -deltaDeg,
            miterLimit: 3.0,
            densifyIfSegmentMeters: 0,
          );
          addTrack(points: left);

          final right = ActiveRoadsData.deslocarPontos(
            seg,
            deslocamentoOrtogonal: deltaDeg,
            miterLimit: 3.0,
            densifyIfSegmentMeters: 0,
          );
          addTrack(points: right);
        } else {
          addTrack(points: seg);
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
    selectedSurfaceFilter,
    savingOrImporting,
    regionLabels,
    activeBucket,
    // ✅ garante emit (mesmo sem comparar geoms)
    geomVersion,
  ];
}

// ============================================================================
// Labels em TaggedChangedMarker (cluster)
// ============================================================================
extension ActiveRoadsLabelClusterExt on ActiveRoadsState {
  List<TaggedChangedMarker<ActiveRoadsData>> buildRoadLabelTaggedMarkers({
    required double zoom,
  }) {
    final size = (zoom * 3.2).clamp(18.0, 32.0);
    final font = (size * 0.45).clamp(8.0, 13.0);

    // usa o dataset filtrado (para não gerar labels “fantasmas”)
    final filteredIds = filteredAll.map((e) => e.id).whereType<String>().toSet();

    return mapGeoms
        .where((g) => filteredIds.contains(g.id))
        .map((g) {
      final r = g.road;
      final anchor = r.labelAnchorOnLine;
      if (anchor == null) return null;

      final label = (r.acronym?.isNotEmpty ?? false) ? r.acronym! : (r.roadCode ?? '');
      if (label.isEmpty) return null;

      return TaggedChangedMarker<ActiveRoadsData>(
        point: anchor,
        data: r,
        properties: {'label': label, 'diameter': size, 'font': font},
      );
    })
        .whereType<TaggedChangedMarker<ActiveRoadsData>>()
        .toList(growable: false);
  }
}

extension ActiveRoadsLabelsExtension on ActiveRoadsState {
  List<Marker> buildRoadLabelMarkers({required double zoom}) {
    final size = (zoom * 3.2).clamp(18.0, 32.0);
    final font = (size * 0.45).clamp(8.0, 13.0);

    final filteredIds = filteredAll.map((e) => e.id).whereType<String>().toSet();

    return mapGeoms
        .where((g) => filteredIds.contains(g.id))
        .map((g) {
      final r = g.road;
      final anchor = r.labelAnchorOnLine;
      if (anchor == null) return null;

      final label = (r.acronym?.isNotEmpty ?? false) ? r.acronym! : (r.roadCode ?? '');
      if (label.isEmpty) return null;

      return Marker(
        point: anchor,
        width: size,
        height: size,
        alignment: Alignment.center,
        child: RoadLabelCircle(
          text: label,
          diameter: size,
          fontSize: font,
        ),
      );
    })
        .whereType<Marker>()
        .toList(growable: false);
  }
}

// ============================================================================
// Anchors para labels (mantém sua lógica original)
// ============================================================================
final _dist = const Distance();

LatLng? pointAtDistanceOnLine(List<LatLng> pts, double targetMeters) {
  if (pts.length < 2) return pts.isNotEmpty ? pts.first : null;

  double acc = 0.0;
  for (int i = 0; i < pts.length - 1; i++) {
    final a = pts[i];
    final b = pts[i + 1];
    final seg = _dist.as(LengthUnit.Meter, a, b);

    if (acc + seg >= targetMeters) {
      final remain = targetMeters - acc;
      final t = (seg == 0) ? 0.0 : (remain / seg).clamp(0.0, 1.0);
      final lat = a.latitude + (b.latitude - a.latitude) * t;
      final lng = a.longitude + (b.longitude - a.longitude) * t;
      return LatLng(lat, lng);
    }
    acc += seg;
  }
  return pts.last;
}

double lengthOfLineMeters(List<LatLng> pts) {
  double acc = 0.0;
  for (int i = 0; i < pts.length - 1; i++) {
    acc += _dist.as(LengthUnit.Meter, pts[i], pts[i + 1]);
  }
  return acc;
}

extension ActiveRoadsAnchors on ActiveRoadsData {
  LatLng? get labelAnchorOnLine {
    final pts = points;
    if (pts == null || pts.length < 2) return centerLatLng ?? pts?.first;
    final L = lengthOfLineMeters(pts);
    if (L <= 0) return pts.first;
    return pointAtDistanceOnLine(pts, L / 2);
  }
}
