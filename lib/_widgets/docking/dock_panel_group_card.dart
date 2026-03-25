import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:sipged/_widgets/docking/dock_panel_types.dart';
import 'package:sipged/_widgets/docking/dock_panel_workspace_config.dart';

class DockPanelGroupCard extends StatelessWidget {
  final DockPanelGroupData group;
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

  const DockPanelGroupCard({
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

    final shouldShrinkWrap = !isFloating && group.shrinkWrapOnMainAxis;

    final contentBody = RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: activeItem.contentPadding,
        child: activeItem.child,
      ),
    );

    final content = isDragging
        ? Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DraggableHeader(
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
          _DragPlaceholder(accent: accent)
        else
          Expanded(child: _DragPlaceholder(accent: accent)),
      ],
    )
        : Column(
      mainAxisSize:
      shouldShrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      children: [
        _DraggableHeader(
          group: group,
          accent: accent,
          isFloating: isFloating,
          onToggleFloating: onToggleFloating,
          onHide: onHide,
          onDragStarted: onDragStarted,
          onDragUpdate: onDragUpdate,
          onDragEnd: onDragEnd,
        ),
        if (group.items.length > 1)
          _DockTabs(
            group: group,
            accent: accent,
            onTabSelected: onTabSelected,
          ),
        if (shouldShrinkWrap)
          contentBody
        else
          Expanded(child: contentBody),
        if (isFloating)
          _ResizeHandle(
            onPanStart: onResizeStart,
            onPanUpdate: onResizeUpdate,
            onPanEnd: onResizeEnd,
          ),
      ],
    );

    return _PanelContainer(
      isFloating: isFloating,
      fill: fill,
      borderColor: borderColor,
      shadowColor: shadowColor,
      child: content,
    );
  }
}

class _PanelContainer extends StatelessWidget {
  final Widget child;
  final bool isFloating;
  final Color fill;
  final Color borderColor;
  final Color shadowColor;

  const _PanelContainer({
    required this.child,
    required this.isFloating,
    required this.fill,
    required this.borderColor,
    required this.shadowColor,
  });

  @override
  Widget build(BuildContext context) {
    if (!isFloating) {
      return Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: DockPanelWorkspaceConfig.panelRadius,
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: DockPanelWorkspaceConfig.panelRadius,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _DraggableHeader extends StatelessWidget {
  final DockPanelGroupData group;
  final Color accent;
  final bool isFloating;
  final VoidCallback onToggleFloating;
  final VoidCallback onHide;

  final VoidCallback onDragStarted;
  final void Function(DragUpdateDetails details) onDragUpdate;
  final void Function(DraggableDetails details) onDragEnd;

  const _DraggableHeader({
    required this.group,
    required this.accent,
    required this.isFloating,
    required this.onToggleFloating,
    required this.onHide,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Draggable<DockDragPayload>(
      data: DockDragPayload(groupId: group.id),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      rootOverlay: true,
      feedback: _LightweightDragFeedback(group: group, accent: accent),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: onDragStarted,
      onDragUpdate: onDragUpdate,
      onDragEnd: onDragEnd,
      child: _GroupHeaderBar(
        group: group,
        accent: accent,
        isFloating: isFloating,
        onToggleFloating: onToggleFloating,
        onHide: onHide,
      ),
    );
  }
}

class _LightweightDragFeedback extends StatelessWidget {
  final DockPanelGroupData group;
  final Color accent;

  const _LightweightDragFeedback({
    required this.group,
    required this.accent,
  });

  double _feedbackWidth() {
    switch (group.area) {
      case DockArea.left:
      case DockArea.right:
        return group.dockExtent.clamp(220, 520).toDouble();
      case DockArea.top:
      case DockArea.bottom:
        return math.max(320, group.floatingSize.width);
      case DockArea.floating:
        return group.floatingSize.width;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = math.min(280, _feedbackWidth()).toDouble();

    return Material(
      color: Colors.transparent,
      child: IgnorePointer(
        child: Container(
          width: width,
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.96),
            borderRadius: DockPanelWorkspaceConfig.panelRadius,
            border: Border.all(
              color: accent.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              if (group.icon != null) ...[
                const SizedBox(width: 6),
                Icon(group.icon, size: 16, color: accent),
              ],
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeaderBar extends StatelessWidget {
  final DockPanelGroupData group;
  final Color accent;
  final bool isFloating;
  final VoidCallback onToggleFloating;
  final VoidCallback onHide;

  const _GroupHeaderBar({
    required this.group,
    required this.accent,
    required this.isFloating,
    required this.onToggleFloating,
    required this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerColor =
    isDark ? const Color(0xFF2A2F3A) : const Color(0xFFF2F3F5);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    final textColor = isDark
        ? Colors.white.withValues(alpha: 0.90)
        : Colors.black.withValues(alpha: 0.85);

    return MouseRegion(
      cursor: SystemMouseCursors.grab,
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: headerColor,
          border: Border(
            bottom: BorderSide(color: borderColor),
          ),
        ),
        child: Row(
          children: [
            if (group.icon != null) ...[
              const SizedBox(width: 6),
              Icon(group.icon, size: 16, color: textColor),
            ],
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                group.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            IconButton(
              tooltip: isFloating ? 'Ancorar à esquerda' : 'Soltar painel',
              visualDensity: VisualDensity.compact,
              onPressed: onToggleFloating,
              icon: Icon(
                isFloating ? Icons.close_fullscreen : Icons.open_in_full,
                size: 18,
                color: textColor,
              ),
            ),
            IconButton(
              tooltip: 'Ocultar painel',
              visualDensity: VisualDensity.compact,
              onPressed: onHide,
              icon: Icon(Icons.close, size: 18, color: textColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _DockTabs extends StatelessWidget {
  final DockPanelGroupData group;
  final Color accent;
  final ValueChanged<String> onTabSelected;

  const _DockTabs({
    required this.group,
    required this.accent,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final activeId = group.activeItem?.id;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tabsBg = isDark
        ? const Color(0xFF2A2F3A)
        : const Color(0xFFF2F3F5);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.08);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: tabsBg,
        border: Border(
          bottom: BorderSide(color: borderColor),
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 4, right: 4, top: 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: group.items.map((item) {
              final active = item.id == activeId;

              return _ExcelLikeTab(
                title: item.title,
                active: active,
                accent: accent,
                onTap: () => onTabSelected(item.id),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _ExcelLikeTab extends StatefulWidget {
  final String title;
  final bool active;
  final Color accent;
  final VoidCallback onTap;

  const _ExcelLikeTab({
    required this.title,
    required this.active,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_ExcelLikeTab> createState() => _ExcelLikeTabState();
}

class _ExcelLikeTabState extends State<_ExcelLikeTab> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final inactiveTextColor = isDark
        ? Colors.white.withValues(alpha: 0.84)
        : Colors.black.withValues(alpha: 0.78);

    final bgColor = widget.active
        ? (isDark ? const Color(0xFF182033) : Colors.white)
        : (_hovered
        ? (isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.04))
        : Colors.transparent);

    final borderColor = widget.active
        ? widget.accent.withValues(alpha: 0.55)
        : (isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
          onTap: widget.onTap,
          child: Container(
            height: 28,
            margin: const EdgeInsets.only(right: 2),
            constraints: const BoxConstraints(minWidth: 7),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
              border: Border(
                top: BorderSide(color: borderColor),
                left: BorderSide(color: borderColor),
                right: BorderSide(color: borderColor),
                // sem bottom
              ),
            ),
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: widget.active ? FontWeight.w700 : FontWeight.w600,
                color: widget.active ? widget.accent : inactiveTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DragPlaceholder extends StatelessWidget {
  final Color accent;

  const _DragPlaceholder({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        borderRadius: DockPanelWorkspaceConfig.panelRadius,
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
        color: accent.withValues(alpha: 0.05),
      ),
    );
  }
}

class _ResizeHandle extends StatelessWidget {
  final VoidCallback onPanStart;
  final void Function(DragUpdateDetails details) onPanUpdate;
  final void Function(DragEndDetails details) onPanEnd;

  const _ResizeHandle({
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: GestureDetector(
        onPanStart: (_) => onPanStart(),
        onPanUpdate: onPanUpdate,
        onPanEnd: onPanEnd,
        child: Padding(
          padding: const EdgeInsets.only(right: 8, bottom: 8),
          child: Icon(
            Icons.drag_handle,
            size: 18,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withValues(alpha: 0.70),
          ),
        ),
      ),
    );
  }
}