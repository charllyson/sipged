// lib/screens/modules/traffic/accidents/dashboard/widgets/accident_dashboard_map.dart
import 'dart:math' as math;

import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_utils/theme/sipged_theme.dart';
import 'package:sipged/_widgets/map/pin/pin_aureola.dart';

import 'package:sipged/_widgets/map/flutter_map/map_interactive.dart';
import 'package:sipged/_widgets/map/polygon/polygon_changed_data.dart';

import 'package:sipged/_blocs/modules/transit/accidents/accidents_data.dart';

class AccidentDashboardMap extends StatelessWidget {
  final LatLng center;

  final List<AccidentsData> accidents;
  final void Function(AccidentsData acc) onTapMarker;

  final List<PolygonChangedData> polygonsChanged;

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

  String _norm(String s) =>
      removeDiacritics(s).replaceAll(RegExp(r'\s+'), ' ').trim().toUpperCase();

  String _severityOf(AccidentsData a) {
    final death = (a.death ?? 0);
    if (death > 0) return 'GRAVE';

    final victims = (a.scoresVictims ?? 0);
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

  // ---------------------------------------------------------------------------
  // ✅ BOUNDS + CENTER + ZOOM (fit no Split) — sem depender do MapInteractivePage
  // ---------------------------------------------------------------------------

  (_Bounds? bounds, bool any) _boundsFromPolygons(
      List<PolygonChangedData> polys, {
        int sampleTarget = 90,
      }) {
    if (polys.isEmpty) return (null, false);

    double minLat = 999.0, maxLat = -999.0;
    double minLng = 999.0, maxLng = -999.0;

    bool any = false;

    for (final p in polys) {
      final pts = p.polygon.points;
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
    }

    if (!any) return (null, false);

    return (
    _Bounds(minLat: minLat, maxLat: maxLat, minLng: minLng, maxLng: maxLng),
    true
    );
  }

  /// Expande bounds com padding em graus (proporcional ao span + mínimo)
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

  /// WebMercator helpers
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

  // ---------------------------------------------------------------------------
  // ✅ Cores (noData / data / selected no modelo) + borda MAIS VIVA
  // ---------------------------------------------------------------------------


  List<PolygonChangedData> _applyAccidentsStyle({
    required List<PolygonChangedData> polys,
    required Map<String, Color> cityColorsNorm,
  }) {
    if (polys.isEmpty) return polys;

    final citiesWithData = cityColorsNorm.keys.map(_norm).toSet();

    const noDataBase = Color(0xFF000000);
    const noDataBorderBase = Color(0xFF000000);

    const noDataAlpha = 0.05;        // fill noData bem fantasma
    const noDataBorderAlpha = 0.12;  // borda noData leve

    const dataAlpha = 0.55;          // fill com dado

    const dataBorderWidth = 1.7;
    const noDataBorderWidth = 0.8;

    const selectedFill = Color(0xFF1E6BFF);
    const selectedBorder = Color(0xFF0B2F7A);
    const selectedAlpha = 0.78;

    return polys.map((p) {
      final nameNorm = _norm(p.title);
      final hasData = citiesWithData.contains(nameNorm);

      final dataBase = cityColorsNorm[nameNorm] ??
          cityColorsNorm[p.title.trim()] ??
          cityColorsNorm[p.title.trim().toUpperCase()] ??
          const Color(0xFF5AA7FF);

      final fill = hasData
          ? dataBase.withValues(alpha: dataAlpha)
          : noDataBase.withValues(alpha: noDataAlpha);

      // ✅ borda SEM transparência quando tem dado
      final border = hasData
          ? dataBase
          : noDataBorderBase.withValues(alpha: noDataBorderAlpha);

      return p.copyWith(
        normalFillColor: fill,
        normalBorderColor: border,
        normalBorderWidth: hasData ? dataBorderWidth : noDataBorderWidth,

        selectedFillColor: selectedFill.withValues(alpha: selectedAlpha),
        selectedBorderColor: selectedBorder,
        selectedBorderWidth: hasData ? 2.6 : 2.4,
      );
    }).toList(growable: false);
  }


  @override
  Widget build(BuildContext context) {
    // Map<cityName, Color> (intensidade)
    final cityColors = AccidentsData.calculateColorsFilteredCity(accidents);

    final styledPolys = _applyAccidentsStyle(
      polys: polygonsChanged,
      cityColorsNorm: cityColors,
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
    })
        .toList(growable: false);

    // ✅ recalcula center/zoom no tamanho real do painel
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

        return MapInteractivePage<AccidentsData>(
          key: ValueKey('transitMap_${styledPolys.length}'),
          activeMap: true,
          showLegend: false,
          showSearch: false,
          showChangeMapType: true,
          showMyLocation: true,
          initialZoom: effectiveZoom,
          minZoom: 5,
          maxZoom: 19,

          // ✅ modelo já “carimbado”
          polygonsChanged: styledPolys,

          // ✅ respeitar 100% o modelo (sem opacidade padrão do MapInteractive)
          polygonChangeColors: null,

          allowMultiSelect: false,
          selectedRegionNames: selectedRegionNames ?? const <String>[],
          onRegionTap: onRegionTap,
          extraMarkers: markers,
          initialGeometryPoints: [effectiveCenter],
        );
      },
    );
  }
}

class _Bounds {
  final double minLat, maxLat, minLng, maxLng;
  const _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });
}
