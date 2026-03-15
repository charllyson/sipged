import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum TypeFieldGeoJson { string, integer, double_, boolean, datetime }

class GeoAttributesData extends Equatable {
  final String? docId;
  final Map<String, dynamic> originalProperties;
  final Map<String, dynamic> editedProperties;
  final Map<String, TypeFieldGeoJson> columnTypes;
  final bool selected;
  final Map<String, dynamic> geometry;
  final String geometryType;
  final List<GeoPoint> geometryPoints;
  final List<List<GeoPoint>> geometryParts;

  const GeoAttributesData({
    this.docId,
    required this.originalProperties,
    required this.editedProperties,
    required this.columnTypes,
    required this.selected,
    required this.geometry,
    required this.geometryType,
    required this.geometryPoints,
    required this.geometryParts,
  });

  bool get hasGeometry =>
      geometry.isNotEmpty || geometryPoints.isNotEmpty || geometryParts.isNotEmpty;

  GeoAttributesData copyWith({
    String? docId,
    Map<String, dynamic>? originalProperties,
    Map<String, dynamic>? editedProperties,
    Map<String, TypeFieldGeoJson>? columnTypes,
    bool? selected,
    Map<String, dynamic>? geometry,
    String? geometryType,
    List<GeoPoint>? geometryPoints,
    List<List<GeoPoint>>? geometryParts,
  }) {
    return GeoAttributesData(
      docId: docId ?? this.docId,
      originalProperties: originalProperties ?? this.originalProperties,
      editedProperties: editedProperties ?? this.editedProperties,
      columnTypes: columnTypes ?? this.columnTypes,
      selected: selected ?? this.selected,
      geometry: geometry ?? this.geometry,
      geometryType: geometryType ?? this.geometryType,
      geometryPoints: geometryPoints ?? this.geometryPoints,
      geometryParts: geometryParts ?? this.geometryParts,
    );
  }

  @override
  List<Object?> get props => [
    docId,
    originalProperties,
    editedProperties,
    columnTypes,
    selected,
    geometry,
    geometryType,
    geometryPoints,
    geometryParts,
  ];
}

class ImportColumnMeta extends Equatable {
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

  @override
  List<Object?> get props => [name, selected, type];
}