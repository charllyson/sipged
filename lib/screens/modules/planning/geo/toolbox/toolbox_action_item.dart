import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/layer/layer_data.dart';

class ToolboxActionItem {
  final String id;
  final String tooltip;
  final IconData icon;
  final VoidCallback? onTap;
  final bool enabled;
  final List<ToolboxActionItem> children;
  final LayerGeometryKind? geometryKind;
  final bool showEditBadge;

  const ToolboxActionItem({
    required this.id,
    required this.tooltip,
    required this.icon,
    this.onTap,
    this.enabled = true,
    this.children = const [],
    this.geometryKind,
    this.showEditBadge = false,
  });

  bool get hasChildren => children.isNotEmpty;

  ToolboxActionItem copyWith({
    String? id,
    String? tooltip,
    IconData? icon,
    VoidCallback? onTap,
    bool? enabled,
    List<ToolboxActionItem>? children,
    LayerGeometryKind? geometryKind,
    bool? showEditBadge,
  }) {
    return ToolboxActionItem(
      id: id ?? this.id,
      tooltip: tooltip ?? this.tooltip,
      icon: icon ?? this.icon,
      onTap: onTap ?? this.onTap,
      enabled: enabled ?? this.enabled,
      children: children ?? this.children,
      geometryKind: geometryKind ?? this.geometryKind,
      showEditBadge: showEditBadge ?? this.showEditBadge,
    );
  }
}

class ToolboxSectionData {
  final String id;
  final List<ToolboxActionItem> actions;

  const ToolboxSectionData({
    required this.id,
    required this.actions,
  });
}