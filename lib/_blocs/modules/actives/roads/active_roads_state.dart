import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/oacs/active_oacs_state.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_blocs/modules/actives/roads/active_roads_style.dart';
import 'package:sipged/screens/modules/actives/roads/network/road_label_circle.dart';
import 'package:sipged/_widgets/map/markers/marker_changed_data.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_data.dart';

enum ActiveRoadsLoadStatus { idle, loading, success, failure }

enum ActiveRoadColorMode {
  defaultColor,
  surface,
  vsa,
  region,
}

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

  final List<ActiveRoadsData> all;

  final String? selectedPolylineId;

  final int? selectedPieIndexFilter;
  final String? selectedRegionFilter;
  final String? selectedSurfaceFilter;
  final int? selectedVsaFilter;

  final bool savingOrImporting;

  final List<String> regionLabels;

  final int? activeBucket;
  final List<ActiveRoadMapGeom> mapGeoms;

  final int geomVersion;

  final ActiveRoadColorMode colorMode;

  const ActiveRoadsState({
    this.initialized = false,
    this.loadStatus = ActiveRoadsLoadStatus.idle,
    this.error,
    this.all = const [],
    this.selectedPolylineId,
    this.selectedPieIndexFilter,
    this.selectedRegionFilter,
    this.selectedSurfaceFilter,
    this.selectedVsaFilter,
    this.savingOrImporting = false,
    this.regionLabels = const [],
    this.activeBucket,
    this.mapGeoms = const [],
    this.geomVersion = 0,
    this.colorMode = ActiveRoadColorMode.defaultColor,
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
    Object? selectedVsaFilter = _unset,
    bool? savingOrImporting,
    List<String>? regionLabels,
    int? activeBucket,
    List<ActiveRoadMapGeom>? mapGeoms,
    int? geomVersion,
    ActiveRoadColorMode? colorMode,
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
      selectedVsaFilter: identical(selectedVsaFilter, _unset)
          ? this.selectedVsaFilter
          : selectedVsaFilter as int?,
      savingOrImporting: savingOrImporting ?? this.savingOrImporting,
      regionLabels: regionLabels ?? this.regionLabels,
      activeBucket: activeBucket ?? this.activeBucket,
      mapGeoms: mapGeoms ?? this.mapGeoms,
      geomVersion: geomVersion ?? this.geomVersion,
      colorMode: colorMode ?? this.colorMode,
    );
  }

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

  String _surfaceCodeOf(ActiveRoadsData road) {
    return ActiveRoadsStyle.normalizeSurfaceCode(
      road.stateSurface ?? road.surface ?? road.state ?? '',
    );
  }

  String _labelForSurface(String code) {
    return ActiveRoadsStyle.labelForSurface(code);
  }

  Color _effectivePolylineColor(ActiveRoadsData road) {
    switch (colorMode) {
      case ActiveRoadColorMode.defaultColor:
        return ActiveRoadsStyle.defaultRoadColor();
      case ActiveRoadColorMode.vsa:
        return ActiveRoadsStyle.colorForVsa(road.vsa);
      case ActiveRoadColorMode.surface:
        return ActiveRoadsStyle.colorForSurface(_surfaceCodeOf(road));
      case ActiveRoadColorMode.region:
        return ActiveRoadsStyle.colorForRegion(road.displayRegion);
    }
  }

  bool _matchesRegion(ActiveRoadsData r, String? regionCanon) {
    if (regionCanon == null) return true;
    return _canonRegion(r.displayRegion) == regionCanon;
  }

  bool _matchesSurface(ActiveRoadsData r, String? surfaceCode, String? fallbackText) {
    if (surfaceCode != null) {
      return _surfaceCodeOf(r) == surfaceCode;
    }

    if (fallbackText != null && fallbackText.isNotEmpty) {
      final raw = (r.stateSurface ?? r.surface ?? r.state ?? '').toUpperCase();
      return raw.contains(fallbackText);
    }

    return true;
  }

  bool _matchesVsa(ActiveRoadsData r, int? vsa) {
    if (vsa == null) return true;
    return r.vsa == vsa;
  }

  List<ActiveRoadsData> _filterRoads({
    bool includeRegion = true,
    bool includeSurface = true,
    bool includeVsa = true,
  }) {
    final regionFilterC =
    includeRegion && selectedRegionFilter != null ? _canonRegion(selectedRegionFilter) : null;

    final surfaceCode =
    includeSurface ? _surfaceFilterFromPieOrNull : null;

    final fallbackText =
    includeSurface ? selectedSurfaceFilter?.toUpperCase() : null;

    final vsaFilter =
    includeVsa ? selectedVsaFilter : null;

    return all.where((r) {
      if (!_matchesRegion(r, regionFilterC)) return false;
      if (!_matchesSurface(r, surfaceCode, fallbackText)) return false;
      if (!_matchesVsa(r, vsaFilter)) return false;
      return true;
    }).toList(growable: false);
  }

  List<ActiveRoadsData> get _baseForPieChart {
    return _filterRoads(
      includeRegion: true,
      includeSurface: false,
      includeVsa: true,
    );
  }

  Map<String, double> get _sumExtBySurfaceInRegionAndVsa {
    final src = _baseForPieChart;
    final map = <String, double>{
      for (final s in ActiveRoadsStyle.surfaceCodesOrder) s: 0.0,
    };

    for (final r in src) {
      final code = _surfaceCodeOf(r);
      final extKm = (r.extension ?? 0.0).toDouble();
      map[code] = (map[code] ?? 0.0) + extKm;
    }

    return map;
  }

  List<({String code, Color color, String labelText, double value})>
  get _pieItems {
    final sums = _sumExtBySurfaceInRegionAndVsa;

    return ActiveRoadsStyle.surfaceCodesOrder.map((code) {
      final km = sums[code] ?? 0.0;

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

  double get pieTotal =>
      _pieItems.fold<double>(0.0, (sum, e) => sum + e.value);

  String surfaceCodeFromPieChartIndex(int pieIndex) {
    final items = _pieItems;
    if (pieIndex < 0 || pieIndex >= items.length) return 'OUTRO';
    return items[pieIndex].code;
  }

  GaugeVM gaugeForCurrentFilters() {
    final String? codeFilter = _surfaceFilterFromPieOrNull;
    final String? regionFilterC =
    selectedRegionFilter == null ? null : _canonRegion(selectedRegionFilter);
    final int? vsaFilter = selectedVsaFilter;

    double sumKm({
      String? regionC,
      String? surfaceCode,
      int? vsa,
    }) {
      return all.where((r) {
        if (regionC != null && _canonRegion(r.displayRegion) != regionC) {
          return false;
        }

        if (surfaceCode != null && _surfaceCodeOf(r) != surfaceCode) {
          return false;
        }

        if (vsa != null && r.vsa != vsa) {
          return false;
        }

        return true;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));
    }

    final totalKm = sumKm(
      regionC: regionFilterC,
      vsa: vsaFilter,
    );

    final countKm = sumKm(
      regionC: regionFilterC,
      surfaceCode: codeFilter,
      vsa: vsaFilter,
    );

    if (totalKm <= 0) {
      return const GaugeVM(label: 'Total', count: 0, total: 0, percent: 0);
    }

    final label = codeFilter != null ? _labelForSurface(codeFilter) : 'Total';

    return GaugeVM(
      label: label,
      count: countKm,
      total: totalKm,
      percent: (countKm / totalKm).clamp(0.0, 1.0),
    );
  }

  List<double> get regionSumsKm {
    final values = <double>[];

    for (final label in regionLabels) {
      final labelC = _canonRegion(label);

      final sumKm = all.where((r) {
        return _canonRegion(r.displayRegion) == labelC;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));

      values.add(sumKm);
    }

    return values;
  }

  List<double> regionCountsFilteredByPie() {
    final values = <double>[];
    final codeFilter = _surfaceFilterFromPieOrNull;
    final vsaFilter = selectedVsaFilter;

    for (final label in regionLabels) {
      final labelC = _canonRegion(label);

      final sumKm = all.where((r) {
        if (_canonRegion(r.displayRegion) != labelC) return false;
        if (codeFilter != null && _surfaceCodeOf(r) != codeFilter) return false;
        if (vsaFilter != null && r.vsa != vsaFilter) return false;
        return true;
      }).fold<double>(0.0, (acc, r) => acc + (r.extension ?? 0.0));

      values.add(sumKm);
    }

    return values;
  }

  List<Color> regionBarColors(int? selectedRegionIndex) {
    final values = regionCountsFilteredByPie();
    final hasSelection = selectedRegionIndex != null;

    return List<Color>.generate(regionLabels.length, (i) {
      final value = i < values.length ? values[i] : 0.0;
      final base = ActiveRoadsStyle.colorForRegion(regionLabels[i]);

      return ActiveRoadsStyle.colorForBarState(
        baseColor: base,
        value: value,
        isSelected: selectedRegionIndex == i,
        hasSomeFilter: hasSelection,
        isInFilter: selectedRegionIndex == i,
        hasSelection: hasSelection,
        isHighlighted: !hasSelection,
      );
    });
  }

  String? get _surfaceFilterFromPieOrNull {
    if (selectedPieIndexFilter == null) return null;
    return surfaceCodeFromPieChartIndex(selectedPieIndexFilter!);
  }

  List<ActiveRoadsData> get filteredAll {
    return _filterRoads(
      includeRegion: true,
      includeSurface: true,
      includeVsa: true,
    );
  }

  Set<String> get filteredIds =>
      filteredAll.map((e) => e.id).whereType<String>().toSet();

  List<String> get vsaLabelsForChart =>
      const ['VSA 1', 'VSA 2', 'VSA 3', 'VSA 4', 'VSA 5'];

  List<double> get vsaKmValuesForChart {
    final src = _filterRoads(
      includeRegion: true,
      includeSurface: true,
      includeVsa: false,
    );

    final map = <int, double>{
      1: 0.0,
      2: 0.0,
      3: 0.0,
      4: 0.0,
      5: 0.0,
    };

    for (final r in src) {
      final vsa = r.vsa;
      if (vsa == null || vsa < 1 || vsa > 5) continue;

      final km = (r.extension ?? 0.0).toDouble();
      map[vsa] = (map[vsa] ?? 0.0) + km;
    }

    return [
      map[1] ?? 0.0,
      map[2] ?? 0.0,
      map[3] ?? 0.0,
      map[4] ?? 0.0,
      map[5] ?? 0.0,
    ];
  }

  List<Color> get vsaColorsForChart {
    final values = vsaKmValuesForChart;
    final hasSelection = selectedVsaFilter != null;

    return List<Color>.generate(5, (i) {
      final vsa = i + 1;
      final base = ActiveRoadsStyle.colorForVsa(vsa);
      final value = i < values.length ? values[i] : 0.0;
      final isSelected = selectedVsaFilter == vsa;

      return ActiveRoadsStyle.colorForBarState(
        baseColor: base,
        value: value,
        isSelected: isSelected,
        hasSomeFilter: hasSelection,
        isInFilter: isSelected,
        hasSelection: hasSelection,
        isHighlighted: !hasSelection,
      );
    });
  }

  List<String>? get selectedRegionNamesForMap =>
      selectedRegionFilter == null ? null : [selectedRegionFilter!];

  List<ActiveRoadMapGeom> get filteredMapGeoms {
    final ids = filteredIds;
    return mapGeoms.where((g) => ids.contains(g.id)).toList(growable: false);
  }

  List<PolylineChangedData> buildStyledPolylines({
    required double zoom,
    required double centerLatitude,
  }) {
    final lines = <PolylineChangedData>[];

    for (final geom in filteredMapGeoms) {
      final code = _surfaceCodeOf(geom.road);
      final isSelected =
          selectedPolylineId != null && selectedPolylineId == geom.id;

      lines.addAll(
        ActiveRoadsStyle.buildRoadPolylines(
          id: geom.id,
          code: code,
          segments: geom.segments,
          zoom: zoom,
          centerLatitude: centerLatitude,
          isSelected: isSelected,
          overrideColor: _effectivePolylineColor(geom.road),
        ),
      );
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
    selectedVsaFilter,
    savingOrImporting,
    regionLabels,
    activeBucket,
    geomVersion,
    colorMode,
  ];
}

/// ===============================
/// HELPERS DE LABELS
/// ===============================

double _labelDiameterForZoom(double zoom) {
  if (zoom < 7.0) return 0.0;
  if (zoom < 7.8) return 14.0;
  if (zoom < 8.6) return 16.0;
  if (zoom < 9.4) return 18.0;
  if (zoom < 10.4) return 20.0;
  if (zoom < 11.4) return 22.0;
  return 24.0;
}

double _labelFontForDiameter(double diameter) {
  if (diameter <= 0) return 0.0;
  return (diameter * 0.38).clamp(7.0, 10.0);
}

int _maxLabelsForZoom(double zoom) {
  if (zoom < 7.0) return 0;
  if (zoom < 7.8) return 8;
  if (zoom < 8.6) return 14;
  if (zoom < 9.4) return 22;
  if (zoom < 10.4) return 32;
  if (zoom < 11.4) return 46;
  return 64;
}

double _minExtensionKmForZoom(double zoom) {
  if (zoom < 7.0) return double.infinity;
  if (zoom < 7.8) return 80.0;
  if (zoom < 8.6) return 55.0;
  if (zoom < 9.4) return 35.0;
  if (zoom < 10.4) return 18.0;
  if (zoom < 11.4) return 8.0;
  return 0.0;
}

String _labelTextForRoad(ActiveRoadsData road) {
  final label = (road.acronym?.isNotEmpty ?? false)
      ? road.acronym!
      : (road.roadCode ?? '');
  return label.trim();
}

List<ActiveRoadMapGeom> _selectRoadLabelGeoms({
  required List<ActiveRoadMapGeom> geoms,
  required double zoom,
}) {
  final maxLabels = _maxLabelsForZoom(zoom);
  if (maxLabels <= 0) return const [];

  final minExtensionKm = _minExtensionKmForZoom(zoom);

  final filtered = geoms.where((g) {
    final anchor = g.road.labelAnchorOnLine;
    if (anchor == null) return false;

    final label = _labelTextForRoad(g.road);
    if (label.isEmpty) return false;

    final ext = (g.road.extension ?? 0.0).toDouble();
    if (ext < minExtensionKm) return false;

    return true;
  }).toList(growable: false);

  final ordered = List<ActiveRoadMapGeom>.from(filtered)
    ..sort((a, b) {
      final extA = (a.road.extension ?? 0.0).toDouble();
      final extB = (b.road.extension ?? 0.0).toDouble();

      final byExt = extB.compareTo(extA);
      if (byExt != 0) return byExt;

      final labelA = _labelTextForRoad(a.road).toUpperCase();
      final labelB = _labelTextForRoad(b.road).toUpperCase();
      return labelA.compareTo(labelB);
    });

  if (ordered.length <= maxLabels) return ordered;
  return ordered.take(maxLabels).toList(growable: false);
}

extension ActiveRoadsLabelClusterExt on ActiveRoadsState {
  List<MarkerChangedData<ActiveRoadsData>> buildRoadLabelTaggedMarkers({
    required double zoom,
  }) {
    final size = _labelDiameterForZoom(zoom);
    if (size <= 0) return const [];

    final font = _labelFontForDiameter(size);
    final selected = _selectRoadLabelGeoms(
      geoms: filteredMapGeoms,
      zoom: zoom,
    );

    return selected
        .map((g) {
      final r = g.road;
      final anchor = r.labelAnchorOnLine;
      if (anchor == null) return null;

      final label = _labelTextForRoad(r);
      if (label.isEmpty) return null;

      return MarkerChangedData<ActiveRoadsData>(
        point: anchor,
        data: r,
        properties: {
          'label': label,
          'diameter': size,
          'font': font,
        },
      );
    })
        .whereType<MarkerChangedData<ActiveRoadsData>>()
        .toList(growable: false);
  }
}

extension ActiveRoadsLabelsExtension on ActiveRoadsState {
  List<Marker> buildRoadLabelMarkers({required double zoom}) {
    final size = _labelDiameterForZoom(zoom);
    if (size <= 0) return const [];

    final font = _labelFontForDiameter(size);
    final selected = _selectRoadLabelGeoms(
      geoms: filteredMapGeoms,
      zoom: zoom,
    );

    return selected
        .map((g) {
      final r = g.road;
      final anchor = r.labelAnchorOnLine;
      if (anchor == null) return null;

      final label = _labelTextForRoad(r);
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

final _distance = const Distance();

LatLng? pointAtDistanceOnLine(List<LatLng> pts, double targetMeters) {
  if (pts.length < 2) return pts.isNotEmpty ? pts.first : null;

  double acc = 0.0;
  for (int i = 0; i < pts.length - 1; i++) {
    final a = pts[i];
    final b = pts[i + 1];
    final seg = _distance.as(LengthUnit.Meter, a, b);

    if (acc + seg >= targetMeters) {
      final remain = targetMeters - acc;
      final t = seg == 0 ? 0.0 : (remain / seg).clamp(0.0, 1.0);

      return LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
    }

    acc += seg;
  }

  return pts.last;
}

double lengthOfLineMeters(List<LatLng> pts) {
  double acc = 0.0;
  for (int i = 0; i < pts.length - 1; i++) {
    acc += _distance.as(LengthUnit.Meter, pts[i], pts[i + 1]);
  }
  return acc;
}

extension ActiveRoadsAnchors on ActiveRoadsData {
  LatLng? get labelAnchorOnLine {
    final pts = points;
    if (pts == null || pts.length < 2) return centerLatLng ?? pts?.first;

    final total = lengthOfLineMeters(pts);
    if (total <= 0) return pts.first;

    return pointAtDistanceOnLine(pts, total / 2);
  }
}