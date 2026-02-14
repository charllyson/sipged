import 'package:flutter/material.dart';

class WindowCircleButton extends StatefulWidget {
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;
  final String? tooltip;
  final Widget? icon;

  /// ✅ macOS-like: ícone aparece somente ao hover/press
  final bool iconOnlyOnHover;

  const WindowCircleButton({
    super.key,
    required this.color,
    this.onTap,
    this.disabled = false,
    this.tooltip,
    this.icon,
    this.iconOnlyOnHover = true,
  });

  @override
  State<WindowCircleButton> createState() => _WindowCircleButtonState();
}

class _WindowCircleButtonState extends State<WindowCircleButton> {
  bool _hovering = false;
  bool _pressed = false;

  bool get _enabled => !widget.disabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    const size = 16.0;

    final effectiveColor =
    widget.disabled ? widget.color.withValues(alpha: 0.45) : widget.color;

    final bool showIcon =
        widget.icon != null && (!widget.iconOnlyOnHover || _hovering || _pressed);

    final double scale = _pressed ? 0.90 : 1.0;

    Widget circle = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveColor,

          // ✅ sombra macOS: bem leve no normal, sobe no hover
          boxShadow: [
            BoxShadow(
              blurRadius: _hovering ? 5 : 2,
              offset: const Offset(0, 0.75),
              color: Colors.black.withValues(alpha: _hovering ? 0.28 : 0.22),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ✅ gloss / brilho superior interno (macOS)
            if (_enabled)
              Positioned.fill(
                child: ClipOval(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withValues(alpha: _hovering ? 0.40 : 0.28),
                            Colors.white.withValues(alpha: 0.00),
                          ],
                          stops: const [0.0, 0.75],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ highlight radial no hover (bem sutil)
            if (_hovering && _enabled)
              Positioned.fill(
                child: ClipOval(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.9,
                          colors: [
                            Colors.white.withValues(alpha: 0.22),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.75],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ✅ ícone aparece no hover/press com fade
            AnimatedOpacity(
              opacity: showIcon ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedScale(
                scale: _hovering ? 1.0 : 0.92,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: IconTheme(
                  data: IconThemeData(
                    size: 9,
                    color: Colors.black.withValues(alpha: _pressed ? 0.95 : 0.85),
                  ),
                  child: widget.icon ?? const SizedBox.shrink(),
                ),
              ),
            ),

            // ✅ aro interno sutil (dá acabamento)
            Positioned.fill(
              child: ClipOval(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.12),
                        width: 0.6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (_enabled) {
      circle = MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() {
          _hovering = false;
          _pressed = false;
        }),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap?.call();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: circle,
        ),
      );
    } else {
      // mesmo desabilitado: mantém hover false
      circle = MouseRegion(
        cursor: widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: circle,
      );
    }

    if (widget.tooltip != null) {
      circle = Tooltip(
        message: widget.tooltip!,
        child: circle,
      );
    }

    return circle;
  }
}
