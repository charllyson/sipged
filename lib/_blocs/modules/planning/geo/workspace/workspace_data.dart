import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_binding.dart';
import 'package:sipged/_blocs/modules/planning/geo/catalog/catalog_data.dart';

enum WorkspaceSnapEdge {
  left,
  centerX,
  right,
  top,
  centerY,
  bottom,
}

@immutable
class WorkspaceData {
  final String id;
  final String title;
  final CatalogType type;
  final Offset offset;
  final Size size;
  final List<CatalogData> properties;

  final String? resolvedTitle;
  final String? resolvedSubtitle;
  final String? resolvedLabel;
  final String? resolvedValue;
  final List<String>? resolvedLabels;
  final List<double>? resolvedValues;

  const WorkspaceData({
    required this.id,
    required this.title,
    required this.type,
    required this.offset,
    required this.size,
    this.properties = const [],
    this.resolvedTitle,
    this.resolvedSubtitle,
    this.resolvedLabel,
    this.resolvedValue,
    this.resolvedLabels,
    this.resolvedValues,
  });

  static const Size minSize = Size(180, 120);
  static const Object _sentinel = Object();

  String get catalogItemId => type.catalogItemId;

  CatalogData? propertyByKey(String key) {
    for (final property in properties) {
      if (property.key == key) return property;
    }
    return null;
  }

  String getTextProperty(String key, {String fallback = ''}) {
    return propertyByKey(key)?.textValue ?? fallback;
  }

  String? getNullableTextProperty(String key) {
    return propertyByKey(key)?.textValue;
  }

  double getNumberProperty(String key, {double fallback = 0}) {
    return propertyByKey(key)?.numberValue ?? fallback;
  }

  double? getNullableNumberProperty(String key) {
    return propertyByKey(key)?.numberValue;
  }

  String getSelectedProperty(String key, {String fallback = ''}) {
    return propertyByKey(key)?.selectedValue ?? fallback;
  }

  String? getNullableSelectedProperty(String key) {
    return propertyByKey(key)?.selectedValue;
  }

  FeatureDataBinding? getBindingProperty(String key) {
    return propertyByKey(key)?.bindingValue;
  }

  String? getBindingFieldName(String key) {
    final value = getBindingProperty(key)?.fieldName?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get sourceLayerId {
    final explicit = getBindingProperty('source')?.sourceId?.trim();
    if (explicit != null && explicit.isNotEmpty) {
      return explicit;
    }

    const fallbackBindingKeys = [
      'labelField',
      'valueField',
      'label',
      'value',
    ];

    for (final key in fallbackBindingKeys) {
      final candidate = getBindingProperty(key)?.sourceId?.trim();
      if (candidate != null && candidate.isNotEmpty) {
        return candidate;
      }
    }

    return null;
  }

  bool get hasResolvedChartData =>
      resolvedLabels != null &&
          resolvedValues != null &&
          resolvedLabels!.isNotEmpty &&
          resolvedValues!.isNotEmpty &&
          resolvedLabels!.length == resolvedValues!.length;

  bool get hasResolvedCardData =>
      (resolvedValue?.trim().isNotEmpty ?? false) ||
          (resolvedLabel?.trim().isNotEmpty ?? false);

  WorkspaceData copyWith({
    String? id,
    String? title,
    CatalogType? type,
    Offset? offset,
    Size? size,
    List<CatalogData>? properties,
    Object? resolvedTitle = _sentinel,
    Object? resolvedSubtitle = _sentinel,
    Object? resolvedLabel = _sentinel,
    Object? resolvedValue = _sentinel,
    Object? resolvedLabels = _sentinel,
    Object? resolvedValues = _sentinel,
  }) {
    return WorkspaceData(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      offset: offset ?? this.offset,
      size: size ?? this.size,
      properties: properties ?? this.properties,
      resolvedTitle: identical(resolvedTitle, _sentinel)
          ? this.resolvedTitle
          : resolvedTitle as String?,
      resolvedSubtitle: identical(resolvedSubtitle, _sentinel)
          ? this.resolvedSubtitle
          : resolvedSubtitle as String?,
      resolvedLabel: identical(resolvedLabel, _sentinel)
          ? this.resolvedLabel
          : resolvedLabel as String?,
      resolvedValue: identical(resolvedValue, _sentinel)
          ? this.resolvedValue
          : resolvedValue as String?,
      resolvedLabels: identical(resolvedLabels, _sentinel)
          ? this.resolvedLabels
          : resolvedLabels as List<String>?,
      resolvedValues: identical(resolvedValues, _sentinel)
          ? this.resolvedValues
          : resolvedValues as List<double>?,
    );
  }

  WorkspaceData copyWithUpdatedProperty(
      String propertyKey,
      CatalogData updatedProperty,
      ) {
    var changed = false;

    final nextProperties = properties.map((property) {
      if (property.key != propertyKey) return property;
      changed = true;
      return updatedProperty;
    }).toList(growable: false);

    if (!changed) return this;
    return copyWith(properties: nextProperties);
  }

  WorkspaceData copyWithResolvedData({
    String? title,
    String? subtitle,
    String? label,
    String? value,
    List<String>? labels,
    List<double>? values,
  }) {
    return copyWith(
      resolvedTitle: title,
      resolvedSubtitle: subtitle,
      resolvedLabel: label,
      resolvedValue: value,
      resolvedLabels: labels,
      resolvedValues: values,
    );
  }

  WorkspaceData clearResolvedData() {
    return copyWith(
      resolvedTitle: null,
      resolvedSubtitle: null,
      resolvedLabel: null,
      resolvedValue: null,
      resolvedLabels: null,
      resolvedValues: null,
    );
  }

  WorkspaceData copyWithoutResolvedData() {
    return WorkspaceData(
      id: id,
      title: title,
      type: type,
      offset: offset,
      size: size,
      properties: properties,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type.name,
      'offsetX': offset.dx,
      'offsetY': offset.dy,
      'width': size.width,
      'height': size.height,
      'properties': properties.map((e) => e.toMap()).toList(growable: false),
    };
  }

  factory WorkspaceData.fromMap(Map<String, dynamic> map) {
    final rawProperties = (map['properties'] as List?) ?? const [];

    return WorkspaceData(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      type: CatalogType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => CatalogType.card,
      ),
      offset: Offset(
        (map['offsetX'] as num?)?.toDouble() ?? 0,
        (map['offsetY'] as num?)?.toDouble() ?? 0,
      ),
      size: Size(
        (map['width'] as num?)?.toDouble() ?? minSize.width,
        (map['height'] as num?)?.toDouble() ?? minSize.height,
      ),
      properties: rawProperties
          .whereType<Map>()
          .map((e) => CatalogData.fromMap(Map<String, dynamic>.from(e)))
          .toList(growable: false),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is WorkspaceData &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        other.offset == offset &&
        other.size == size &&
        listEquals(other.properties, properties) &&
        other.resolvedTitle == resolvedTitle &&
        other.resolvedSubtitle == resolvedSubtitle &&
        other.resolvedLabel == resolvedLabel &&
        other.resolvedValue == resolvedValue &&
        listEquals(other.resolvedLabels, resolvedLabels) &&
        listEquals(other.resolvedValues, resolvedValues);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    offset,
    size,
    Object.hashAll(properties),
    resolvedTitle,
    resolvedSubtitle,
    resolvedLabel,
    resolvedValue,
    Object.hashAll(resolvedLabels ?? const []),
    Object.hashAll(resolvedValues ?? const []),
  );
}