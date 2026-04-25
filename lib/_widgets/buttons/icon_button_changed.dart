import 'package:flutter/material.dart';

class IconButtonChanged extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool selected;
  final bool enabled;
  final bool isDragging;
  final bool showEditBadge;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;

  const IconButtonChanged({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.selected,
    this.enabled = true,
    this.isDragging = false,
    this.showEditBadge = false,
    this.size = 46,
    this.iconSize = 24,
    this.onTap,
  });

  @override
  State<IconButtonChanged> createState() => _IconButtonChangedState();
}

class _IconButtonChangedState extends State<IconButtonChanged> {
  static const Color _editBadgeRed = Color(0xFFE53935);

  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primary = scheme.primary;
    final isEnabled = widget.enabled;
    final hovered =
        (_hovered || widget.selected || widget.isDragging) && isEnabled;

    final backgroundColor = widget.selected
        ? (isDark ? const Color(0xFF1A1A22) : const Color(0xFFF8F8FA))
        : (isDark ? const Color(0xFF171717) : Colors.white);

    final Color borderColor;
    final double borderWidth;

    if (widget.selected) {
      borderColor = primary.withValues(alpha: 0.70);
      borderWidth = 1.1;
    } else if (hovered) {
      borderColor = primary.withValues(alpha: 0.28);
      borderWidth = 1;
    } else {
      borderColor = Colors.transparent;
      borderWidth = 1;
    }

    final iconColor = !isEnabled
        ? theme.disabledColor
        : widget.selected
        ? primary
        : hovered
        ? primary.withValues(alpha: 0.95)
        : primary.withValues(alpha: 0.82);

    final badgeSize = widget.size <= 36 ? 13.0 : 15.0;
    final badgeIconSize = widget.size <= 36 ? 8.0 : 9.0;

    return Opacity(
      opacity: isEnabled ? 1 : 0.42,
      child: MouseRegion(
        cursor: isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.forbidden,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Tooltip(
          message: widget.tooltip,
          waitDuration: const Duration(milliseconds: 250),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            scale: hovered ? 1.01 : 1,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: isEnabled ? widget.onTap : null,
                      child: Center(
                        child: Icon(
                          widget.icon,
                          size: widget.iconSize,
                          color: iconColor,
                        ),
                      ),
                    ),
                  ),
                  if (widget.showEditBadge)
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: badgeSize,
                        height: badgeSize,
                        decoration: BoxDecoration(
                          color: _editBadgeRed,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.18),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit,
                            size: badgeIconSize,
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
}