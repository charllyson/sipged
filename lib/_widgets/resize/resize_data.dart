
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_property.dart';

enum ResizeHandle {
  left,
  right,
  top,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

class ResizeData {
  final String id;
  final String title;
  final GeoWorkspaceWidgetType type;
  final Offset offset;
  final Size size;
  final List<GeoWorkspaceDataProperty> properties;

  const ResizeData({
    required this.id,
    required this.title,
    required this.type,
    required this.offset,
    required this.size,
    this.properties = const [],
  });

  static const Size minSize = Size(180, 120);

  String get catalogItemId => type.catalogItemId;

  GeoWorkspaceDataProperty? propertyByKey(String key) {
    try {
      return properties.firstWhere((e) => e.key == key);
    } catch (_) {
      return null;
    }
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

  List<String> getStringListProperty(
      String key, {
        List<String> fallback = const [],
      }) {
    return propertyByKey(key)?.stringListValue ?? fallback;
  }

  List<String>? getNullableStringListProperty(String key) {
    return propertyByKey(key)?.stringListValue;
  }

  List<double> getNumberListProperty(
      String key, {
        List<double> fallback = const [],
      }) {
    return propertyByKey(key)?.numberListValue ?? fallback;
  }

  List<double>? getNullableNumberListProperty(String key) {
    return propertyByKey(key)?.numberListValue;
  }

  String getSelectedProperty(String key, {String fallback = ''}) {
    return propertyByKey(key)?.selectedValue ?? fallback;
  }

  String? getNullableSelectedProperty(String key) {
    return propertyByKey(key)?.selectedValue;
  }

  GeoWorkspaceFieldData? getBindingProperty(String key) {
    return propertyByKey(key)?.bindingValue;
  }

  ResizeData copyWith({
    String? id,
    String? title,
    GeoWorkspaceWidgetType? type,
    Offset? offset,
    Size? size,
    List<GeoWorkspaceDataProperty>? properties,
  }) {
    return ResizeData(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      offset: offset ?? this.offset,
      size: size ?? this.size,
      properties: properties ?? this.properties,
    );
  }

  ResizeData copyWithUpdatedProperty(
      String propertyKey,
      GeoWorkspaceDataProperty updatedProperty,
      ) {
    final nextProperties = properties.map((property) {
      if (property.key != propertyKey) return property;
      return updatedProperty;
    }).toList(growable: false);

    return copyWith(properties: nextProperties);
  }

  @override
  bool operator ==(Object other) {
    return other is ResizeData &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        other.offset == offset &&
        other.size == size &&
        listEquals(other.properties, properties);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    offset,
    size,
    Object.hashAll(properties),
  );
}