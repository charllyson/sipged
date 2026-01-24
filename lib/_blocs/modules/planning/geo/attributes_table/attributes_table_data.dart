import 'package:cloud_firestore/cloud_firestore.dart';

const String kGeometrySourceLabel = '[GEOMETRIA] Coordenadas (array GeoPoint)';

enum TypeFieldGeoJson { string, integer, double_, boolean, datetime }

class AttributesTableData {
  /// No modo Firestore, guarda o docId real
  final String? docId;

  final Map<String, dynamic> originalProperties;
  final Map<String, dynamic> editedProperties;

  /// Tipos inferidos/definidos (apenas controle de UI por enquanto)
  final Map<String, TypeFieldGeoJson> columnTypes;

  final bool selected;

  final bool saveGeometry;

  /// Nome do campo "flatten" de geometria no Firestore (ex.: "points")
  final String geometryFieldName;

  /// ✅ Flatten (compatibilidade): lista única de pontos
  final List<GeoPoint> geometryPoints;

  /// ✅ Segmentos (MultiLineString seguro): cada item é um trecho (>=2 pts)
  final List<List<GeoPoint>> geometryParts;

  /// Ex.: LineString, MultiLineString, Polygon etc.
  final String geometryType;

  const AttributesTableData({
    this.docId,
    required this.originalProperties,
    required this.editedProperties,
    required this.columnTypes,
    required this.selected,
    required this.saveGeometry,
    required this.geometryFieldName,
    required this.geometryPoints,
    required this.geometryParts,
    required this.geometryType,
  });

  AttributesTableData copyWith({
    String? docId,
    Map<String, dynamic>? originalProperties,
    Map<String, dynamic>? editedProperties,
    Map<String, TypeFieldGeoJson>? columnTypes,
    bool? selected,
    bool? saveGeometry,
    String? geometryFieldName,
    List<GeoPoint>? geometryPoints,
    List<List<GeoPoint>>? geometryParts,
    String? geometryType,
  }) {
    return AttributesTableData(
      docId: docId ?? this.docId,
      originalProperties: originalProperties ?? this.originalProperties,
      editedProperties: editedProperties ?? this.editedProperties,
      columnTypes: columnTypes ?? this.columnTypes,
      selected: selected ?? this.selected,
      saveGeometry: saveGeometry ?? this.saveGeometry,
      geometryFieldName: geometryFieldName ?? this.geometryFieldName,
      geometryPoints: geometryPoints ?? this.geometryPoints,
      geometryParts: geometryParts ?? this.geometryParts,
      geometryType: geometryType ?? this.geometryType,
    );
  }
}

class ImportColumnMeta {
  final String name;
  final bool selected;
  final TypeFieldGeoJson type;

  const ImportColumnMeta({
    required this.name,
    required this.selected,
    required this.type,
  });

  ImportColumnMeta copyWith({
    String? name,
    bool? selected,
    TypeFieldGeoJson? type,
  }) {
    return ImportColumnMeta(
      name: name ?? this.name,
      selected: selected ?? this.selected,
      type: type ?? this.type,
    );
  }
}
