import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/geo_feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';

@immutable
class GeoWorkspaceState {
  final List<GeoWorkspaceData> items;
  final String? selectedItemId;
  final GeoWorkspaceGuideLines? guides;
  final Map<String, List<GeoFeatureData>> featuresByLayer;
  final Size panelSize;
  final int dataVersion;

  const GeoWorkspaceState({
    required this.items,
    required this.selectedItemId,
    required this.guides,
    required this.featuresByLayer,
    required this.panelSize,
    required this.dataVersion,
  });

  factory GeoWorkspaceState.initial({
    List<GeoWorkspaceData> items = const [],
    Map<String, List<GeoFeatureData>> featuresByLayer = const {},
  }) {
    return GeoWorkspaceState(
      items: List<GeoWorkspaceData>.from(items),
      selectedItemId: null,
      guides: null,
      featuresByLayer: Map<String, List<GeoFeatureData>>.from(featuresByLayer),
      panelSize: Size.zero,
      dataVersion: 0,
    );
  }

  GeoWorkspaceState copyWith({
    List<GeoWorkspaceData>? items,
    String? selectedItemId,
    bool clearSelectedItem = false,
    GeoWorkspaceGuideLines? guides,
    bool clearGuides = false,
    Map<String, List<GeoFeatureData>>? featuresByLayer,
    Size? panelSize,
    int? dataVersion,
  }) {
    return GeoWorkspaceState(
      items: items ?? this.items,
      selectedItemId:
      clearSelectedItem ? null : (selectedItemId ?? this.selectedItemId),
      guides: clearGuides ? null : (guides ?? this.guides),
      featuresByLayer: featuresByLayer ?? this.featuresByLayer,
      panelSize: panelSize ?? this.panelSize,
      dataVersion: dataVersion ?? this.dataVersion,
    );
  }

  bool get hasItems => items.isNotEmpty;

  List<String> get itemIds => items.map((e) => e.id).toList(growable: false);

  GeoWorkspaceData? itemByIdOrNull(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  GeoWorkspaceData? get selectedItem {
    final id = selectedItemId;
    if (id == null) return null;
    return itemByIdOrNull(id);
  }

  bool isSelected(String itemId) => selectedItemId == itemId;

  @override
  bool operator ==(Object other) {
    return other is GeoWorkspaceState &&
        listEquals(other.items, items) &&
        other.selectedItemId == selectedItemId &&
        other.guides == guides &&
        other.panelSize == panelSize &&
        other.dataVersion == dataVersion;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    selectedItemId,
    guides,
    panelSize,
    dataVersion,
  );
}