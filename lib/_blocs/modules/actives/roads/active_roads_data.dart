import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_utils/geometry/sipged_geo_math.dart';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'package:sipged/_blocs/modules/actives/roads/active_roads_style.dart';
import 'package:sipged/_utils/geometry/sipged_geo_math.dart';
import 'package:sipged/_widgets/map/polylines/polyline_changed_data.dart';

@immutable
class RoadViewField {
  final String label;
  final String value;

  const RoadViewField({
    required this.label,
    required this.value,
  });
}

class ActiveRoadsData {
  final String? id;

  final String? acronym;
  final String? uf;
  final String? segmentType;
  final String? descCoin;
  final String? roadCode;
  final String? initialSegment;
  final String? finalSegment;
  final double? initialKm;
  final double? finalKm;
  final double? extension;
  final String? stateSurface;
  final String? works;
  final String? coincidentFederal;
  final String? administration;
  final String? legalAct;
  final String? coincidentState;
  final String? coincidentStateSurface;
  final String? jurisdiction;
  final String? surface;
  final String? unitLocal;
  final String? coincident;
  final String? initialLatSegment;
  final String? initialLongSegment;
  final String? finalLatSegment;
  final String? finalLongSegment;
  final String? regional;
  final String? previousNumber;
  final String? revestmentType;
  final int? tmd;
  final int? tracksNumber;
  final int? maximumSpeed;
  final String? conservationCondition;
  final String? drainage;
  final int? vsa;
  final String? roadName;
  final String? state;
  final String? direction;
  final String? managingAgency;
  final String? description;
  final Map<String, dynamic>? metadata;
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;

  final List<LatLng>? points;

  const ActiveRoadsData({
    this.id,
    this.acronym,
    this.uf,
    this.segmentType,
    this.descCoin,
    this.roadCode,
    this.initialSegment,
    this.finalSegment,
    this.initialKm,
    this.finalKm,
    this.extension,
    this.stateSurface,
    this.works,
    this.coincidentFederal,
    this.administration,
    this.legalAct,
    this.coincidentState,
    this.coincidentStateSurface,
    this.jurisdiction,
    this.surface,
    this.unitLocal,
    this.coincident,
    this.initialLatSegment,
    this.initialLongSegment,
    this.finalLatSegment,
    this.finalLongSegment,
    this.regional,
    this.previousNumber,
    this.revestmentType,
    this.tmd,
    this.tracksNumber,
    this.maximumSpeed,
    this.conservationCondition,
    this.drainage,
    this.vsa,
    this.roadName,
    this.state,
    this.direction,
    this.managingAgency,
    this.description,
    this.metadata,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.points,
  });

  factory ActiveRoadsData.fromDocument(DocumentSnapshot snapshot) {
    if (!snapshot.exists) {
      throw Exception('Documento não encontrado');
    }

    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Dados estão vazios');
    }

    return ActiveRoadsData.fromMap(data, id: snapshot.id);
  }

  factory ActiveRoadsData.fromMap(Map<String, dynamic> map, {String? id}) {
    return ActiveRoadsData(
      id: id ?? map['id']?.toString(),
      acronym: map['acronym']?.toString(),
      uf: map['uf']?.toString(),
      segmentType: map['segmentType']?.toString(),
      descCoin: map['descCoin']?.toString(),
      roadCode: map['roadCode']?.toString(),
      initialSegment: map['initialSegment']?.toString(),
      finalSegment: map['finalSegment']?.toString(),
      initialKm: _toDouble(map['initialKm']),
      finalKm: _toDouble(map['finalKm']),
      extension: _toDouble(map['extension']),
      stateSurface: map['stateSurface']?.toString(),
      works: map['works']?.toString(),
      coincidentFederal: map['coincidentFederal']?.toString(),
      administration: map['administration']?.toString(),
      legalAct: map['legalAct']?.toString(),
      coincidentState: map['coincidentState']?.toString(),
      coincidentStateSurface: map['coincidentStateSurface']?.toString(),
      jurisdiction: map['jurisdiction']?.toString(),
      surface: map['surface']?.toString(),
      unitLocal: map['unitLocal']?.toString(),
      coincident: map['coincident']?.toString(),
      initialLatSegment: map['initialLatSegment']?.toString(),
      initialLongSegment: map['initialLongSegment']?.toString(),
      finalLatSegment: map['finalLatSegment']?.toString(),
      finalLongSegment: map['finalLongSegment']?.toString(),
      regional: map['regional']?.toString(),
      previousNumber: map['previousNumber']?.toString(),
      revestmentType: map['revestmentType']?.toString(),
      tmd: _toInt(map['tmd']),
      tracksNumber: _toInt(map['tracksNumber']),
      maximumSpeed: _toInt(map['maximumSpeed']),
      conservationCondition: map['conservationCondition']?.toString(),
      drainage: map['drainage']?.toString(),
      vsa: _toInt(map['vsa']),
      roadName: map['roadName']?.toString(),
      state: map['state']?.toString(),
      direction: map['direction']?.toString(),
      managingAgency: map['managingAgency']?.toString(),
      description: map['description']?.toString(),
      metadata: map['metadata'] is Map<String, dynamic>
          ? map['metadata'] as Map<String, dynamic>
          : null,
      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy']?.toString(),
      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy']?.toString(),
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy']?.toString(),
      points: _parsePoints(map['points']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'acronym': acronym,
      'uf': uf,
      'segmentType': segmentType,
      'descCoin': descCoin,
      'roadCode': roadCode,
      'initialSegment': initialSegment,
      'finalSegment': finalSegment,
      'initialKm': initialKm,
      'finalKm': finalKm,
      'extension': extension,
      'stateSurface': stateSurface,
      'works': works,
      'coincidentFederal': coincidentFederal,
      'administration': administration,
      'legalAct': legalAct,
      'coincidentState': coincidentState,
      'coincidentStateSurface': coincidentStateSurface,
      'jurisdiction': jurisdiction,
      'surface': surface,
      'unitLocal': unitLocal,
      'coincident': coincident,
      'initialLatSegment': initialLatSegment,
      'initialLongSegment': initialLongSegment,
      'finalLatSegment': finalLatSegment,
      'finalLongSegment': finalLongSegment,
      'regional': regional,
      'previousNumber': previousNumber,
      'revestmentType': revestmentType,
      'tmd': tmd,
      'tracksNumber': tracksNumber,
      'maximumSpeed': maximumSpeed,
      'conservationCondition': conservationCondition,
      'drainage': drainage,
      'vsa': vsa,
      'roadName': roadName,
      'state': state,
      'direction': direction,
      'managingAgency': managingAgency,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt,
      'deletedBy': deletedBy,
      'points': points
          ?.map((p) => GeoPoint(p.latitude, p.longitude))
          .toList(growable: false),
    };
  }

  ActiveRoadsData copyWith({
    String? id,
    String? acronym,
    String? uf,
    String? segmentType,
    String? descCoin,
    String? roadCode,
    String? initialSegment,
    String? finalSegment,
    double? initialKm,
    double? finalKm,
    double? extension,
    String? stateSurface,
    String? works,
    String? coincidentFederal,
    String? administration,
    String? legalAct,
    String? coincidentState,
    String? coincidentStateSurface,
    String? jurisdiction,
    String? surface,
    String? unitLocal,
    String? coincident,
    String? initialLatSegment,
    String? initialLongSegment,
    String? finalLatSegment,
    String? finalLongSegment,
    String? regional,
    String? previousNumber,
    String? revestmentType,
    int? tmd,
    int? tracksNumber,
    int? maximumSpeed,
    String? conservationCondition,
    String? drainage,
    int? vsa,
    String? roadName,
    String? state,
    String? direction,
    String? managingAgency,
    String? description,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    List<LatLng>? points,
  }) {
    return ActiveRoadsData(
      id: id ?? this.id,
      acronym: acronym ?? this.acronym,
      uf: uf ?? this.uf,
      segmentType: segmentType ?? this.segmentType,
      descCoin: descCoin ?? this.descCoin,
      roadCode: roadCode ?? this.roadCode,
      initialSegment: initialSegment ?? this.initialSegment,
      finalSegment: finalSegment ?? this.finalSegment,
      initialKm: initialKm ?? this.initialKm,
      finalKm: finalKm ?? this.finalKm,
      extension: extension ?? this.extension,
      stateSurface: stateSurface ?? this.stateSurface,
      works: works ?? this.works,
      coincidentFederal: coincidentFederal ?? this.coincidentFederal,
      administration: administration ?? this.administration,
      legalAct: legalAct ?? this.legalAct,
      coincidentState: coincidentState ?? this.coincidentState,
      coincidentStateSurface:
      coincidentStateSurface ?? this.coincidentStateSurface,
      jurisdiction: jurisdiction ?? this.jurisdiction,
      surface: surface ?? this.surface,
      unitLocal: unitLocal ?? this.unitLocal,
      coincident: coincident ?? this.coincident,
      initialLatSegment: initialLatSegment ?? this.initialLatSegment,
      initialLongSegment: initialLongSegment ?? this.initialLongSegment,
      finalLatSegment: finalLatSegment ?? this.finalLatSegment,
      finalLongSegment: finalLongSegment ?? this.finalLongSegment,
      regional: regional ?? this.regional,
      previousNumber: previousNumber ?? this.previousNumber,
      revestmentType: revestmentType ?? this.revestmentType,
      tmd: tmd ?? this.tmd,
      tracksNumber: tracksNumber ?? this.tracksNumber,
      maximumSpeed: maximumSpeed ?? this.maximumSpeed,
      conservationCondition:
      conservationCondition ?? this.conservationCondition,
      drainage: drainage ?? this.drainage,
      vsa: vsa ?? this.vsa,
      roadName: roadName ?? this.roadName,
      state: state ?? this.state,
      direction: direction ?? this.direction,
      managingAgency: managingAgency ?? this.managingAgency,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      points: points ?? this.points,
    );
  }

  String get displayRegion =>
      regional?.trim().isNotEmpty == true
          ? regional!.trim()
          : (metadata?['regional']?.toString().trim() ?? '');

  String get surfaceCode =>
      ActiveRoadsStyle.normalizeSurfaceCode(
        stateSurface ?? surface ?? state ?? '',
      );

  String get surfaceLabel => ActiveRoadsStyle.labelForSurface(surfaceCode);

  bool get hasGeometry => points != null && points!.length >= 2;

  LatLng? get startLatLng {
    final lat = double.tryParse((initialLatSegment ?? '').replaceAll(',', '.'));
    final lng =
    double.tryParse((initialLongSegment ?? '').replaceAll(',', '.'));

    if (lat != null && lng != null) return LatLng(lat, lng);
    if (points != null && points!.isNotEmpty) return points!.first;
    return null;
  }

  LatLng? get endLatLng {
    final lat = double.tryParse((finalLatSegment ?? '').replaceAll(',', '.'));
    final lng =
    double.tryParse((finalLongSegment ?? '').replaceAll(',', '.'));

    if (lat != null && lng != null) return LatLng(lat, lng);
    if (points != null && points!.isNotEmpty) return points!.last;
    return null;
  }

  LatLng? get centerLatLng {
    final ps = points;
    if (ps != null && ps.isNotEmpty) {
      double lat = 0;
      double lng = 0;

      for (final p in ps) {
        lat += p.latitude;
        lng += p.longitude;
      }

      return LatLng(lat / ps.length, lng / ps.length);
    }

    final a = startLatLng;
    final b = endLatLng;
    if (a != null && b != null) {
      return LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );
    }

    return a ?? b;
  }

  LatLng? projectOnPolyline(LatLng p) {
    final ps = points;
    if (ps == null || ps.length < 2) return null;

    final meanLat =
        ps.fold<double>(0.0, (acc, e) => acc + e.latitude) / ps.length;

    const metersPerDegLat = 111320.0;
    final metersPerDegLng =
        111320.0 * math.cos(SipGedGeoMath.degToRad(meanLat));

    Offset toMeters(LatLng ll) =>
        Offset(ll.longitude * metersPerDegLng, ll.latitude * metersPerDegLat);

    LatLng toLatLng(Offset m) =>
        LatLng(m.dy / metersPerDegLat, m.dx / metersPerDegLng);

    final projectedTap = toMeters(p);

    double bestDistance = double.infinity;
    Offset? bestProjection;

    for (int i = 0; i < ps.length - 1; i++) {
      final a = toMeters(ps[i]);
      final b = toMeters(ps[i + 1]);
      final proj = _projectPointOnSegment(projectedTap, a, b);
      final dist = (proj - projectedTap).distance;

      if (dist < bestDistance) {
        bestDistance = dist;
        bestProjection = proj;
      }
    }

    if (bestProjection == null) return null;
    return toLatLng(bestProjection);
  }

  LatLng? anchorForTap(LatLng? tap) {
    final fallback =
        tap ?? centerLatLng ?? startLatLng ?? endLatLng ?? const LatLng(0, 0);

    return projectOnPolyline(fallback) ??
        centerLatLng ??
        startLatLng ??
        endLatLng;
  }

  List<RoadViewField> get detailsFields {
    String fmtNum(num? v, {int maxDecimals = 2}) {
      if (v == null) return '';
      var s = v.toStringAsFixed(maxDecimals);
      while (s.contains('.') && (s.endsWith('0') || s.endsWith('.'))) {
        s = s.substring(0, s.length - 1);
      }
      return s;
    }

    final items = <RoadViewField>[
      RoadViewField(label: 'Tipo de Segmento', value: segmentType ?? ''),
      RoadViewField(label: 'Código da Rodovia', value: roadCode ?? ''),
      RoadViewField(label: 'Sigla da Rodovia', value: acronym ?? ''),
      RoadViewField(label: 'Gerência Regional', value: displayRegion),
      RoadViewField(label: 'Início do Segmento', value: initialSegment ?? ''),
      RoadViewField(label: 'Fim do Segmento', value: finalSegment ?? ''),
      RoadViewField(label: 'Início do Km', value: fmtNum(initialKm)),
      RoadViewField(label: 'Fim do Km', value: fmtNum(finalKm)),
      RoadViewField(label: 'Extensão', value: fmtNum(extension)),
      RoadViewField(label: 'Tipo de Superfície', value: stateSurface ?? ''),
      RoadViewField(
        label: 'Tipo de Revestimento',
        value: revestmentType ?? '',
      ),
      RoadViewField(label: 'VSA', value: vsa?.toString() ?? ''),
      RoadViewField(label: 'TMD', value: tmd?.toString() ?? ''),
      RoadViewField(label: 'Estado', value: uf ?? ''),
      RoadViewField(label: 'Administração', value: administration ?? ''),
      RoadViewField(label: 'Jurisdição', value: jurisdiction ?? ''),
      RoadViewField(label: 'Obras', value: works ?? ''),
      RoadViewField(
        label: 'Federal Coincidente',
        value: coincidentFederal ?? '',
      ),
      RoadViewField(label: 'Ato legal', value: legalAct ?? ''),
      RoadViewField(
        label: 'Rod. Estadual Coincidente',
        value: coincidentState ?? '',
      ),
      RoadViewField(
        label: 'Coincident State Surface',
        value: coincidentStateSurface ?? '',
      ),
      RoadViewField(label: 'Superfície', value: surface ?? ''),
      RoadViewField(label: 'Unidade Local', value: unitLocal ?? ''),
      RoadViewField(label: 'Coincidente', value: coincident ?? ''),
      RoadViewField(
        label: 'Latitude inicial do Segmento',
        value: initialLatSegment ?? '',
      ),
      RoadViewField(
        label: 'Longitude inicial do Segmento',
        value: initialLongSegment ?? '',
      ),
      RoadViewField(
        label: 'Latitude final do Segmento',
        value: finalLatSegment ?? '',
      ),
      RoadViewField(
        label: 'Longitude final do Segmento',
        value: finalLongSegment ?? '',
      ),
      RoadViewField(label: 'Número Anterior', value: previousNumber ?? ''),
      RoadViewField(
        label: 'Número de faixas',
        value: tracksNumber?.toString() ?? '',
      ),
      RoadViewField(
        label: 'Velocidade máxima',
        value: maximumSpeed?.toString() ?? '',
      ),
      RoadViewField(
        label: 'Condição de conservação',
        value: conservationCondition ?? '',
      ),
      RoadViewField(label: 'Drenagem', value: drainage ?? ''),
      RoadViewField(label: 'Nome da Rodovia', value: roadName ?? ''),
      RoadViewField(label: 'Estado', value: state ?? ''),
      RoadViewField(label: 'Descrição', value: description ?? ''),
      RoadViewField(label: 'Metadata', value: metadata?.toString() ?? ''),
    ];

    return items.where((e) => e.value.trim().isNotEmpty).toList(growable: false);
  }

  double get idealDetailMapZoom => computeIdealZoom(points ?? const []);

  List<PolylineChangedData> buildDetailPolylines({
    required double zoom,
    required double centerLatitude,
  }) {
    final ps = points;
    if (ps == null || ps.length < 2) return const [];

    return ActiveRoadsStyle.buildRoadPolylines(
      id: id ?? '',
      code: surfaceCode,
      segments: [ps],
      zoom: zoom,
      centerLatitude: centerLatitude,
      isSelected: false,
      detailsMode: true,
    );
  }

  List<MapEntry<String, String>> toEntries() {
    return [
      MapEntry('Rodovia', acronym ?? ''),
      MapEntry('UF', uf ?? ''),
      MapEntry('Extensão', extension?.toStringAsFixed(2) ?? '--'),
      MapEntry('Pontos', points?.length.toString() ?? ''),
      MapEntry('ID', id ?? ''),
    ];
  }

  static Map<String, List<ActiveRoadsData>> groupByAcronym(
      List<ActiveRoadsData> list,
      ) {
    final map = <String, List<ActiveRoadsData>>{};

    for (final r in list) {
      final key = (r.acronym ?? 'SEM SIGLA').trim().toUpperCase();
      map.putIfAbsent(key, () => <ActiveRoadsData>[]).add(r);
    }

    for (final entry in map.entries) {
      entry.value.sort((a, b) {
        final aKey = '${a.uf ?? ''}${a.roadCode ?? ''}'.toUpperCase();
        final bKey = '${b.uf ?? ''}${b.roadCode ?? ''}'.toUpperCase();
        return aKey.compareTo(bKey);
      });
    }

    return map;
  }

  static num sumExtension(Iterable<ActiveRoadsData> items) {
    return items.fold<num>(0, (sum, r) => sum + (r.extension ?? 0));
  }

  static double computeIdealZoom(List<LatLng> pts) {
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

    if (delta < 0.002) return 17.0;
    if (delta < 0.01) return 16.0;
    if (delta < 0.05) return 15.0;
    if (delta < 0.15) return 14.0;
    if (delta < 0.50) return 13.0;
    if (delta < 1.00) return 12.0;
    return 11.0;
  }

  static bool isDupla(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    return c == 'DUP' || c == 'EOD';
  }

  static bool isTracejada(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    return c == 'EOD' || c == 'EOP';
  }

  static double laneWidthForZoom(double zoom) {
    final w = 1.00 * math.pow(1.24, zoom - 8.0);
    return w.clamp(1.0, 4.2).toDouble();
  }

  static double laneSeparationPxForZoom(double zoom) {
    final s = 1.60 * math.pow(1.45, zoom - 8.0);
    return s.clamp(1.8, 13.0).toDouble();
  }

  static double degreesPerPixel(double latitude, double zoom) {
    final mpp = 156543.03392 *
        math.cos(SipGedGeoMath.degToRad(latitude)) /
        math.pow(2.0, zoom);
    return mpp / 111320.0;
  }

  static List<LatLng> deslocarPontos(
      List<LatLng> pts, {
        required double deslocamentoOrtogonal,
        double miterLimit = 3.0,
        double densifyIfSegmentMeters = 0,
      }) {
    if (pts.length < 2 || deslocamentoOrtogonal.abs() < 1e-12) return pts;

    final latMean =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;

    final cosLat = math.cos(SipGedGeoMath.degToRad(latMean));

    const metersPerDegLat = 111320.0;
    final metersPerDegLng = 111320.0 * cosLat;

    List<_PointM> toMeters(List<LatLng> source) => source
        .map((p) => _PointM(
      p.longitude * metersPerDegLng,
      p.latitude * metersPerDegLat,
    ))
        .toList(growable: false);

    List<LatLng> toLatLng(List<_PointM> source) => source
        .map((p) => LatLng(
      p.y / metersPerDegLat,
      p.x / metersPerDegLng,
    ))
        .toList(growable: false);

    List<_PointM> densify(List<_PointM> src, double maxSegMeters) {
      if (maxSegMeters <= 0) return src;

      final out = <_PointM>[];
      for (int i = 0; i < src.length - 1; i++) {
        final a = src[i];
        final b = src[i + 1];
        out.add(a);

        final dx = b.x - a.x;
        final dy = b.y - a.y;
        final len = math.sqrt(dx * dx + dy * dy);
        final steps = (len / maxSegMeters).floor();

        if (steps > 1) {
          for (int k = 1; k < steps; k++) {
            final t = k / steps;
            out.add(_PointM(a.x + dx * t, a.y + dy * t));
          }
        }
      }

      out.add(src.last);
      return out;
    }

    final offsetMeters = deslocamentoOrtogonal * metersPerDegLat;

    var meters = toMeters(pts);
    if (densifyIfSegmentMeters > 0) {
      meters = densify(meters, densifyIfSegmentMeters);
    }

    final segmentNormals = <_PointM>[];
    for (int i = 0; i < meters.length - 1; i++) {
      final a = meters[i];
      final b = meters[i + 1];
      final vx = b.x - a.x;
      final vy = b.y - a.y;
      final len = math.sqrt(vx * vx + vy * vy);

      if (len < 1e-12) {
        segmentNormals.add(const _PointM(0, 0));
      } else {
        segmentNormals.add(_PointM(-vy / len, vx / len));
      }
    }

    final out = <_PointM>[];
    for (int i = 0; i < meters.length; i++) {
      late _PointM offset;

      if (i == 0) {
        final n = segmentNormals[0];
        offset = _PointM(n.x * offsetMeters, n.y * offsetMeters);
      } else if (i == meters.length - 1) {
        final n = segmentNormals[segmentNormals.length - 1];
        offset = _PointM(n.x * offsetMeters, n.y * offsetMeters);
      } else {
        final n1 = segmentNormals[i - 1];
        final n2 = segmentNormals[i];

        var tx = n1.x + n2.x;
        var ty = n1.y + n2.y;
        var tlen = math.sqrt(tx * tx + ty * ty);

        if (tlen < 1e-9) {
          tx = n2.x;
          ty = n2.y;
          tlen = 1.0;
        }

        tx /= tlen;
        ty /= tlen;

        final dot = tx * n1.x + ty * n1.y;
        final gain = (dot.abs() < 1e-3) ? miterLimit : (1.0 / dot).abs();
        final k = math.min(gain, miterLimit);

        offset = _PointM(tx * offsetMeters * k, ty * offsetMeters * k);
      }

      out.add(_PointM(meters[i].x + offset.x, meters[i].y + offset.y));
    }

    return toLatLng(out);
  }

  static String getStatusSurface(String status) {
    switch (status.trim().toUpperCase()) {
      case 'DUP':
        return 'DUPLICADA';
      case 'EOD':
        return 'EM OBRA DE DUPLICAÇÃO';
      case 'PAV':
        return 'PAVIMENTADA';
      case 'EOP':
        return 'EM OBRAS DE PAVIMENTAÇÃO';
      case 'IMP':
        return 'IMPLANTADA';
      case 'EOI':
        return 'EM OBRAS DE IMPLANTAÇÃO';
      case 'LEN':
        return 'LEITO NATURAL';
      case 'PLA':
        return 'PLANEJADA';
      default:
        return 'OUTRO';
    }
  }
}

class _PointM {
  final double x;
  final double y;

  const _PointM(this.x, this.y);
}

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.'));
  return null;
}

int? _toInt(dynamic value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

List<LatLng>? _parsePoints(dynamic value) {
  if (value is! List) return null;

  return value
      .map<LatLng?>((e) {
    if (e is GeoPoint) {
      return LatLng(e.latitude, e.longitude);
    }

    if (e is Map && e['lat'] != null && e['lng'] != null) {
      return LatLng(
        (e['lat'] as num).toDouble(),
        (e['lng'] as num).toDouble(),
      );
    }

    if (e is Map && e['latitude'] != null && e['longitude'] != null) {
      return LatLng(
        (e['latitude'] as num).toDouble(),
        (e['longitude'] as num).toDouble(),
      );
    }

    return null;
  })
      .whereType<LatLng>()
      .toList(growable: false);
}

Offset _projectPointOnSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;

  if (ab2 == 0) return a;

  final ap = p - a;
  var t = (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
  t = t.clamp(0.0, 1.0);

  return Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
}