import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum DockArea {
  left,
  right,
  top,
  bottom,
  floating,
}

enum DockCrossSpan {
  full,
  inner,
}

class DockPanelItemData {
  final String id;
  final String title;
  final IconData? icon;
  final Widget child;
  final EdgeInsetsGeometry contentPadding;

  const DockPanelItemData({
    required this.id,
    required this.title,
    required this.child,
    this.icon,
    this.contentPadding = const EdgeInsets.all(8),
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DockPanelItemData &&
            other.id == id &&
            other.title == title &&
            other.icon == icon &&
            identical(other.child, child) &&
            other.contentPadding == contentPadding);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    icon,
    identityHashCode(child),
    contentPadding,
  );
}

class DockPanelGroupData {
  final String id;
  final String title;
  final DockArea area;
  final DockCrossSpan crossSpan;
  final List<DockPanelItemData> items;
  final String? activeItemId;
  final bool visible;
  final Offset floatingOffset;
  final Size floatingSize;
  final double dockExtent;
  final double dockWeight;
  final IconData? icon;
  final Color? accentColor;

  /// Quando true, o painel dockado tenta usar apenas a altura/largura
  /// necessária para o conteúdo no eixo principal da área.
  final bool shrinkWrapOnMainAxis;

  const DockPanelGroupData({
    required this.id,
    required this.title,
    required this.area,
    required this.items,
    this.crossSpan = DockCrossSpan.full,
    this.activeItemId,
    this.visible = true,
    this.floatingOffset = const Offset(80, 80),
    this.floatingSize = const Size(360, 420),
    this.dockExtent = 320,
    this.dockWeight = 1.0,
    this.icon,
    this.accentColor,
    this.shrinkWrapOnMainAxis = false,
  });

  DockPanelItemData? get activeItem {
    if (items.isEmpty) return null;
    if (activeItemId == null) return items.first;

    for (final item in items) {
      if (item.id == activeItemId) return item;
    }

    return items.first;
  }

  DockPanelGroupData copyWith({
    String? id,
    String? title,
    DockArea? area,
    DockCrossSpan? crossSpan,
    List<DockPanelItemData>? items,
    String? activeItemId,
    bool? visible,
    Offset? floatingOffset,
    Size? floatingSize,
    double? dockExtent,
    double? dockWeight,
    IconData? icon,
    Color? accentColor,
    bool? shrinkWrapOnMainAxis,
  }) {
    return DockPanelGroupData(
      id: id ?? this.id,
      title: title ?? this.title,
      area: area ?? this.area,
      crossSpan: crossSpan ?? this.crossSpan,
      items: items ?? this.items,
      activeItemId: activeItemId ?? this.activeItemId,
      visible: visible ?? this.visible,
      floatingOffset: floatingOffset ?? this.floatingOffset,
      floatingSize: floatingSize ?? this.floatingSize,
      dockExtent: dockExtent ?? this.dockExtent,
      dockWeight: dockWeight ?? this.dockWeight,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      shrinkWrapOnMainAxis:
      shrinkWrapOnMainAxis ?? this.shrinkWrapOnMainAxis,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DockPanelGroupData &&
            other.id == id &&
            other.title == title &&
            other.area == area &&
            other.crossSpan == crossSpan &&
            listEquals(other.items, items) &&
            other.activeItemId == activeItemId &&
            other.visible == visible &&
            other.floatingOffset == floatingOffset &&
            other.floatingSize == floatingSize &&
            other.dockExtent == dockExtent &&
            other.dockWeight == dockWeight &&
            other.icon == icon &&
            other.accentColor == accentColor &&
            other.shrinkWrapOnMainAxis == shrinkWrapOnMainAxis);
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    title,
    area,
    crossSpan,
    Object.hashAll(items),
    activeItemId,
    visible,
    floatingOffset,
    floatingSize,
    dockExtent,
    dockWeight,
    icon,
    accentColor,
    shrinkWrapOnMainAxis,
  ]);
}

class DockDragPayload {
  final String groupId;

  const DockDragPayload({
    required this.groupId,
  });
}