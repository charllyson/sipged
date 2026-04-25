import 'package:flutter/material.dart';
import 'package:sipged/_widgets/buttons/window_button_change.dart';

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
    final size = MediaQuery.of(context).size;

    final maxWidth = _isFullscreen ? size.width - 16 : (widget.width ?? 520);
    final usableHeight = _isFullscreen ? size.height - 16 : null;
    final outerPadding = _isFullscreen ? const EdgeInsets.all(8) : EdgeInsets.zero;

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
                maxWidth: maxWidth,
                maxHeight: usableHeight ?? double.infinity,
              ),
              child: SizedBox(
                height: usableHeight,
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
                      mainAxisSize:
                      _isFullscreen ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: (details) {
                            setState(() {
                              _offset += details.delta;
                            });
                          },
                          child: Container(
                            height: 38,
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
                          height: 1,
                          thickness: 1,
                          color: cs.outlineVariant.withValues(alpha: 0.4),
                        ),
                        if (_isFullscreen)
                          Expanded(
                            child: Padding(
                              padding: widget.contentPadding,
                              child: widget.child,
                            ),
                          )
                        else
                          Padding(
                            padding: widget.contentPadding,
                            child: widget.child,
                          ),
                      ],
                    ),
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