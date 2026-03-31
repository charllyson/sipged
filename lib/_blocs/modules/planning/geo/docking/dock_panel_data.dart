import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data_item.dart';

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

class DockPanelData {
  static const Object _sentinel = Object();

  final String id;
  final String title;
  final DockArea area;
  final DockCrossSpan crossSpan;
  final List<DockPanelDataItem> items;
  final String? activeItemId;
  final bool visible;

  /// Quando true, o painel não ocupa layout, mas continua acessível
  /// na rail lateral.
  final bool collapsed;

  final Offset floatingOffset;
  final Size floatingSize;

  final double dockExtent;
  final double dockWeight;

  final IconData? icon;
  final Color? accentColor;

  final bool shrinkWrapOnMainAxis;
  final bool minimized;
  final DockArea? lastDockArea;
  final DockCrossSpan? lastDockCrossSpan;

  /// Quando true, o floating está em modo popup/dialog ampliado.
  final bool floatingAsDialog;

  /// Se true, ao fechar o dialog ele volta para floating normal.
  /// Se false, ele volta para a área dockada anterior.
  final bool restoreToFloatingOnDialogClose;

  /// Estado anterior do floating normal antes de abrir como dialog.
  final Offset storedFloatingOffset;
  final Size storedFloatingSize;

  const DockPanelData({
    required this.id,
    required this.title,
    required this.area,
    required this.items,
    this.crossSpan = DockCrossSpan.full,
    this.activeItemId,
    this.visible = true,
    this.collapsed = false,
    this.floatingOffset = const Offset(80, 80),
    this.floatingSize = const Size(360, 420),
    this.dockExtent = 320,
    this.dockWeight = 1.0,
    this.icon,
    this.accentColor,
    this.shrinkWrapOnMainAxis = false,
    this.minimized = false,
    this.lastDockArea,
    this.lastDockCrossSpan,
    this.floatingAsDialog = false,
    this.restoreToFloatingOnDialogClose = false,
    this.storedFloatingOffset = const Offset(80, 80),
    this.storedFloatingSize = const Size(360, 420),
  });

  bool get hasItems => items.isNotEmpty;

  DockPanelDataItem? get activeItem {
    if (items.isEmpty) return null;
    if (activeItemId == null) return items.first;

    for (final item in items) {
      if (item.id == activeItemId) return item;
    }

    return items.first;
  }

  bool get hasRenderableItem => activeItem != null;

  DockPanelData copyWith({
    String? id,
    String? title,
    DockArea? area,
    DockCrossSpan? crossSpan,
    List<DockPanelDataItem>? items,
    Object? activeItemId = _sentinel,
    bool? visible,
    bool? collapsed,
    Offset? floatingOffset,
    Size? floatingSize,
    double? dockExtent,
    double? dockWeight,
    IconData? icon,
    Color? accentColor,
    bool? shrinkWrapOnMainAxis,
    bool? minimized,
    Object? lastDockArea = _sentinel,
    Object? lastDockCrossSpan = _sentinel,
    bool? floatingAsDialog,
    bool? restoreToFloatingOnDialogClose,
    Offset? storedFloatingOffset,
    Size? storedFloatingSize,
  }) {
    return DockPanelData(
      id: id ?? this.id,
      title: title ?? this.title,
      area: area ?? this.area,
      crossSpan: crossSpan ?? this.crossSpan,
      items: items ?? this.items,
      activeItemId:
      identical(activeItemId, _sentinel) ? this.activeItemId : activeItemId as String?,
      visible: visible ?? this.visible,
      collapsed: collapsed ?? this.collapsed,
      floatingOffset: floatingOffset ?? this.floatingOffset,
      floatingSize: floatingSize ?? this.floatingSize,
      dockExtent: dockExtent ?? this.dockExtent,
      dockWeight: dockWeight ?? this.dockWeight,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      shrinkWrapOnMainAxis:
      shrinkWrapOnMainAxis ?? this.shrinkWrapOnMainAxis,
      minimized: minimized ?? this.minimized,
      lastDockArea:
      identical(lastDockArea, _sentinel) ? this.lastDockArea : lastDockArea as DockArea?,
      lastDockCrossSpan: identical(lastDockCrossSpan, _sentinel)
          ? this.lastDockCrossSpan
          : lastDockCrossSpan as DockCrossSpan?,
      floatingAsDialog: floatingAsDialog ?? this.floatingAsDialog,
      restoreToFloatingOnDialogClose:
      restoreToFloatingOnDialogClose ?? this.restoreToFloatingOnDialogClose,
      storedFloatingOffset: storedFloatingOffset ?? this.storedFloatingOffset,
      storedFloatingSize: storedFloatingSize ?? this.storedFloatingSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is DockPanelData &&
            other.id == id &&
            other.title == title &&
            other.area == area &&
            other.crossSpan == crossSpan &&
            listEquals(other.items, items) &&
            other.activeItemId == activeItemId &&
            other.visible == visible &&
            other.collapsed == collapsed &&
            other.floatingOffset == floatingOffset &&
            other.floatingSize == floatingSize &&
            other.dockExtent == dockExtent &&
            other.dockWeight == dockWeight &&
            other.icon == icon &&
            other.accentColor == accentColor &&
            other.shrinkWrapOnMainAxis == shrinkWrapOnMainAxis &&
            other.minimized == minimized &&
            other.lastDockArea == lastDockArea &&
            other.lastDockCrossSpan == lastDockCrossSpan &&
            other.floatingAsDialog == floatingAsDialog &&
            other.restoreToFloatingOnDialogClose ==
                restoreToFloatingOnDialogClose &&
            other.storedFloatingOffset == storedFloatingOffset &&
            other.storedFloatingSize == storedFloatingSize);
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
    collapsed,
    floatingOffset,
    floatingSize,
    dockExtent,
    dockWeight,
    icon,
    accentColor,
    shrinkWrapOnMainAxis,
    minimized,
    lastDockArea,
    lastDockCrossSpan,
    floatingAsDialog,
    restoreToFloatingOnDialogClose,
    storedFloatingOffset,
    storedFloatingSize,
  ]);
}

class DockDragPayload {
  final String groupId;

  const DockDragPayload({
    required this.groupId,
  });
}