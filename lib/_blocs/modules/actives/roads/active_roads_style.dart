import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_data.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_data.dart';

class ActiveRoadsStyle {
  const ActiveRoadsStyle._();

  static const List<String> surfaceCodesOrder = <String>[
    'DUP',
    'EOD',
    'PAV',
    'EOP',
    'IMP',
    'EOI',
    'PLA',
    'LEN',
    'OUTRO',
  ];

  /// Paleta fixa e estável para regionais.
  /// Evita colisão visual de hash.
  static const Map<String, Color> _regionColorMap = <String, Color>{
    'AGRESTE': Color(0xFFF57C00),
    'METROPOLITANA': Color(0xFF0F8B94),
    'VALE DO MUNDAU': Color(0xFFFF4D6D),
    'VALE DO PARAIBA': Color(0xFFFFB703),
    'NORTE': Color(0xFF6E7BFF),
    'SERTAO': Color(0xFF60A5FA),
    'SUL': Color(0xFFB66DFF),
  };

  static const List<Color> _vsaPalette = <Color>[
    Color(0xFFD32F2F),
    Color(0xFFF57C00),
    Color(0xFFFBC02D),
    Color(0xFF7CB342),
    Color(0xFF2E7D32),
  ];

  static const Color _selectedBarOverlay = Colors.orange;
  static const Color _selectedRoadColor = Colors.orangeAccent;

  static String normalizeSurfaceCode(String? rawValue) {
    final raw = (rawValue ?? '').trim().toUpperCase();

    if (raw.isEmpty) return 'OUTRO';
    if (surfaceCodesOrder.contains(raw)) return raw;

    if (raw.contains('OBRA') && raw.contains('DUP')) return 'EOD';
    if (raw.contains('DUP')) return 'DUP';
    if (raw.contains('PAV') && raw.contains('OBRA')) return 'EOP';
    if (raw.contains('PAV')) return 'PAV';
    if (raw.contains('OBRA') && raw.contains('IMP')) return 'EOI';
    if (raw.contains('IMPL')) return 'IMP';
    if (raw.contains('PLAN')) return 'PLA';
    if (raw.contains('LEITO') || raw.contains('NAT')) return 'LEN';

    return 'OUTRO';
  }

  static String labelForSurface(String code) {
    switch (normalizeSurfaceCode(code)) {
      case 'DUP':
        return 'Duplicada';
      case 'EOD':
        return 'Em Duplicação';
      case 'PAV':
        return 'Pavimentada';
      case 'EOP':
        return 'Em Pavimentação';
      case 'IMP':
        return 'Implantada';
      case 'EOI':
        return 'Em Implantação';
      case 'PLA':
        return 'Planejada';
      case 'LEN':
        return 'Leito Natural';
      default:
        return 'Outro';
    }
  }

  static Color defaultRoadColor() => Colors.green.shade600;

  static Color colorForSurface(String code) {
    switch (normalizeSurfaceCode(code)) {
      case 'DUP':
        return const Color(0xFF2ECC71);

      case 'PAV':
        return const Color(0xFF2979FF);

      case 'EOD':
        return const Color(0xFFFF6D00);

      case 'EOP':
        return const Color(0xFF00B8D4);

      case 'EOI':
        return const Color(0xFFAA00FF);

      case 'IMP':
        return const Color(0xFFFFB703);

      case 'PLA':
        return const Color(0xFFFF4D6D);

      case 'LEN':
        return const Color(0xFF8D6E63);

      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static String normalizeRegionKey(String? input) {
    var text = (input ?? '').trim().toUpperCase();
    if (text.isEmpty) return '';

    const accents = <String, String>{
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

    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final char = String.fromCharCode(rune);
      buffer.write(accents[char] ?? char);
    }

    text = buffer.toString();
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    if (text.contains('MUNDAU')) return 'VALE DO MUNDAU';
    if (text.contains('PARAIBA')) return 'VALE DO PARAIBA';

    return text;
  }

  static Color colorForRegion(String? region) {
    final key = normalizeRegionKey(region);
    if (key.isEmpty) return Colors.grey.shade600;

    final exact = _regionColorMap[key];
    if (exact != null) return exact;

    // fallback seguro caso apareça alguma regional nova no futuro
    return const Color(0xFF78909C);
  }

  static Color colorForVsa(int? vsa) {
    switch (vsa) {
      case 1:
        return _vsaPalette[0];
      case 2:
        return _vsaPalette[1];
      case 3:
        return _vsaPalette[2];
      case 4:
        return _vsaPalette[3];
      case 5:
        return _vsaPalette[4];
      default:
        return Colors.grey.shade600;
    }
  }

  static List<Color> get vsaChartPalette =>
      List<Color>.unmodifiable(_vsaPalette);

  static Color colorForRegionBar({
    required String regionLabel,
    required double value,
    required bool selected,
  }) {
    if (value <= 0) return Colors.grey.shade300;

    final base = colorForRegion(regionLabel);
    if (selected) {
      return Color.lerp(base, Colors.black, 0.12) ?? base;
    }
    return base;
  }

  static Color colorForBarState({
    required Color baseColor,
    required double value,
    required bool isSelected,
    required bool hasSomeFilter,
    required bool isInFilter,
    required bool hasSelection,
    required bool isHighlighted,
  }) {
    if (value <= 0) {
      return baseColor.withValues(alpha: 0.20);
    }

    if (isSelected) {
      return _selectedBarOverlay;
    }

    if (hasSomeFilter && !isInFilter) {
      return baseColor.withValues(alpha: 0.20);
    }

    if (hasSelection) {
      return baseColor.withValues(alpha: 0.10);
    }

    if (isHighlighted) {
      return baseColor;
    }

    return baseColor;
  }

  static double _expScale(
      double zoom, {
        required double baseAtZ8,
        required double growth,
        required double min,
        required double max,
      }) {
    final value = baseAtZ8 * math.pow(growth, zoom - 8.0);
    return value.clamp(min, max).toDouble();
  }

  static double casingWidthForZoom(double zoom) {
    return _expScale(
      zoom,
      baseAtZ8: 2.6,
      growth: 1.30,
      min: 2.4,
      max: 14.0,
    );
  }

  static double centerLineWidthForZoom(double zoom) {
    return _expScale(
      zoom,
      baseAtZ8: 1.8,
      growth: 1.22,
      min: 1.6,
      max: 7.0,
    );
  }

  static double carriagewayOffsetPxForZoom(double zoom) {
    return _expScale(
      zoom,
      baseAtZ8: 1.7,
      growth: 1.45,
      min: 1.8,
      max: 13.0,
    );
  }

  static double medianWhiteWidthForZoom(double zoom) {
    return _expScale(
      zoom,
      baseAtZ8: 3.8,
      growth: 1.34,
      min: 3.6,
      max: 24.0,
    );
  }

  static double selectionHaloWidthForZoom(double zoom) {
    return _expScale(
      zoom,
      baseAtZ8: 0.9,
      growth: 1.18,
      min: 0.8,
      max: 3.0,
    );
  }

  static double degreesPerPixel(double latitude, double zoom) {
    return ActiveRoadsData.degreesPerPixel(latitude, zoom);
  }

  static bool isDualRoadSurface(String code) {
    final c = normalizeSurfaceCode(code);
    return c == 'DUP' || c == 'EOD';
  }

  static bool isCentralDashed(String code) {
    final c = normalizeSurfaceCode(code);
    return c == 'EOP' || c == 'EOI';
  }

  static bool leftTrackDashedForDual(String code) {
    return false;
  }

  static bool rightTrackDashedForDual(String code) {
    final c = normalizeSurfaceCode(code);
    return c == 'EOD';
  }

  static List<PolylineChangedData> buildRoadPolylines({
    required String id,
    required String code,
    required List<List<LatLng>> segments,
    required double zoom,
    required double centerLatitude,
    bool isSelected = false,
    bool detailsMode = false,
    Color? overrideColor,
  }) {
    if (segments.isEmpty) return const [];

    final normalizedCode = normalizeSurfaceCode(code);
    final statusColor = overrideColor ?? colorForSurface(normalizedCode);

    final isDualRoad = isDualRoadSurface(normalizedCode);

    final casingWidth = detailsMode
        ? math.max(3.8, casingWidthForZoom(zoom) * 1.10)
        : casingWidthForZoom(zoom);

    final centerWidth = detailsMode
        ? math.max(1.4, centerLineWidthForZoom(zoom) * 1.08)
        : centerLineWidthForZoom(zoom);

    final carriagewayOffsetPx = detailsMode
        ? carriagewayOffsetPxForZoom(zoom) * 1.08
        : carriagewayOffsetPxForZoom(zoom);

    final medianWhiteWidth = detailsMode
        ? medianWhiteWidthForZoom(zoom) * 1.08
        : medianWhiteWidthForZoom(zoom);

    final degPerPx = degreesPerPixel(centerLatitude, zoom);
    final carriagewayOffsetDeg = carriagewayOffsetPx * degPerPx;

    final out = <PolylineChangedData>[];

    void addTrack({
      required List<LatLng> centerTrack,
      required String suffix,
      required bool dashed,
      required bool interactive,
    }) {
      if (centerTrack.length < 2) return;

      final visibleColor =
      isSelected && !detailsMode ? _selectedRoadColor : statusColor;

      if (isSelected && !detailsMode) {
        out.add(
          PolylineChangedData(
            points: centerTrack,
            tag: interactive ? id : '${id}_color_$suffix',
            color: visibleColor,
            defaultColor: statusColor,
            strokeWidth: centerWidth,
            isDotted: dashed,
            useDashedPattern: true,
            dashSegmentLength: 5,
            dashGapLength: 2,
            patternFit: PatternFit.scaleUp,
            hitTestable: interactive,
          ),
        );
      }

      out.add(
        PolylineChangedData(
          points: centerTrack,
          tag: '${id}_casing_$suffix',
          color: Colors.white,
          defaultColor: Colors.white,
          strokeWidth: casingWidth,
          isDotted: false,
          hitTestable: false,
        ),
      );

      out.add(
        PolylineChangedData(
          points: centerTrack,
          tag: interactive ? id : '${id}_color_$suffix',
          color: visibleColor,
          defaultColor: statusColor,
          strokeWidth: centerWidth,
          isDotted: dashed,
          hitTestable: interactive,
        ),
      );
    }

    for (final seg in segments) {
      if (seg.length < 2) continue;

      if (isDualRoad) {
        out.add(
          PolylineChangedData(
            points: seg,
            tag: '${id}_median_white',
            color: Colors.white,
            defaultColor: Colors.white,
            strokeWidth: medianWhiteWidth,
            isDotted: false,
            hitTestable: false,
          ),
        );

        final leftTrack = ActiveRoadsData.deslocarPontos(
          seg,
          deslocamentoOrtogonal: -carriagewayOffsetDeg,
          miterLimit: 3.0,
          densifyIfSegmentMeters: 0,
        );

        final rightTrack = ActiveRoadsData.deslocarPontos(
          seg,
          deslocamentoOrtogonal: carriagewayOffsetDeg,
          miterLimit: 3.0,
          densifyIfSegmentMeters: 0,
        );

        addTrack(
          centerTrack: leftTrack,
          suffix: 'dual_left',
          dashed: leftTrackDashedForDual(normalizedCode),
          interactive: false,
        );

        addTrack(
          centerTrack: rightTrack,
          suffix: 'dual_right',
          dashed: rightTrackDashedForDual(normalizedCode),
          interactive: true,
        );
      } else {
        addTrack(
          centerTrack: seg,
          suffix: 'single',
          dashed: isCentralDashed(normalizedCode),
          interactive: true,
        );
      }
    }

    return out;
  }

  static List<PolylineChangedData> styleLane(String? status, double zoom) {
    final code = normalizeSurfaceCode(status);
    final color = colorForSurface(code);

    if (isDualRoadSurface(code)) {
      return [
        PolylineChangedData(
          points: const [],
          tag: null,
          color: Colors.white,
          defaultColor: Colors.white,
          strokeWidth: medianWhiteWidthForZoom(zoom),
          isDotted: false,
          hitTestable: false,
        ),
        PolylineChangedData(
          points: const [],
          tag: null,
          color: Colors.white,
          defaultColor: Colors.white,
          strokeWidth: casingWidthForZoom(zoom),
          isDotted: false,
          hitTestable: false,
        ),
        PolylineChangedData(
          points: const [],
          tag: null,
          color: color,
          defaultColor: color,
          strokeWidth: centerLineWidthForZoom(zoom),
          isDotted: false,
          hitTestable: false,
        ),
        PolylineChangedData(
          points: const [],
          tag: null,
          color: Colors.white,
          defaultColor: Colors.white,
          strokeWidth: casingWidthForZoom(zoom),
          isDotted: false,
          hitTestable: false,
        ),
        PolylineChangedData(
          points: const [],
          tag: null,
          color: color,
          defaultColor: color,
          strokeWidth: centerLineWidthForZoom(zoom),
          isDotted: code == 'EOD',
          hitTestable: false,
        ),
      ];
    }

    return [
      PolylineChangedData(
        points: const [],
        tag: null,
        color: Colors.white,
        defaultColor: Colors.white,
        strokeWidth: casingWidthForZoom(zoom),
        isDotted: false,
        hitTestable: false,
      ),
      PolylineChangedData(
        points: const [],
        tag: null,
        color: color,
        defaultColor: color,
        strokeWidth: centerLineWidthForZoom(zoom),
        isDotted: isCentralDashed(code),
        hitTestable: false,
      ),
    ];
  }
}