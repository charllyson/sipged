import 'package:flutter/material.dart';

enum LoadingTreeDotsVariant {
  blue,
  white,
}

class LoadingTreeDots extends StatelessWidget {
  final double? size;
  final double strokeWidth;
  final Color? color;
  final bool centered;
  final LoadingTreeDotsVariant variant;

  /// Widget opcional exibido sobre a animação.
  ///
  /// Pode ser um Text simples:
  /// message: Text('Carregando...')
  ///
  /// Ou um Positioned/Align/Padding para controle total:
  /// message: const Positioned(
  ///   top: 8,
  ///   left: 0,
  ///   right: 0,
  ///   child: Text('Carregando...', textAlign: TextAlign.center),
  /// )
  final Widget? message;

  const LoadingTreeDots({
    super.key,
    this.size,
    this.strokeWidth = 8,
    this.color,
    this.centered = true,
    this.variant = LoadingTreeDotsVariant.blue,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final double resolvedSize = size ?? 100;

    final content = SizedBox(
      width: resolvedSize,
      height: resolvedSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _LinearLoadingAnimation(
            size: resolvedSize,
            strokeWidth: strokeWidth,
            color: color,
            variant: variant,
          ),
          if (message != null)
            Positioned(
              top: 0,
              left: -resolvedSize,
              right: -resolvedSize,
              child: Center(
                child: _SingleLineMessage(
                  child: message!,
                ),
              ),
            ),
        ],
      ),
    );

    if (centered) {
      return Center(child: content);
    }

    return content;
  }
}

class _SingleLineMessage extends StatelessWidget {
  const _SingleLineMessage({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (child is Text) {
      final text = child as Text;

      return Text(
        text.data ?? '',
        key: text.key,
        textAlign: text.textAlign ?? TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
        style: text.style,
        strutStyle: text.strutStyle,
        textDirection: text.textDirection,
        locale: text.locale,
        textScaler: text.textScaler,
        semanticsLabel: text.semanticsLabel,
        textWidthBasis: text.textWidthBasis,
        textHeightBehavior: text.textHeightBehavior,
      );
    }

    return DefaultTextStyle.merge(
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
      child: child,
    );
  }
}

class _LinearLoadingAnimation extends StatefulWidget {
  const _LinearLoadingAnimation({
    required this.size,
    required this.strokeWidth,
    required this.color,
    required this.variant,
  });

  final double size;
  final double strokeWidth;
  final Color? color;
  final LoadingTreeDotsVariant variant;

  @override
  State<_LinearLoadingAnimation> createState() => _LinearLoadingAnimationState();
}

class _LinearLoadingAnimationState extends State<_LinearLoadingAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<AlignmentGeometry> _alignment;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,

      /// Mais lento e mais elegante.
      duration: const Duration(milliseconds: 1850),
    )..repeat(reverse: true);

    _opacity = Tween<double>(
      begin: 0.58,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    _alignment = Tween<AlignmentGeometry>(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _baseColor(BuildContext context) {
    if (widget.color != null) return widget.color!;

    switch (widget.variant) {
      case LoadingTreeDotsVariant.blue:
        return const Color(0xFF1976D2);

      case LoadingTreeDotsVariant.white:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = _baseColor(context);
    final isWhite = widget.variant == LoadingTreeDotsVariant.white;

    final backgroundColor = isWhite
        ? Colors.white.withValues(alpha: 0.18)
        : baseColor.withValues(alpha: 0.12);

    final glowColor = isWhite
        ? Colors.white.withValues(alpha: 0.95)
        : baseColor.withValues(alpha: 0.95);

    final width = (widget.size * 0.68).clamp(68.0, 190.0).toDouble();
    final height = widget.strokeWidth.clamp(3.0, 8.0).toDouble();
    final thumbWidth = (width * 0.34).clamp(28.0, 72.0).toDouble();

    return SizedBox(
      width: width,
      height: widget.size,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: width,
            height: height,
            color: backgroundColor,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Align(
                  alignment: _alignment.value,
                  child: Opacity(
                    opacity: _opacity.value,
                    child: Container(
                      width: thumbWidth,
                      height: height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            glowColor.withValues(alpha: 0.10),
                            glowColor,
                            glowColor.withValues(alpha: 0.10),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}