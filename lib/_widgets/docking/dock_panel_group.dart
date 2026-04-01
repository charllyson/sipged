import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/docking/dock_panel_data.dart';
import 'package:sipged/_widgets/docking/dock_panel_body.dart';
import 'package:sipged/_widgets/docking/dock_panel_tabs.dart';
import 'package:sipged/_widgets/draggable/drag_placeholder.dart';
import 'package:sipged/_widgets/draggable/draggable_header.dart';
import 'package:sipged/_widgets/resize/resize_handle.dart';

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
  static const double _compactPanelMinHeight = 110;

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

    final minimized = group.minimized;
    final shouldShrinkWrap =
        !isFloating && (group.shrinkWrapOnMainAxis || minimized);

    final showTabs = !minimized && group.items.length > 1;
    final showResizeHandle =
        isFloating && !minimized && !group.floatingAsDialog;

    final double bottomReservedSpace =
        (showTabs ? _tabsHeight : 0.0) +
            (showResizeHandle ? _resizeHandleReserve : 0.0);

    final Widget contentBody = activeItem != null
        ? Container(
      width: double.infinity,
      padding: activeItem.contentPadding.add(
        EdgeInsets.only(bottom: bottomReservedSpace),
      ),
      child: RepaintBoundary(
        child: activeItem.child,
      ),
    )
        : _EmptyDockPanelContent(
      bottomReservedSpace: bottomReservedSpace,
    );

    final Widget panelStack = Stack(
      fit: StackFit.expand,
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
    );

    Widget panelBody;
    if (minimized) {
      panelBody = const SizedBox.shrink();
    } else if (shouldShrinkWrap) {
      final compactHeight = math.max(
        _compactPanelMinHeight,
        72 + bottomReservedSpace,
      );

      panelBody = SizedBox(
        width: double.infinity,
        height: compactHeight,
        child: panelStack,
      );
    } else {
      panelBody = Expanded(
        child: SizedBox(
          width: double.infinity,
          child: panelStack,
        ),
      );
    }

    final Widget content = isDragging
        ? Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
        Expanded(child: DragPlaceholder(accent: accent)),
      ],
    )
        : Column(
      mainAxisSize:
      shouldShrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
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
      child: SizedBox(
        width: double.infinity,
        child: content,
      ),
    );
  }
}

class _EmptyDockPanelContent extends StatelessWidget {
  final double bottomReservedSpace;

  const _EmptyDockPanelContent({
    required this.bottomReservedSpace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(12, 12, 12, 12 + bottomReservedSpace),
      alignment: Alignment.center,
      child: Text(
        'Nenhum conteúdo disponível neste painel',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}