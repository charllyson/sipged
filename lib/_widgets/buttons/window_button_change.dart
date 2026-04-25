import 'package:flutter/material.dart';

class WindowButtonChange extends StatefulWidget {
  final Color color;
  final VoidCallback? onTap;
  final bool disabled;
  final String? tooltip;
  final Widget? icon;

  /// Se true, o ícone aparece apenas no hover/press.
  /// Para botões de janela, geralmente vale deixar false.
  final bool iconOnlyOnHover;

  /// Tamanho visual do círculo.
  final double visualSize;

  /// Área clicável real.
  final double hitSize;

  const WindowButtonChange({
    super.key,
    required this.color,
    this.onTap,
    this.disabled = false,
    this.tooltip,
    this.icon,
    this.iconOnlyOnHover = false,
    this.visualSize = 16,
    this.hitSize = 28,
  });

  @override
  State<WindowButtonChange> createState() => _WindowButtonChangeState();
}

class _WindowButtonChangeState extends State<WindowButtonChange> {
  bool _hovering = false;
  bool _pressed = false;

  bool get _enabled => !widget.disabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
    widget.disabled ? widget.color.withValues(alpha: 0.45) : widget.color;

    final bool showIcon =
        widget.icon != null &&
            (!widget.iconOnlyOnHover || _hovering || _pressed || !_enabled);

    final double scale = _pressed ? 0.90 : 1.0;

    final Widget visualCircle = AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        width: widget.visualSize,
        height: widget.visualSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: effectiveColor,
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
                            Colors.white.withValues(
                              alpha: _hovering ? 0.40 : 0.28,
                            ),
                            Colors.white.withValues(alpha: 0.00),
                          ],
                          stops: const [0.0, 0.75],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
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
            AnimatedOpacity(
              opacity: showIcon ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedScale(
                scale: _hovering ? 1.0 : 0.96,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: IconTheme(
                  data: IconThemeData(
                    size: 9,
                    color: Colors.black.withValues(
                      alpha: widget.disabled ? 0.45 : (_pressed ? 0.95 : 0.85),
                    ),
                  ),
                  child: widget.icon ?? const SizedBox.shrink(),
                ),
              ),
            ),
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

    Widget buttonBody = SizedBox(
      width: widget.hitSize,
      height: widget.hitSize,
      child: Center(child: visualCircle),
    );

    if (_enabled) {
      buttonBody = MouseRegion(
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
          child: buttonBody,
        ),
      );
    } else {
      buttonBody = MouseRegion(
        cursor:
        widget.disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: buttonBody,
      );
    }

    if (widget.tooltip != null) {
      buttonBody = Tooltip(
        message: widget.tooltip!,
        child: buttonBody,
      );
    }

    return buttonBody;
  }
}