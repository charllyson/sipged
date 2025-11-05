// lib/_blocs/planning/highway_domain/planning_highway_domain_data.dart
import 'package:cloud_firestore/cloud_firestore.dart' show GeoPoint, Timestamp;
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

class PlanningHighwayDomainData extends Equatable {
  final String id;

  /// Metadados (vindos de KML/KMZ/GeoJSON properties)
  final Map<String, dynamic> properties;

  /// Ex.: "LineString" ou "Polygon" (você pode padronizar no import)
  final String geometryType;

  /// Polyline/Polygon para UI
  final List<LatLng> points;

  /// Auditoria (opcional)
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;

  const PlanningHighwayDomainData({
    required this.id,
    required this.properties,
    required this.geometryType,
    required this.points,
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [
    id,
    properties,
    geometryType,
    points,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
  ];

  // -------- Parse Firestore -> Modelo --------
  factory PlanningHighwayDomainData.fromFirestore(String id, Map<String, dynamic> m) {
    final rawPts = (m['points'] as List?) ?? const [];
    final pts = <LatLng>[];
    for (final p in rawPts) {
      if (p is GeoPoint) {
        pts.add(LatLng(p.latitude, p.longitude));
      } else if (p is Map) {
        final lat = (p['lat'] ?? p['latitude']) as num?;
        final lng = (p['lng'] ?? p['longitude']) as num?;
        if (lat != null && lng != null) pts.add(LatLng(lat.toDouble(), lng.toDouble()));
      } else if (p is List && p.length >= 2) {
        final lon = (p[0] as num?)?.toDouble();
        final lat = (p[1] as num?)?.toDouble();
        if (lat != null && lon != null) pts.add(LatLng(lat, lon));
      }
    }

    DateTime? _d(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) return DateTime.tryParse(v);
      if (v is DateTime) return v;
      return null;
    }

    return PlanningHighwayDomainData(
      id: id,
      properties: Map<String, dynamic>.from((m['props'] as Map?) ?? const {}),
      geometryType: (m['geometryType'] ?? 'LineString').toString(),
      points: pts,
      createdAt: _d(m['createdAt']),
      createdBy: (m['createdBy'] ?? '') as String?,
      updatedAt: _d(m['updatedAt']),
      updatedBy: (m['updatedBy'] ?? '') as String?,
    );
  }

  // -------- Modelo -> Firestore --------
  Map<String, dynamic> toFirestore() {
    return {
      'props': properties,
      'geometryType': geometryType,
      'points': points.map((p) => {'latitude': p.latitude, 'longitude': p.longitude}).toList(),
    };
  }
}
