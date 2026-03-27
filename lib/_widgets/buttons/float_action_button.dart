import 'package:flutter/material.dart';

class FloatActionButton extends StatefulWidget {
  const FloatActionButton({
    super.key,
    required this.tooltip,
    required this.cursor,
    required this.iconColor,
    required this.borderColor,
    required this.borderHoverColor,
    this.icon,
    this.customChild,
    this.size = 30,
    this.width,
    this.height,
    this.iconSize = 16,
    this.borderRadius = 8,
    this.backgroundColor,
    this.hoverBackgroundColor,
    this.shadowColor,
    this.shadowBlurRadius = 8,
    this.shadowOffset = const Offset(0, 2),
    this.padding = EdgeInsets.zero,
    this.alignment,
    this.onTap,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  final String tooltip;
  final IconData? icon;
  final Widget? customChild;
  final MouseCursor cursor;
  final Color iconColor;
  final Color borderColor;
  final Color borderHoverColor;

  final double size;
  final double? width;
  final double? height;
  final double iconSize;
  final double borderRadius;

  final Color? backgroundColor;
  final Color? hoverBackgroundColor;
  final Color? shadowColor;
  final double shadowBlurRadius;
  final Offset shadowOffset;
  final EdgeInsets padding;
  final Alignment? alignment;

  final VoidCallback? onTap;
  final GestureDragStartCallback? onPanStart;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureDragEndCallback? onPanEnd;

  @override
  State<FloatActionButton> createState() => _FloatActionButtonState();
}

class _FloatActionButtonState extends State<FloatActionButton> {
  bool _hovered = false;

  bool get _hasDragHandlers =>
      widget.onPanStart != null ||
          widget.onPanUpdate != null ||
          widget.onPanEnd != null;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        widget.backgroundColor ?? Colors.white.withValues(alpha: 0.94);

    final hoverBackgroundColor =
        widget.hoverBackgroundColor ?? Colors.white.withValues(alpha: 0.98);

    final resolvedShadowColor =
        widget.shadowColor ?? Colors.black.withValues(alpha: 0.10);

    final resolvedBorderColor =
    _hovered ? widget.borderHoverColor : widget.borderColor;

    final resolvedWidth = widget.width ?? widget.size;
    final resolvedHeight = widget.height ?? widget.size;

    final innerChild = widget.customChild ??
        Icon(
          widget.icon,
          size: widget.iconSize,
          color: widget.iconColor,
        );

    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: resolvedWidth,
      height: resolvedHeight,
      decoration: BoxDecoration(
        color: _hovered ? hoverBackgroundColor : backgroundColor,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: resolvedBorderColor),
        boxShadow: [
          BoxShadow(
            color: resolvedShadowColor,
            blurRadius: widget.shadowBlurRadius,
            offset: widget.shadowOffset,
          ),
        ],
      ),
      child: innerChild,
    );

    final interactiveChild = _hasDragHandlers
        ? GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onPanStart: widget.onPanStart,
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: widget.onPanEnd,
      child: content,
    )
        : InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: content,
    );

    final wrapped = Padding(
      padding: widget.padding,
      child: Tooltip(
        message: widget.tooltip,
        child: MouseRegion(
          cursor: widget.cursor,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: interactiveChild,
        ),
      ),
    );

    if (widget.alignment != null) {
      return Align(
        alignment: widget.alignment!,
        child: wrapped,
      );
    }

    return wrapped;
  }
}