import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

class ToolboxData {
  final String id;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final LayerGeometryKind? geometryKind;
  final bool showEditBadge;

  const ToolboxData({
    required this.id,
    required this.tooltip,
    required this.icon,
    this.onTap,
    this.enabled = true,
    this.geometryKind,
    this.showEditBadge = false,
  });

  ToolboxData copyWith({
    String? id,
    String? tooltip,
    IconData? icon,
    VoidCallback? onTap,
    bool? enabled,
    LayerGeometryKind? geometryKind,
    bool? showEditBadge,
  }) {
    return ToolboxData(
      id: id ?? this.id,
      tooltip: tooltip ?? this.tooltip,
      icon: icon ?? this.icon,
      onTap: onTap ?? this.onTap,
      enabled: enabled ?? this.enabled,
      geometryKind: geometryKind ?? this.geometryKind,
      showEditBadge: showEditBadge ?? this.showEditBadge,
    );
  }
}

class ToolboxSectionData {
  final String id;
  final List<ToolboxData> actions;

  const ToolboxSectionData({
    required this.id,
    required this.actions,
  });
}