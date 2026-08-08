import 'package:flutter/material.dart';

import 'package:sipged/_widgets/cards/basic/basic_card.dart';

class SimpleCard extends StatelessWidget {
  const SimpleCard({
    super.key,
    required this.isDark,
    required this.primary,
    this.title,
    this.label,
    this.value,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 20,
  });

  final bool isDark;
  final Color primary;
  final String? title;
  final String? label;
  final String? value;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  bool get _hasTitle => title != null && title!.trim().isNotEmpty;
  bool get _hasValue => value != null && value!.trim().isNotEmpty;
  bool get _hasLabel => label != null && label!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return BasicCard(
      isDark: isDark,
      borderRadius: borderRadius,
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isVerySmall = constraints.maxHeight < 170;
          final isSmall = constraints.maxHeight < 210;

          final titleFontSize = isVerySmall ? 15.0 : 16.0;
          final labelFontSize = isVerySmall ? 18.0 : 20.0;
          final valueFontSize = isVerySmall ? 28.0 : (isSmall ? 34.0 : 40.0);

          return SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (_hasTitle) ...[
                  Text(
                    title!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF18181B),
                    ),
                  ),
                  SizedBox(height: isVerySmall ? 10 : 14),
                ],
                if (_hasLabel)
                  Text(
                    label!.trim(),
                    maxLines: isVerySmall ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: labelFontSize,
                      fontWeight: FontWeight.w600,
                      height: 1.1,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.82)
                          : const Color(0xFF374151),
                    ),
                  )
                else
                  _SimpleCardSkeletonBox(
                    isDark: isDark,
                    height: isVerySmall ? 18 : 20,
                    width: isVerySmall ? 120 : 170,
                    borderRadius: 4,
                  ),
                SizedBox(height: isVerySmall ? 8 : 10),
                if (_hasValue)
                  Text(
                    value!.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  )
                else
                  _SimpleCardSkeletonBox(
                    isDark: isDark,
                    height: isVerySmall ? 28 : (isSmall ? 34 : 40),
                    width: isVerySmall ? 90 : 130,
                    borderRadius: 6,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SimpleCardSkeletonBox extends StatefulWidget {
  const _SimpleCardSkeletonBox({
    required this.isDark,
    required this.height,
    required this.width,
    this.borderRadius = 6,
  });

  final bool isDark;
  final double height;
  final double width;
  final double borderRadius;

  @override
  State<_SimpleCardSkeletonBox> createState() => _SimpleCardSkeletonBoxState();
}

class _SimpleCardSkeletonBoxState extends State<_SimpleCardSkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.shade300;

    final highlightColor = widget.isDark
        ? Colors.white.withValues(alpha: 0.16)
        : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final width = bounds.width;
            final dx = (_controller.value * 2 - 1) * width;

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [
                0.25,
                0.50,
                0.75,
              ],
              transform: _SimpleCardSlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _SimpleCardSlidingGradientTransform extends GradientTransform {
  const _SimpleCardSlidingGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}