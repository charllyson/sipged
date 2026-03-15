import 'package:flutter/material.dart';
import 'package:sipged/_widgets/geo/toolbox/toolbox_action_item.dart';

class ToolboxIconButton extends StatefulWidget {
  final ToolboxActionItem action;
  final String? selectedToolId;
  final ValueChanged<String?>? onSelected;
  final double iconSize;
  final double buttonSize;

  const ToolboxIconButton({
    super.key,
    required this.action,
    required this.selectedToolId,
    required this.onSelected,
    required this.iconSize,
    required this.buttonSize,
  });

  @override
  State<ToolboxIconButton> createState() => _ToolboxIconButtonState();
}

class _ToolboxIconButtonState extends State<ToolboxIconButton> {
  static const Color _modernBlue = Color(0xFF3B82F6);
  static const Color _editBadgeRed = Color(0xFFE53935);

  bool _isHovering = false;

  ToolboxActionItem get action => widget.action;

  ToolboxActionItem get _displayAction {
    if (!action.hasChildren) return action;

    for (final child in action.children) {
      if (child.id == widget.selectedToolId) {
        return child;
      }
    }

    for (final child in action.children) {
      if (child.enabled) return child;
    }

    return action.children.first;
  }

  bool get _isSelected => _isActionSelected(action, widget.selectedToolId);

  bool _isActionSelected(ToolboxActionItem item, String? selectedId) {
    if (selectedId == null) return false;
    if (item.id == selectedId) return true;
    return item.children.any((child) => child.id == selectedId);
  }

  void _handleMainTap() {
    final displayAction = _displayAction;
    if (!displayAction.enabled) return;

    widget.onSelected?.call(displayAction.id);

    if (widget.selectedToolId != displayAction.id) {
      displayAction.onTap?.call();
    }
  }

  Future<void> _handleArrowTap(BuildContext context) async {
    if (!action.hasChildren) return;

    final selectedChild = await _showChildrenMenu(context);
    if (selectedChild == null) return;

    widget.onSelected?.call(selectedChild.id);
    selectedChild.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayAction = _displayAction;
    final isEnabled = displayAction.enabled;

    final iconColor = isEnabled
        ? (_isSelected ? _modernBlue : theme.iconTheme.color)
        : theme.disabledColor;

    final showContainer = _isSelected;
    final showHover = _isHovering && !_isSelected && isEnabled;

    final backgroundColor = showContainer
        ? _modernBlue.withValues(alpha: 0.14)
        : showHover
        ? theme.hoverColor.withValues(alpha: 0.08)
        : Colors.transparent;

    final borderColor = showContainer
        ? _modernBlue.withValues(alpha: 0.45)
        : showHover
        ? theme.dividerColor.withValues(alpha: 0.25)
        : Colors.transparent;

    return Tooltip(
      message: displayAction.tooltip,
      waitDuration: const Duration(milliseconds: 250),
      child: MouseRegion(
        onEnter: (_) {
          if (!_isHovering) {
            setState(() => _isHovering = true);
          }
        },
        onExit: (_) {
          if (_isHovering) {
            setState(() => _isHovering = false);
          }
        },
        cursor: isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        child: Opacity(
          opacity: isEnabled ? 1 : 0.42,
          child: Material(
            color: Colors.transparent,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: widget.buttonSize,
              height: widget.buttonSize,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: borderColor),
                boxShadow: _isSelected
                    ? [
                  BoxShadow(
                    color: _modernBlue.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
                    : null,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: InkWell(
                      onTap: isEnabled ? _handleMainTap : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Center(
                        child: Icon(
                          displayAction.icon,
                          size: widget.iconSize,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  if (action.hasChildren)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                          isEnabled ? () => _handleArrowTap(context) : null,
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(4),
                            topLeft: Radius.circular(4),
                          ),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: Icon(
                              Icons.arrow_drop_down,
                              size: 14,
                              color: iconColor?.withValues(alpha: 0.95),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_displayAction.showEditBadge)
                    Positioned(
                      right: action.hasChildren ? 14 : -2,
                      bottom: -2,
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: _editBadgeRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.edit,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<ToolboxActionItem?> _showChildrenMenu(BuildContext context) async {
    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox) return null;

    final overlayObject = Overlay.of(context).context.findRenderObject();
    if (overlayObject is! RenderBox) return null;

    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderObject.localToGlobal(Offset.zero, ancestor: overlayObject),
        renderObject.localToGlobal(
          renderObject.size.bottomRight(Offset.zero),
          ancestor: overlayObject,
        ),
      ),
      Offset.zero & overlayObject.size,
    );

    return showMenu<ToolboxActionItem>(
      context: context,
      position: position,
      items: action.children.map((child) {
        final isCurrent = child.id == _displayAction.id;

        return PopupMenuItem<ToolboxActionItem>(
          value: child,
          enabled: child.enabled,
          child: Opacity(
            opacity: child.enabled ? 1 : 0.45,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  child.icon,
                  size: 18,
                  color: isCurrent ? _modernBlue : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    child.tooltip,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isCurrent ? _modernBlue : null,
                      fontWeight:
                      isCurrent ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: _modernBlue,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }
}