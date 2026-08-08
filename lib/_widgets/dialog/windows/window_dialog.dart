import 'package:flutter/material.dart';
import 'package:sipged/_widgets/dialog/windows/window_button_change.dart';

class WindowDialog extends StatefulWidget {
  final Widget child;
  final String? title;
  final double? width;
  final EdgeInsets contentPadding;

  final VoidCallback? onClose;
  final VoidCallback? onToggleFullscreen;
  final bool showMinimize;

  const WindowDialog({
    super.key,
    required this.child,
    this.title,
    this.width,
    this.contentPadding = const EdgeInsets.fromLTRB(12, 12, 12, 12),
    this.onClose,
    this.onToggleFullscreen,
    this.showMinimize = false,
  });

  @override
  State<WindowDialog> createState() => _WindowDialogState();
}

class _WindowDialogState extends State<WindowDialog> {
  Offset _offset = Offset.zero;
  bool _isFullscreen = false;

  static const double _headerHeight = 38.0;
  static const double _dividerHeight = 1.0;
  static const double _normalOuterMargin = 18.0;
  static const double _fullscreenOuterMargin = 8.0;

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _offset = Offset.zero;
    });

    widget.onToggleFullscreen?.call();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    final maxWidth = _isFullscreen
        ? size.width - (_fullscreenOuterMargin * 2)
        : (widget.width ?? 520).clamp(
      320.0,
      size.width - (_normalOuterMargin * 2),
    );

    final maxHeight = _isFullscreen
        ? size.height - (_fullscreenOuterMargin * 2)
        : size.height - (_normalOuterMargin * 2);

    final outerPadding = _isFullscreen
        ? const EdgeInsets.all(_fullscreenOuterMargin)
        : const EdgeInsets.all(_normalOuterMargin);

    const backgroundColor = Color(0xFFF7F7FA);
    const borderRadius = 14.0;

    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: outerPadding,
          child: Transform.translate(
            offset: _offset,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth.toDouble(),
                maxHeight: maxHeight,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: cs.outline.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                      color: Colors.black.withValues(alpha: 0.20),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(borderRadius),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onPanUpdate: (details) {
                          if (_isFullscreen) return;

                          setState(() {
                            _offset += details.delta;
                          });
                        },
                        child: Container(
                          height: _headerHeight,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFEDEDEF),
                                Color(0xFFE2E2E6),
                              ],
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Row(
                                  children: [
                                    const SizedBox(width: 8),
                                    WindowButtonChange(
                                      color: const Color(0xFFE5534B),
                                      tooltip: 'Fechar',
                                      onTap: widget.onClose,
                                      icon: const Icon(Icons.close),
                                      iconOnlyOnHover: false,
                                      hitSize: 28,
                                      visualSize: 16,
                                    ),
                                    WindowButtonChange(
                                      color: const Color(0xFFFACD4A),
                                      tooltip: 'Minimizar',
                                      onTap: widget.showMinimize ? () {} : null,
                                      disabled: !widget.showMinimize,
                                      icon: const Icon(Icons.remove),
                                      iconOnlyOnHover: false,
                                      hitSize: 28,
                                      visualSize: 16,
                                    ),
                                    WindowButtonChange(
                                      color: const Color(0xFF32C554),
                                      tooltip: _isFullscreen
                                          ? 'Sair da tela cheia'
                                          : 'Tela cheia',
                                      onTap: _toggleFullscreen,
                                      icon: Icon(
                                        _isFullscreen
                                            ? Icons.fullscreen_exit
                                            : Icons.fullscreen,
                                      ),
                                      iconOnlyOnHover: false,
                                      hitSize: 28,
                                      visualSize: 16,
                                    ),
                                  ],
                                ),
                              ),
                              if (widget.title != null)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 110,
                                    ),
                                    child: Text(
                                      widget.title!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      Divider(
                        height: _dividerHeight,
                        thickness: _dividerHeight,
                        color: cs.outlineVariant.withValues(alpha: 0.4),
                      ),
                      Flexible(
                        child: Padding(
                          padding: widget.contentPadding,
                          child: widget.child,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}