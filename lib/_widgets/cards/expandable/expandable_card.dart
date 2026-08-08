import 'package:flutter/material.dart';

typedef ExpandableCardValueFormatter = String Function(double value);

class ExpandableCard extends StatefulWidget {
  const ExpandableCard({
    super.key,
    required this.title,
    this.icon,
    this.colorIcon = Colors.blueAccent,
    this.valoresIndividuais = const <double?>[],
    this.totalOverride,
    this.valorTotal,
    this.loading = false,
    this.formatAsCurrency = true,
    this.valueFormatter,
    this.subTitles,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 12,
    this.backgroundColor,
    this.borderColor,
    this.shadowColor,
    this.elevation = 8,
    this.minWidth = 180,
  });

  final String title;
  final IconData? icon;
  final Color colorIcon;

  final List<double?> valoresIndividuais;
  final double? totalOverride;
  final Future<double?>? valorTotal;
  final bool loading;

  /// Mantido por compatibilidade.
  ///
  /// Se [valueFormatter] for informado, ele tem prioridade.
  /// Se [formatAsCurrency] for true e [valueFormatter] for null,
  /// usa fallback genérico com 2 casas decimais.
  final bool formatAsCurrency;

  /// Formatador externo.
  ///
  /// No SIPGED, use:
  /// valueFormatter: SipGedFormatMoney.doubleToText
  final ExpandableCardValueFormatter? valueFormatter;

  final List<String>? subTitles;

  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final double elevation;
  final double minWidth;

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard> {
  bool expanded = false;

  bool get _hasBreakdown => widget.valoresIndividuais.isNotEmpty;

  String _formatValue(double? value) {
    final safeValue = value ?? 0.0;

    if (widget.valueFormatter != null) {
      return widget.valueFormatter!(safeValue);
    }

    if (widget.formatAsCurrency) {
      return safeValue.toStringAsFixed(2);
    }

    final isInteger = safeValue % 1 == 0;

    if (isInteger) {
      return safeValue.toInt().toString();
    }

    return safeValue.toString();
  }

  Widget _totalText(double? value) {
    return Text(
      _formatValue(value),
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _totalWidget({
    required bool isDark,
  }) {
    if (widget.loading) {
      return ExpandableCardSkeletonBox(
        isDark: isDark,
        width: 60,
        height: 14,
        borderRadius: 4,
      );
    }

    if (widget.totalOverride != null) {
      return _totalText(widget.totalOverride);
    }

    if (widget.valorTotal != null) {
      return FutureBuilder<double?>(
        future: widget.valorTotal,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ExpandableCardSkeletonBox(
              isDark: isDark,
              width: 60,
              height: 14,
              borderRadius: 4,
            );
          }

          return _totalText(snapshot.data);
        },
      );
    }

    final soma = widget.valoresIndividuais.fold<double>(
      0.0,
          (acc, value) => acc + (value ?? 0.0),
    );

    return _totalText(soma);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = widget.backgroundColor ??
        (isDark ? const Color(0xFF111827) : Colors.white);

    final borderColor = widget.borderColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    final shadowColor = widget.shadowColor ??
        Colors.black.withValues(alpha: isDark ? 0.24 : 0.08);

    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: widget.minWidth,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: borderColor,
            ),
            boxShadow: [
              if (widget.elevation > 0)
                BoxShadow(
                  color: shadowColor,
                  blurRadius: widget.elevation,
                  offset: Offset(0, widget.elevation * 0.35),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _hasBreakdown
                    ? () {
                  setState(() {
                    expanded = !expanded;
                  });
                }
                    : null,
                child: Row(
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        color: widget.colorIcon,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF111827),
                        ),
                      ),
                    ),
                    if (_hasBreakdown)
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 200),
                        turns: expanded ? 0.5 : 0,
                        child: Icon(
                          Icons.expand_more,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: _totalWidget(
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox.shrink(),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _buildBreakdown(
                    isDark: isDark,
                  ),
                ),
                crossFadeState: expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 250),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreakdown({
    required bool isDark,
  }) {
    return Column(
      children: List.generate(widget.valoresIndividuais.length, (index) {
        final label = widget.subTitles != null && index < widget.subTitles!.length
            ? widget.subTitles![index]
            : 'Valor ${index + 1}';

        final valor = widget.valoresIndividuais[index] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$label:',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatValue(valor),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ExpandableCardSkeletonBox extends StatefulWidget {
  const ExpandableCardSkeletonBox({
    super.key,
    required this.isDark,
    required this.width,
    required this.height,
    this.borderRadius = 6,
  });

  final bool isDark;
  final double width;
  final double height;
  final double borderRadius;

  @override
  State<ExpandableCardSkeletonBox> createState() =>
      _ExpandableCardSkeletonBoxState();
}

class _ExpandableCardSkeletonBoxState extends State<ExpandableCardSkeletonBox>
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
            final dx = (_controller.value * 2 - 1) * bounds.width;

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
              transform: _ExpandableCardSlidingGradientTransform(dx),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

class _ExpandableCardSlidingGradientTransform extends GradientTransform {
  const _ExpandableCardSlidingGradientTransform(this.dx);

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0, 0);
  }
}