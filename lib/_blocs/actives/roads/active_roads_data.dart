import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:siged/_utils/math/math_utils.dart';

class ActiveRoadsData extends ChangeNotifier {
  late final String? id;

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

  ActiveRoadsData({
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

  /// Cria a partir de snapshot do Firebase
  factory ActiveRoadsData.fromDocument(DocumentSnapshot snapshot) {
    if (!snapshot.exists) throw Exception("Documento não encontrado");
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) throw Exception("Dados estão vazios");
    return ActiveRoadsData.fromMap(data, id: snapshot.id);
  }

  /// Cria a partir de um map genérico (ex.: network)
  factory ActiveRoadsData.fromMap(Map<String, dynamic> map, {String? id}) {
    return ActiveRoadsData(
      id: id ?? map['id'],
      acronym: map['acronym'],
      uf: map['uf'],
      segmentType: map['segmentType'],
      descCoin: map['descCoin'],
      roadCode: map['roadCode'],
      initialSegment: map['initialSegment'],
      finalSegment: map['finalSegment'],
      initialKm: _toDouble(map['initialKm']),
      finalKm: _toDouble(map['finalKm']),
      extension: _toDouble(map['extension']),
      stateSurface: map['stateSurface'],
      works: map['works'],
      coincidentFederal: map['coincidentFederal'],
      administration: map['administration'],
      legalAct: map['legalAct'],
      coincidentState: map['coincidentState'],
      coincidentStateSurface: map['coincidentStateSurface'],
      jurisdiction: map['jurisdiction'],
      surface: map['surface'],
      unitLocal: map['unitLocal'],
      coincident: map['coincident'],
      initialLatSegment: map['initialLatSegment'],
      initialLongSegment: map['initialLongSegment'],
      finalLatSegment: map['finalLatSegment'],
      finalLongSegment: map['finalLongSegment'],
      regional: map['regional'],
      previousNumber: map['previousNumber'],
      revestmentType: map['revestmentType'],
      tmd: _toInt(map['tmd']),
      tracksNumber: _toInt(map['tracksNumber']),
      maximumSpeed: _toInt(map['maximumSpeed']),
      conservationCondition: map['conservationCondition'],
      drainage: map['drainage'],
      vsa: _toInt(map['vsa']),
      roadName: map['roadName'],
      state: map['state'],
      direction: map['direction'],
      managingAgency: map['managingAgency'],
      description: map['description'],
      metadata: (map['metadata'] is Map<String, dynamic>)
          ? map['metadata'] as Map<String, dynamic>
          : null,
      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
      points: _parsePoints(map['points']),
    );
  }

  /// Serializa para Firestore
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
      'points':
      points?.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
    };
  }

  // ===========================================================================
  // Rótulos
  // ===========================================================================
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

  // ===========================================================================
  // LÓGICA DA LEGENDA (tipo de linha)
  // ===========================================================================
  /// DUP/EOD = duas pistas; PAV/EOP = uma pista
  static bool isDupla(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    return c == 'DUP' || c == 'EOD';
  }

  /// EOD/EOP = tracejada; DUP/PAV = contínua
  static bool isTracejada(String? code) {
    final c = (code ?? '').toUpperCase().trim();
    return c == 'EOD' || c == 'EOP';
  }

  // ===========================================================================
  // ESCALAS COM O ZOOM
  // ===========================================================================
  /// largura (px) de uma pista
  static double laneWidthForZoom(double zoom) {
    final w =
        1.15 * math.pow(1.36, zoom - 8); // ~1.2(z8) → ~2.6(z12) → ~5.2(z16)
    return w.clamp(1.0, 6.2).toDouble();
  }

  /// separação (px) entre as duas pistas
  static double laneSeparationPxForZoom(double zoom) {
    final s =
        0.95 * math.pow(1.58, zoom - 10); // ~1.7(z10) → ~4.4(z13) → ~11.6(z16)
    return s.clamp(1.6, 12.5).toDouble();
  }

  /// quantos graus valem 1 px nesse centro/zoom (aprox.)
  static double degreesPerPixel(double latitude, double zoom) {
    final mpp = 156543.03392 *
        math.cos(latitude * math.pi / 180.0) /
        math.pow(2.0, zoom);
    return mpp / 111_320.0;
  }

  // ===========================================================================
  // OFFSET PARALELO (sem "dobras")
  // ===========================================================================
  /// Desloca uma polyline **paralelamente** `deslocamentoOrtogonal` graus (lado esquerdo negativo).
  /// Usa junções com limite de mitra e opcional densificação para curvas discretizadas.
  static List<LatLng> deslocarPontos(
      List<LatLng> pts, {
        required double deslocamentoOrtogonal, // em graus!
        double miterLimit = 3.0,
        double densifyIfSegmentMeters = 0,
      }) {
    if (pts.length < 2 || deslocamentoOrtogonal.abs() < 1e-12) return pts;

    // Conversão LatLng <-> metros (plano local)
    final latMean =
        pts.map((p) => p.latitude).reduce((a, b) => a + b) / pts.length;
    final cosLat = math.cos(latMean * math.pi / 180.0);
    const mPerDegLat = 111_320.0;
    final mPerDegLng = 111_320.0 * cosLat;

    List<_P> toM(List<LatLng> s) =>
        s.map((p) => _P(p.longitude * mPerDegLng, p.latitude * mPerDegLat)).toList();
    List<LatLng> toLL(List<_P> s) =>
        s.map((p) => LatLng(p.y / mPerDegLat, p.x / mPerDegLng)).toList();

    // densify opcional
    List<_P> densify(List<_P> src, double maxSegMeters) {
      if (maxSegMeters <= 0) return src;
      final out = <_P>[];
      for (int i = 0; i < src.length - 1; i++) {
        final a = src[i], b = src[i + 1];
        out.add(a);
        final dx = b.x - a.x, dy = b.y - a.y;
        final len = math.sqrt(dx * dx + dy * dy);
        final nSteps = (len / maxSegMeters).floor();
        if (nSteps > 1) {
          for (int k = 1; k < nSteps; k++) {
            final t = k / nSteps;
            out.add(_P(a.x + dx * t, a.y + dy * t));
          }
        }
      }
      out.add(src.last);
      return out;
    }

    // graus -> metros
    final dMeters = deslocamentoOrtogonal * mPerDegLat;

    var m = toM(pts);
    if (densifyIfSegmentMeters > 0) m = densify(m, densifyIfSegmentMeters);

    // normais por segmento
    final segNormals = <_P>[];
    for (int i = 0; i < m.length - 1; i++) {
      final a = m[i], b = m[i + 1];
      final vx = b.x - a.x, vy = b.y - a.y;
      final len = math.sqrt(vx * vx + vy * vy);
      if (len < 1e-12) {
        segNormals.add(const _P(0, 0));
      } else {
        segNormals.add(_P(-vy / len, vx / len)); // 90° esq
      }
    }

    // offset ponto a ponto com mitra
    final out = <_P>[];
    for (int i = 0; i < m.length; i++) {
      late _P off;
      if (i == 0) {
        final n = segNormals[0];
        off = _P(n.x * dMeters, n.y * dMeters);
      } else if (i == m.length - 1) {
        final n = segNormals[segNormals.length - 1];
        off = _P(n.x * dMeters, n.y * dMeters);
      } else {
        final n1 = segNormals[i - 1];
        final n2 = segNormals[i];
        var tx = n1.x + n2.x, ty = n1.y + n2.y;
        var tlen = math.sqrt(tx * tx + ty * ty);
        if (tlen < 1e-9) {
          tx = n2.x;
          ty = n2.y;
          tlen = 1.0;
        }
        tx /= tlen;
        ty /= tlen;
        final dot = tx * n1.x + ty * n1.y; // cos(theta/2)
        final gain = (dot.abs() < 1e-3) ? miterLimit : (1.0 / dot).abs();
        final k = math.min(gain, miterLimit);
        off = _P(tx * dMeters * k, ty * dMeters * k);
      }
      out.add(_P(m[i].x + off.x, m[i].y + off.y));
    }

    return toLL(out);
  }
}

class _P {
  final double x, y;
  const _P(this.x, this.y);
}

/// ----------------- HELPERS -----------------

double? _toDouble(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
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
  if (value is List) {
    return value.map<LatLng?>((e) {
      if (e is GeoPoint) {
        return LatLng(e.latitude, e.longitude);
      }
      if (e is Map && e['lat'] != null && e['lng'] != null) {
        return LatLng(
          (e['lat'] as num).toDouble(),
          (e['lng'] as num).toDouble(),
        );
      }
      return null;
    }).whereType<LatLng>().toList();
  }
  return null;
}

/// ----------------- EXTENSIONS ÚTEIS -----------------

extension RoadDataExtensions on ActiveRoadsData {
  /// Ponto inicial (pelos campos de lat/long) – se existirem.
  LatLng? get startLatLng {
    final lat =
    double.tryParse((initialLatSegment ?? '').replaceAll(',', '.'));
    final lng =
    double.tryParse((initialLongSegment ?? '').replaceAll(',', '.'));
    if (lat != null && lng != null) return LatLng(lat, lng);
    return (points != null && points!.isNotEmpty) ? points!.first : null;
  }

  /// Ponto final (pelos campos de lat/long) – se existirem.
  LatLng? get endLatLng {
    final lat =
    double.tryParse((finalLatSegment ?? '').replaceAll(',', '.'));
    final lng =
    double.tryParse((finalLongSegment ?? '').replaceAll(',', '.'));
    if (lat != null && lng != null) return LatLng(lat, lng);
    return (points != null && points!.isNotEmpty) ? points!.last : null;
  }

  /// Centro geométrico simples (média dos pontos) – se houver polyline.
  LatLng? get centerLatLng {
    final ps = points;
    if (ps != null && ps.isNotEmpty) {
      double lat = 0, lng = 0;
      for (final p in ps) {
        lat += p.latitude;
        lng += p.longitude;
      }
      return LatLng(lat / ps.length, lng / ps.length);
    }
    // sem polyline? tenta média do início/fim
    final a = startLatLng, b = endLatLng;
    if (a != null && b != null) {
      return LatLng(
        (a.latitude + b.latitude) / 2,
        (a.longitude + b.longitude) / 2,
      );
    }
    return a ?? b;
  }

  /// Calcula a projeção do ponto P sobre a polyline (ponto mais próximo na linha).
  /// Retorna null se não houver polyline suficiente.
  LatLng? projectOnPolyline(LatLng p) {
    final ps = points;
    if (ps == null || ps.length < 2) return null;

    // Converte para “metros” aproximados para distância euclidiana
    final meanLat =
        ps.fold<double>(0.0, (acc, e) => acc + e.latitude) / ps.length;
    const mPerDegLat = 111320.0;
    final mPerDegLng = 111320.0 * (MathUtils.cosDeg(meanLat));
    Offset toM(LatLng ll) => Offset(ll.longitude * mPerDegLng, ll.latitude * mPerDegLat);
    LatLng toLL(Offset m) => LatLng(m.dy / mPerDegLat, m.dx / mPerDegLng);

    final P = toM(p);
    double bestDist = double.infinity;
    Offset? best;

    for (int i = 0; i < ps.length - 1; i++) {
      final a = toM(ps[i]);
      final b = toM(ps[i + 1]);
      final proj = _projectPointOnSegment(P, a, b);
      final d = (proj - P).distance;
      if (d < bestDist) {
        bestDist = d;
        best = proj;
      }
    }

    if (best == null) return null;
    return toLL(best);
  }

  /// Escolhe a melhor âncora para o tooltip dado um toque.
  /// 1) projeção do toque na linha; 2) centro; 3) início; 4) fim.
  LatLng? anchorForTap(LatLng? tap) {
    return projectOnPolyline(
      tap ?? centerLatLng ?? startLatLng ?? endLatLng ?? const LatLng(0, 0),
    ) ??
        centerLatLng ??
        startLatLng ??
        endLatLng;
  }

  List<MapEntry<String, String>> toEntries() {
    return [
      MapEntry('Rodovia', acronym ?? ''),
      MapEntry('UF', uf ?? ''),
      MapEntry('Extensão', extension?.toStringAsFixed(2) ?? '--'),
      MapEntry('Trecho', state ?? ''),
      MapEntry('Tipo Pavimento', stateSurface ?? ''),
      MapEntry('Pontos', points?.length.toString() ?? ''),
      MapEntry('ID', id ?? ''),
      MapEntry('Criado em', createdAt?.toString() ?? ''),
      MapEntry('Atualizado em', updatedAt?.toString() ?? ''),
      MapEntry('Deletado em', deletedAt?.toString() ?? ''),
      MapEntry('Criado por', createdBy ?? ''),
      MapEntry('Atualizado por', updatedBy ?? ''),
      MapEntry('Deletado por', deletedBy ?? ''),
      MapEntry('Detalhes', description ?? ''),
      MapEntry('Segmento', segmentType ?? ''),
      MapEntry('Código', roadCode ?? ''),
      MapEntry('Segmento Inicial', initialSegment ?? ''),
      MapEntry('Segmento Final', finalSegment ?? ''),
      MapEntry('Km Inicial', initialKm?.toString() ?? ''),
      MapEntry('Km Final', finalKm?.toString() ?? ''),
      MapEntry('Extensão (raw)', extension?.toString() ?? ''),
      MapEntry('Pavimento', stateSurface ?? ''),
      MapEntry('Trabalho', works ?? ''),
      MapEntry('Coincidente Federal', coincidentFederal ?? ''),
      MapEntry('Administração', administration ?? ''),
      MapEntry('Lei', legalAct ?? ''),
      MapEntry('Coincidente Estadual', coincidentState ?? ''),
      MapEntry('Pavimento Estadual', coincidentStateSurface ?? ''),
      MapEntry('Jurisdição', jurisdiction ?? ''),
      MapEntry('Pavimento (raw)', surface ?? ''),
      MapEntry('Unidade Local', unitLocal ?? ''),
      MapEntry('Coincidente', coincident ?? ''),
      MapEntry('Lat Inicial', initialLatSegment ?? ''),
      MapEntry('Long Inicial', initialLongSegment ?? ''),
      MapEntry('Lat Final', finalLatSegment ?? ''),
      MapEntry('Long Final', finalLongSegment ?? ''),
      MapEntry('Regional', regional ?? ''),
      MapEntry('Número Anterior', previousNumber ?? ''),
      MapEntry('Revest. Tipo', revestmentType ?? ''),
      MapEntry('TMD', tmd?.toString() ?? ''),
      MapEntry('Trilhos', tracksNumber?.toString() ?? ''),
      MapEntry('Vel. Máx.', maximumSpeed?.toString() ?? ''),
      MapEntry('Condic. Conservação', conservationCondition ?? ''),
      MapEntry('Drenagem', drainage ?? ''),
      MapEntry('VSA', vsa?.toString() ?? ''),
      MapEntry('Nome', roadName ?? ''),
      MapEntry('Estado', state ?? ''),
      MapEntry('Direção', direction ?? ''),
      MapEntry('Agência de Gestão', managingAgency ?? ''),
      MapEntry('Descrição', description ?? ''),
      MapEntry('Metadata', metadata?.toString() ?? ''),
    ];
  }
}

/// Função de projeção de ponto em segmento em coordenadas cartesianas (metros aproximados)
Offset _projectPointOnSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
  if (ab2 == 0) return a;
  final ap = p - a;
  var t = (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
  t = t.clamp(0.0, 1.0);
  return Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
}
