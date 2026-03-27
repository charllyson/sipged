import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/docking/dock_panel_config.dart';
import 'package:sipged/_widgets/docking/dock_panel_tabs.dart';
import 'package:sipged/_widgets/draggable/drag_placeholder.dart';
import 'package:sipged/_widgets/draggable/draggable_header.dart';
import 'package:sipged/_widgets/docking/dock_panel_body.dart';
import 'package:sipged/_widgets/draggable/resize_handle.dart';

class DockPanelGroup extends StatelessWidget {
  final DockPanelData group;
  final bool isFloating;
  final bool isDragging;

  final VoidCallback onToggleFloating;
  final VoidCallback onHide;
  final ValueChanged<String> onTabSelected;

  final VoidCallback onDragStarted;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DraggableDetails details) onDragEnd;

  final VoidCallback onResizeStart;
  final void Function(DragUpdateDetails details) onResizeUpdate;
  final void Function(DragEndDetails details) onResizeEnd;

  const DockPanelGroup({
    super.key,
    required this.group,
    required this.isFloating,
    required this.isDragging,
    required this.onToggleFloating,
    required this.onHide,
    required this.onTabSelected,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onResizeStart,
    required this.onResizeUpdate,
    required this.onResizeEnd,
  });

  static const double _tabsHeight = 36;
  static const double _resizeHandleReserve = 28;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final fill = isDark
        ? const Color(0xFF182033).withValues(alpha: 0.94)
        : Colors.white.withValues(alpha: 0.96);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.08);

    final shadowColor = Colors.black.withValues(alpha: isDark ? 0.26 : 0.10);

    final accent = group.accentColor ?? theme.colorScheme.primary;
    final activeItem = group.activeItem;

    if (activeItem == null) {
      return const SizedBox.shrink();
    }

    final minimized = group.minimized;
    final shouldShrinkWrap =
        !isFloating && (group.shrinkWrapOnMainAxis || minimized);

    final showTabs = !minimized && group.items.length > 1;
    final showResizeHandle =
        isFloating && !minimized && !group.floatingAsDialog;

    final double bottomReservedSpace =
        (showTabs ? _tabsHeight : 0.0) +
            (showResizeHandle ? _resizeHandleReserve : 0.0);

    final contentBody = RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: activeItem.contentPadding.add(
          EdgeInsets.only(bottom: bottomReservedSpace),
        ),
        child: activeItem.child,
      ),
    );

    final panelBody = minimized
        ? const SizedBox.shrink()
        : shouldShrinkWrap
        ? Stack(
      children: [
        contentBody,
        if (showTabs)
          Align(
            alignment: Alignment.bottomLeft,
            child: DockPanelTabs(
              group: group,
              accent: accent,
              onTabSelected: onTabSelected,
            ),
          ),
        if (showResizeHandle)
          ResizeHandle(
            onPanStart: onResizeStart,
            onPanUpdate: onResizeUpdate,
            onPanEnd: onResizeEnd,
          ),
      ],
    )
        : Expanded(
      child: Stack(
        children: [
          Positioned.fill(child: contentBody),
          if (showTabs)
            Align(
              alignment: Alignment.bottomLeft,
              child: DockPanelTabs(
                group: group,
                accent: accent,
                onTabSelected: onTabSelected,
              ),
            ),
          if (showResizeHandle)
            ResizeHandle(
              onPanStart: onResizeStart,
              onPanUpdate: onResizeUpdate,
              onPanEnd: onResizeEnd,
            ),
        ],
      ),
    );

    final content = isDragging
        ? Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DraggableHeader(
          group: group,
          accent: accent,
          isFloating: isFloating,
          onToggleFloating: onToggleFloating,
          onHide: onHide,
          onDragStarted: onDragStarted,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
        ),
        if (shouldShrinkWrap)
          DragPlaceholder(accent: accent)
        else
          Expanded(child: DragPlaceholder(accent: accent)),
      ],
    )
        : Column(
      mainAxisSize:
      shouldShrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        DraggableHeader(
          group: group,
          accent: accent,
          isFloating: isFloating,
          onToggleFloating: onToggleFloating,
          onHide: onHide,
          onDragStarted: onDragStarted,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
        ),
        panelBody,
      ],
    );

    return DockPanelBody(
      isFloating: isFloating,
      fill: fill,
      borderColor: borderColor,
      shadowColor: shadowColor,
      child: content,
    );
  }
}
