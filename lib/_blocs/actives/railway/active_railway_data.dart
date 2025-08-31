import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Modelo de Ferrovias compatível com GeoJSON (multiLine) e Firestore (points).
class ActiveRailwayData extends ChangeNotifier {
  // ---------- Identificação / atributos principais ----------
  String? id;
  int? fid;                  // properties.fid
  double? nativeId;          // properties.id (1434.0 etc.)
  String? codigo;            // "Código"
  String? codigoCoincidente; // "Código Coincidente"
  String? nome;              // "Nome"
  String? status;            // "Status" (Em Operação, etc.)
  String? bitola;            // "bitola"
  String? municipio;         // "Município"
  String? uf;                // "UF"

  // Extensões
  double? extensao;          // "Extensão"
  double? extensaoE;         // "Extensão E."
  double? extensaoC;         // "Extensão C."

  /// Geometria principal (MultiLineString ou LineString)
  List<List<LatLng>>? multiLine;
  String? geometryType;

  // ---------- Metadados comuns ----------
  int? order;
  double? score;
  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  ActiveRailwayData({
    this.id,
    this.fid,
    this.nativeId,
    this.codigo,
    this.codigoCoincidente,
    this.nome,
    this.status,
    this.bitola,
    this.municipio,
    this.uf,
    this.extensao,
    this.extensaoE,
    this.extensaoC,
    this.multiLine,
    this.geometryType,
    this.order,
    this.score,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
  });

  // ---------- FACTORIES ----------

  factory ActiveRailwayData.fromDocument(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>?;
    if (data == null) throw Exception('Dados da Ferrovia não encontrados');
    return ActiveRailwayData.fromMap(data)..id = snapshot.id;
  }

  factory ActiveRailwayData.fromMap(Map<String, dynamic> map) {
    final parsedMulti = _parseMultiLineCoords(map['multiLine'] ?? map['geometry']);
    final pointsPolyline = _parsePointsToLatLngList(map['points']);
    final computedMulti = parsedMulti ??
        (pointsPolyline == null || pointsPolyline.isEmpty
            ? null
            : <List<LatLng>>[pointsPolyline]);

    return ActiveRailwayData(
      id: map['id'],
      fid: _asInt(map['fid']),
      nativeId: _asDouble(map['nativeId']) ?? _asDouble(map['id']),
      codigo: map['codigo'] ?? map['Código'],
      codigoCoincidente: map['codigoCoincidente'] ?? map['Código Coincidente'],
      nome: map['nome'] ?? map['Nome'],
      status: map['status'] ?? map['Status'],
      bitola: map['bitola'],
      municipio: map['municipio'] ?? map['Município'],
      uf: map['uf'] ?? map['UF'],
      extensao: _asDouble(map['extensao'] ?? map['Extensão']),
      extensaoE: _asDouble(map['extensaoE'] ?? map['Extensão E.']),
      extensaoC: _asDouble(map['extensaoC'] ?? map['Extensão C.']),
      multiLine: computedMulti,
      geometryType: (map['geometryType'] ?? (parsedMulti != null ? 'MultiLineString' : 'LineString'))?.toString(),
      order: _asInt(map['order']),
      score: _asDouble(map['score']),
      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy'],
      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy'],
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy'],
    );
  }

  factory ActiveRailwayData.fromGeoJsonFeature(Map<String, dynamic> feature) {
    final props = (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};
    final geom = feature['geometry'];
    return ActiveRailwayData(
      fid: _asInt(props['fid']),
      nativeId: _asDouble(props['id']),
      codigo: props['Código'] ?? props['codigo'],
      codigoCoincidente: props['Código Coincidente'] ?? props['codigoCoincidente'],
      nome: props['Nome'] ?? props['nome'],
      status: props['Status'] ?? props['status'],
      bitola: props['bitola'],
      municipio: props['Município'] ?? props['municipio'],
      uf: props['UF'] ?? props['uf'],
      extensao: _asDouble(props['Extensão'] ?? props['extensao']),
      extensaoE: _asDouble(props['Extensão E.'] ?? props['extensaoE']),
      extensaoC: _asDouble(props['Extensão C.'] ?? props['extensaoC']),
      multiLine: _parseMultiLineCoords(geom),
      geometryType: geom is Map && geom['type'] != null ? geom['type'].toString() : 'MultiLineString',
    );
  }

  // ---------- CLONE ----------
  ActiveRailwayData.fromData(ActiveRailwayData d) {
    id = d.id;
    fid = d.fid;
    nativeId = d.nativeId;
    codigo = d.codigo;
    codigoCoincidente = d.codigoCoincidente;
    nome = d.nome;
    status = d.status;
    bitola = d.bitola;
    municipio = d.municipio;
    uf = d.uf;
    extensao = d.extensao;
    extensaoE = d.extensaoE;
    extensaoC = d.extensaoC;
    multiLine = d.multiLine == null
        ? null
        : d.multiLine!.map((seg) => List<LatLng>.from(seg)).toList();
    geometryType = d.geometryType;
    order = d.order;
    score = d.score;
    createdAt = d.createdAt;
    createdBy = d.createdBy;
    updatedAt = d.updatedAt;
    updatedBy = d.updatedBy;
    deletedAt = d.deletedAt;
    deletedBy = d.deletedBy;
  }

  ActiveRailwayData toData() => ActiveRailwayData.fromData(this);

  // ---------- SERIALIZAÇÃO ----------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fid': fid,
      'nativeId': nativeId,
      'codigo': codigo,
      'codigoCoincidente': codigoCoincidente,
      'nome': nome,
      'status': status,
      'bitola': bitola,
      'municipio': municipio,
      'uf': uf,
      'extensao': extensao,
      'extensaoE': extensaoE,
      'extensaoC': extensaoC,
      'geometryType': geometryType ?? (multiLine != null ? 'MultiLineString' : 'LineString'),
      'multiLine': multiLine
          ?.map((seg) => seg.map((p) => [p.longitude, p.latitude]).toList())
          .toList(),
      'order': order,
      'score': score,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
      'deletedAt': deletedAt?.toIso8601String(),
      'deletedBy': deletedBy,
    };
  }

  Map<String, dynamic> toFirestore() {
    final pts = pointsFlattened;
    final m = <String, dynamic>{
      if (fid != null) 'fid': fid,
      if (nativeId != null) 'nativeId': nativeId,
      if (codigo != null) 'codigo': codigo,
      if (codigoCoincidente != null) 'codigoCoincidente': codigoCoincidente,
      if (nome != null) 'nome': nome,
      if (status != null) 'status': status,
      if (bitola != null) 'bitola': bitola,
      if (municipio != null) 'municipio': municipio,
      if (uf != null) 'uf': uf,
      if (extensao != null) 'extensao': extensao,
      if (extensaoE != null) 'extensaoE': extensaoE,
      if (extensaoC != null) 'extensaoC': extensaoC,
      if (geometryType != null) 'geometryType': geometryType,
      if (order != null) 'order': order,
      if (score != null) 'score': score,
      if (pts.isNotEmpty)
        'points': pts.map((p) => GeoPoint(p.latitude, p.longitude)).toList(),
    };
    return m;
  }

  // ---------- HELPERS ----------
  List<LatLng> get pointsFlattened =>
      (multiLine ?? const <List<LatLng>>[]).expand((seg) => seg).toList();

  List<LatLng>? get points {
    final flat = pointsFlattened;
    return flat.isEmpty ? null : flat;
  }

  /// Retorna os segmentos originais (ou 1 polyline se vier de Firestore).
  List<List<LatLng>> getSegments() {
    final ml = multiLine;
    if (ml != null && ml.isNotEmpty) {
      return ml.map((seg) => List<LatLng>.from(seg)).toList();
    }
    final flat = pointsFlattened;
    return flat.isEmpty ? const <List<LatLng>>[] : <List<LatLng>>[flat];
  }

  List<List<LatLng>> get segments => getSegments();

  List<double>? get bounds {
    final pts = pointsFlattened;
    if (pts.isEmpty) return null;
    double minLat = pts.first.latitude, maxLat = pts.first.latitude;
    double minLng = pts.first.longitude, maxLng = pts.first.longitude;
    for (final p in pts) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    return [minLat, minLng, maxLat, maxLng];
  }
}

// ======= Utils =======
double? _asDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.replaceAll(',', '.'));
  return null;
}

int? _asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  if (value is int) {
    try {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } catch (_) {}
  }
  return null;
}

/// ---------- Parsers de Geometria ----------
List<List<LatLng>>? _parseMultiLineCoords(dynamic geometryOrCoords) {
  if (geometryOrCoords == null) return null;

  if (geometryOrCoords is Map<String, dynamic>) {
    final type = geometryOrCoords['type']?.toString();
    final coords = geometryOrCoords['coordinates'];
    if (coords == null) return null;

    if (type == 'MultiLineString') {
      return _coordsToMultiLine(coords);
    } else if (type == 'LineString') {
      final line = _coordsToLine(coords);
      return line == null ? null : [line];
    } else {
      return null;
    }
  }

  if (geometryOrCoords is List) {
    if (geometryOrCoords.isNotEmpty && geometryOrCoords.first is List) {
      final first = geometryOrCoords.first;
      if (first is List && first.isNotEmpty && first.first is List) {
        return _coordsToMultiLine(geometryOrCoords);
      } else {
        final line = _coordsToLine(geometryOrCoords);
        return line == null ? null : [line];
      }
    }
  }
  return null;
}

List<List<LatLng>>? _coordsToMultiLine(dynamic coords) {
  if (coords is! List) return null;
  final result = <List<LatLng>>[];
  for (final seg in coords) {
    final line = _coordsToLine(seg);
    if (line != null && line.isNotEmpty) result.add(line);
  }
  return result.isEmpty ? null : result;
}

List<LatLng>? _coordsToLine(dynamic coords) {
  if (coords is! List) return null;
  final pts = <LatLng>[];
  for (final p in coords) {
    if (p is List && p.length >= 2) {
      final lon = _asDouble(p[0]);
      final lat = _asDouble(p[1]);
      if (lat != null && lon != null) pts.add(LatLng(lat, lon));
    }
  }
  return pts;
}

List<LatLng>? _parsePointsToLatLngList(dynamic value) {
  if (value is! List) return null;
  final out = <LatLng>[];
  for (final p in value) {
    if (p is GeoPoint) {
      out.add(LatLng(p.latitude, p.longitude));
    } else if (p is Map) {
      final lat = _asDouble(p['latitude'] ?? p['lat']);
      final lng = _asDouble(p['longitude'] ?? p['lng']);
      if (lat != null && lng != null) out.add(LatLng(lat, lng));
    } else if (p is List && p.length >= 2) {
      final lon = _asDouble(p[0]);
      final lat = _asDouble(p[1]);
      if (lat != null && lon != null) out.add(LatLng(lat, lon));
    }
  }
  return out;
}
