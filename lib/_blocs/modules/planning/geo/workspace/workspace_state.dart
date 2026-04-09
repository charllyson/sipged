import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/workspace_filter.dart';
import 'package:sipged/_widgets/overlays/guides_lines/guide_lines_data.dart';

@immutable
class WorkspaceState {
  final List<WorkspaceData> items;
  final String? selectedItemId;
  final GuideLinesData? guides;
  final Map<String, List<FeatureData>> featuresByLayer;
  final Size panelSize;
  final int dataVersion;
  final WorkspaceFilter? activeFilter;

  const WorkspaceState({
    required this.items,
    required this.selectedItemId,
    required this.guides,
    required this.featuresByLayer,
    required this.panelSize,
    required this.dataVersion,
    required this.activeFilter,
  });

  factory WorkspaceState.initial({
    List<WorkspaceData> items = const [],
    Map<String, List<FeatureData>> featuresByLayer = const {},
  }) {
    return WorkspaceState(
      items: List<WorkspaceData>.from(items),
      selectedItemId: null,
      guides: null,
      featuresByLayer: Map<String, List<FeatureData>>.from(featuresByLayer),
      panelSize: Size.zero,
      dataVersion: 0,
      activeFilter: null,
    );
  }

  WorkspaceState copyWith({
    List<WorkspaceData>? items,
    String? selectedItemId,
    bool clearSelectedItem = false,
    GuideLinesData? guides,
    bool clearGuides = false,
    Map<String, List<FeatureData>>? featuresByLayer,
    Size? panelSize,
    int? dataVersion,
    WorkspaceFilter? activeFilter,
    bool clearActiveFilter = false,
  }) {
    return WorkspaceState(
      items: items ?? this.items,
      selectedItemId:
      clearSelectedItem ? null : (selectedItemId ?? this.selectedItemId),
      guides: clearGuides ? null : (guides ?? this.guides),
      featuresByLayer: featuresByLayer ?? this.featuresByLayer,
      panelSize: panelSize ?? this.panelSize,
      dataVersion: dataVersion ?? this.dataVersion,
      activeFilter:
      clearActiveFilter ? null : (activeFilter ?? this.activeFilter),
    );
  }

  bool get hasItems => items.isNotEmpty;

  List<String> get itemIds => items.map((e) => e.id).toList(growable: false);

  WorkspaceData? itemByIdOrNull(String id) {
    for (final item in items) {
      if (item.id == id) return item;
    }
    return null;
  }

  WorkspaceData? get selectedItem {
    final id = selectedItemId;
    if (id == null) return null;
    return itemByIdOrNull(id);
  }

  bool isSelected(String itemId) => selectedItemId == itemId;

  @override
  bool operator ==(Object other) {
    return other is WorkspaceState &&
        listEquals(other.items, items) &&
        other.selectedItemId == selectedItemId &&
        other.guides == guides &&
        other.panelSize == panelSize &&
        other.dataVersion == dataVersion &&
        other.activeFilter == activeFilter;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(items),
    selectedItemId,
    guides,
    panelSize,
    dataVersion,
    activeFilter,
  );
}