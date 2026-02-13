import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sipged/_widgets/toolBox/tool_dock.dart';
import 'package:sipged/_widgets/toolBox/tool_slot.dart';

class ToolButton extends StatefulWidget {
  const ToolButton({
    super.key,
    required this.slot,
    required this.displayIcon,
    required this.isOpen,
    required this.isSelected,
    required this.side,
    required this.buttonSize,
    required this.iconSize,
    required this.iconColor,
    required this.activeBorder,
    required this.layerLink,
    this.onTap,
    this.onLongPress,
    this.onHoverOpen,
  });

  final ToolSlot slot;
  final IconData displayIcon;
  final bool isOpen;       // não usamos mais para decidir cor azul
  final bool isSelected;   // APENAS isto deixa azul
  final AIDockSide side;
  final double buttonSize;
  final double iconSize;
  final Color iconColor;
  final Color activeBorder;
  final LayerLink layerLink;

  final VoidCallback? onTap;
  final void Function(Size btnSize)? onLongPress;
  final void Function(Size btnSize)? onHoverOpen;

  @override
  State<ToolButton> createState() => _ToolButtonState();
}

class _ToolButtonState extends State<ToolButton> {
  static const _hoverOrange = Color(0xFFFFA500);

  Timer? _lpTimer;
  Timer? _hoverOpenTimer;

  bool _hover = false;

  void _startMaybeLongPress() {
    _lpTimer?.cancel();
    _lpTimer = Timer(const Duration(milliseconds: 350), () {
      if (widget.onLongPress != null) {
        widget.onLongPress!.call(Size(widget.buttonSize, widget.buttonSize));
      }
    });
  }

  void _cancelMaybeLongPress() {
    _lpTimer?.cancel();
  }

  void _scheduleHoverOpen() {
    if (widget.onHoverOpen == null) return;
    _hoverOpenTimer?.cancel();
    _hoverOpenTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || !_hover) return;
      widget.onHoverOpen!.call(Size(widget.buttonSize, widget.buttonSize));
    });
  }

  void _cancelHoverOpen() {
    _hoverOpenTimer?.cancel();
  }

  @override
  void dispose() {
    _lpTimer?.cancel();
    _hoverOpenTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔵 Azul só quando selecionado (clique). Nunca por hover/abertura do flyout.
    final bool isActiveByClick = widget.isSelected;
    final Color borderColor = isActiveByClick
        ? widget.activeBorder                          // azul clarinho (selecionado)
        : (_hover ? _hoverOrange : Colors.black26);     // laranja no hover, cinza normal
    final double borderWidth = isActiveByClick || _hover ? 1.0 : 1.0;

    return CompositedTransformTarget(
      link: widget.layerLink,
      child: Tooltip(
        message: widget.slot.tooltip,
        child: MouseRegion(
          onEnter: (_) {
            _hover = true;
            setState(() {});
            if (widget.slot.flyout.isNotEmpty) _scheduleHoverOpen();
          },
          onExit: (_) {
            _hover = false;
            _cancelHoverOpen();
            setState(() {});
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => _startMaybeLongPress(),
            onTapUp: (_) {
              _cancelMaybeLongPress();
              widget.onTap?.call(); // clique = seleção
            },
            onTapCancel: _cancelMaybeLongPress,
            onSecondaryTapDown: (_) {
              if (widget.onLongPress != null) {
                widget.onLongPress!.call(Size(widget.buttonSize, widget.buttonSize));
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              width: widget.buttonSize,
              height: widget.buttonSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: borderColor, width: borderWidth),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      widget.displayIcon,
                      size: widget.iconSize,
                      color: widget.iconColor,
                    ),
                  ),
                  if (widget.slot.flyout.isNotEmpty)
                    Positioned(
                      right: widget.side == AIDockSide.left ? 1 : null,
                      left:  widget.side == AIDockSide.right ? 1 : null,
                      bottom: 1,
                      child: Icon(
                        Icons.arrow_right,
                        size: 11,
                        color: widget.iconColor.withValues(alpha: 0.9),
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
