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

class DockPanelData {
  static const Object _sentinel = Object();

  final String id;
  final String title;

  /// Grupo/painel
  final DockArea area;
  final DockCrossSpan crossSpan;
  final List<DockPanelData> items;
  final String? activeItemId;
  final bool visible;

  final Offset floatingOffset;
  final Size floatingSize;
  final double dockExtent;
  final double dockWeight;

  final IconData? icon;
  final Color? accentColor;
  final bool shrinkWrapOnMainAxis;

  /// Mantidos por compatibilidade com código externo.
  final bool collapsed;
  final bool minimized;
  final DockArea? lastDockArea;
  final DockCrossSpan? lastDockCrossSpan;

  final bool floatingAsDialog;
  final bool restoreToFloatingOnDialogClose;
  final Offset storedFloatingOffset;
  final Size storedFloatingSize;

  /// Aba/item
  final Widget? child;
  final EdgeInsetsGeometry contentPadding;

  /// Token para detectar mudança real de conteúdo.
  final Object? contentToken;

  const DockPanelData({
    required this.id,
    required this.title,
    this.area = DockArea.bottom,
    this.crossSpan = DockCrossSpan.full,
    this.items = const <DockPanelData>[],
    this.activeItemId,
    this.visible = true,
    this.floatingOffset = const Offset(80, 80),
    this.floatingSize = const Size(360, 420),
    this.dockExtent = 320,
    this.dockWeight = 1.0,
    this.icon,
    this.accentColor,
    this.shrinkWrapOnMainAxis = false,
    this.collapsed = false,
    this.minimized = false,
    this.lastDockArea,
    this.lastDockCrossSpan,
    this.floatingAsDialog = false,
    this.restoreToFloatingOnDialogClose = false,
    this.storedFloatingOffset = const Offset(80, 80),
    this.storedFloatingSize = const Size(360, 420),
    this.child,
    this.contentPadding = const EdgeInsets.all(8),
    this.contentToken,
  });

  bool get hasItems => items.isNotEmpty;

  bool get isItem => child != null || items.isEmpty;

  DockPanelData? get activeItem {
    if (items.isEmpty) return null;
    if (activeItemId == null) return items.first;

    for (final item in items) {
      if (item.id == activeItemId) return item;
    }

    return items.first;
  }

  bool get hasRenderableItem => activeItem?.child != null;

  DockPanelData copyWith({
    String? id,
    String? title,
    DockArea? area,
    DockCrossSpan? crossSpan,
    List<DockPanelData>? items,
    Object? activeItemId = _sentinel,
    bool? visible,
    Offset? floatingOffset,
    Size? floatingSize,
    double? dockExtent,
    double? dockWeight,
    IconData? icon,
    Color? accentColor,
    bool? shrinkWrapOnMainAxis,
    bool? collapsed,
    bool? minimized,
    Object? lastDockArea = _sentinel,
    Object? lastDockCrossSpan = _sentinel,
    bool? floatingAsDialog,
    bool? restoreToFloatingOnDialogClose,
    Offset? storedFloatingOffset,
    Size? storedFloatingSize,
    Object? child = _sentinel,
    EdgeInsetsGeometry? contentPadding,
    Object? contentToken = _sentinel,
  }) {
    return DockPanelData(
      id: id ?? this.id,
      title: title ?? this.title,
      area: area ?? this.area,
      crossSpan: crossSpan ?? this.crossSpan,
      items: items ?? this.items,
      activeItemId: identical(activeItemId, _sentinel)
          ? this.activeItemId
          : activeItemId as String?,
      visible: visible ?? this.visible,
      floatingOffset: floatingOffset ?? this.floatingOffset,
      floatingSize: floatingSize ?? this.floatingSize,
      dockExtent: dockExtent ?? this.dockExtent,
      dockWeight: dockWeight ?? this.dockWeight,
      icon: icon ?? this.icon,
      accentColor: accentColor ?? this.accentColor,
      shrinkWrapOnMainAxis:
      shrinkWrapOnMainAxis ?? this.shrinkWrapOnMainAxis,
      collapsed: collapsed ?? this.collapsed,
      minimized: minimized ?? this.minimized,
      lastDockArea: identical(lastDockArea, _sentinel)
          ? this.lastDockArea
          : lastDockArea as DockArea?,
      lastDockCrossSpan: identical(lastDockCrossSpan, _sentinel)
          ? this.lastDockCrossSpan
          : lastDockCrossSpan as DockCrossSpan?,
      floatingAsDialog: floatingAsDialog ?? this.floatingAsDialog,
      restoreToFloatingOnDialogClose:
      restoreToFloatingOnDialogClose ??
          this.restoreToFloatingOnDialogClose,
      storedFloatingOffset: storedFloatingOffset ?? this.storedFloatingOffset,
      storedFloatingSize: storedFloatingSize ?? this.storedFloatingSize,
      child: identical(child, _sentinel) ? this.child : child as Widget?,
      contentPadding: contentPadding ?? this.contentPadding,
      contentToken: identical(contentToken, _sentinel)
          ? this.contentToken
          : contentToken,
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
            other.floatingOffset == floatingOffset &&
            other.floatingSize == floatingSize &&
            other.dockExtent == dockExtent &&
            other.dockWeight == dockWeight &&
            other.icon == icon &&
            other.accentColor == accentColor &&
            other.shrinkWrapOnMainAxis == shrinkWrapOnMainAxis &&
            other.collapsed == collapsed &&
            other.minimized == minimized &&
            other.lastDockArea == lastDockArea &&
            other.lastDockCrossSpan == lastDockCrossSpan &&
            other.floatingAsDialog == floatingAsDialog &&
            other.restoreToFloatingOnDialogClose ==
                restoreToFloatingOnDialogClose &&
            other.storedFloatingOffset == storedFloatingOffset &&
            other.storedFloatingSize == storedFloatingSize &&
            other.contentPadding == contentPadding &&
            other.contentToken == contentToken);
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
    collapsed,
    minimized,
    lastDockArea,
    lastDockCrossSpan,
    floatingAsDialog,
    restoreToFloatingOnDialogClose,
    storedFloatingOffset,
    storedFloatingSize,
    contentPadding,
    contentToken,
  ]);
}

class DockDragPayload {
  final String groupId;

  const DockDragPayload({
    required this.groupId,
  });
}