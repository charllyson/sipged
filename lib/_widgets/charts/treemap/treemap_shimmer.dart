// lib/_widgets/charts/treemap/treemap_shimmer.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum TreemapShimDirection { vertical, horizontal }

class TreemapShimmer extends StatelessWidget {
  const TreemapShimmer({
    super.key,
    this.altura = 300,
    this.cardWidth,
    this.legendItems = 8,
    this.borderRadius = 14,
    this.padding = const EdgeInsets.all(12),
    this.direction = TreemapShimDirection.horizontal,
    this.expandToMaxWidth = false,
    this.targetCellSide = 140, // tamanho “médio” de cada bloco
    this.extraWidthFactor = 2.2, // quão mais largo que a tela
  });

  /// Altura do grid (a área interna do shimmer)
  final double altura;

  /// Largura “alvo” do conteúdo (pode vir do LayoutBuilder)
  final double? cardWidth;

  /// Quantos itens “falsos” na legenda
  final int legendItems;

  final double borderRadius;
  final EdgeInsets padding;

  /// Layout do skeleton
  final TreemapShimDirection direction;

  /// Quando true, tenta ocupar toda a largura do pai
  final bool expandToMaxWidth;

  /// Lado alvo por célula para estimar largura base quando horizontal
  final double targetCellSide;

  /// Fator de largura extra do canvas quando horizontal (se não houver constraints)
  final double extraWidthFactor;

  @override
  Widget build(BuildContext context) {
    // Nada de Card aqui – só o conteúdo; o BasicCard é o wrapper.
    final content = Padding(
      padding: padding,
      child: direction == TreemapShimDirection.horizontal
          ? _buildHorizontal(context)
          : _buildVertical(context),
    );

    return SizedBox(
      width: cardWidth ?? double.infinity,
      child: content,
    );
  }

  // --- LAYOUT HORIZONTAL: grid largo com scroll X + legenda à direita
  Widget _buildHorizontal(BuildContext context) {
    final legend = _LegendColumn(items: legendItems);

    return SizedBox(
      height: altura, // altura fixa -> não vaza pra baixo
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // GRID com rolagem horizontal
          Expanded(
            child: LayoutBuilder(
              builder: (context, c) {
                // define uma largura “base” grande pra simular muitos blocos
                final baseWidth = expandToMaxWidth
                    ? c.maxWidth
                    : math.max(
                  c.maxWidth,
                  (c.maxWidth.isFinite
                      ? c.maxWidth * extraWidthFactor
                      : 1200.0) // fallback
                      .clamp(c.maxWidth, 4000.0),
                );

                (baseWidth / targetCellSide).clamp(4, 20).round();

                final grid = _Shimmer(
                  child: CustomPaint(
                    painter: _BlocksPainter(
                      base: Colors.grey.shade300,
                      borderRadius: 8,
                      values: const [40, 25, 15, 10, 5, 5], // pesos fake
                    ),
                    size: Size(double.infinity, altura),
                  ),
                );

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: baseWidth,
                    height: altura,
                    child: grid,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // LEGENDA à direita (com rolagem vertical se necessário)
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: _AutoScrollColumn(child: legend),
            ),
          ),
        ],
      ),
    );
  }

  // --- LAYOUT VERTICAL (mantido p/ compatibilidade)
  Widget _buildVertical(BuildContext context) {
    final grid = _Shimmer(
      child: _FakeTreemapGrid(height: altura, borderRadius: borderRadius),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: altura, width: double.infinity, child: grid),
        const SizedBox(height: 12),
        _LegendWrap(items: legendItems),
      ],
    );
  }
}

// -------------------- PINTURA DO SKELETON --------------------

class _FakeTreemapGrid extends StatelessWidget {
  const _FakeTreemapGrid({
    required this.height,
    this.borderRadius = 14,
  });

  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final w = c.maxWidth;
      return CustomPaint(
        painter: _BlocksPainter(
          base: _base(context),
          borderRadius: borderRadius,
          values: List.generate(14, (_) => 100),
        ),
        child: SizedBox(height: height, width: w),
      );
    });
  }

  Color _base(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withOpacity(.10)
          : Colors.grey.shade300;
}

class _BlocksPainter extends CustomPainter {
  _BlocksPainter({
    required this.base,
    required this.borderRadius,
    required this.values,
  });

  final Color base;
  final double borderRadius;
  final List<double> values; // pesos simulados (ex: [40, 25, 15, 10, 5, 5])

  @override
  void paint(Canvas canvas, Size size) {
    final rects = _squarify(values, Offset.zero & size);

    final paint = Paint()
      ..color = base
      ..isAntiAlias = true;

    const gutter = 6.0;

    for (final r in rects) {
      final rr = RRect.fromRectAndRadius(
        r.deflate(gutter / 2),
        Radius.circular(borderRadius),
      );
      canvas.drawRRect(rr, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Algoritmo squarify bem simples (divide horizontal/vertical mantendo proporção)
List<Rect> _squarify(List<double> values, Rect bounds) {
  final total = values.fold<double>(0, (s, v) => s + v);
  final rects = <Rect>[];

  double x = bounds.left;
  double y = bounds.top;
  double w = bounds.width;
  double h = bounds.height;

  bool horizontal = w > h;

  for (final v in values) {
    final frac = v / total;
    if (horizontal) {
      final bw = w * frac;
      rects.add(Rect.fromLTWH(x, y, bw, h));
      x += bw;
    } else {
      final bh = h * frac;
      rects.add(Rect.fromLTWH(x, y, w, bh));
      y += bh;
    }
  }
  return rects;
}

// -------------------- SHIMMER --------------------

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child});
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController.unbounded(vsync: this)
      ..repeat(min: 0, max: 1, period: Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final gradient = LinearGradient(
          begin: Alignment(-1 + 2 * _ctrl.value, 0),
          end: Alignment(1 + 2 * _ctrl.value, 0),
          colors: isDark
              ? [
            Colors.white.withOpacity(.10),
            Colors.white.withOpacity(.24),
            Colors.white.withOpacity(.10),
          ]
              : [
            Colors.grey.shade300,
            Colors.grey.shade100,
            Colors.grey.shade300,
          ],
          stops: const [0.25, 0.5, 0.75],
        );
        return ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// -------------------- LEGENDA --------------------

class _LegendWrap extends StatelessWidget {
  const _LegendWrap({required this.items});
  final int items;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(.14)
        : Colors.grey.shade300;

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: List.generate(items, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 58 + (i % 3) * 18,
              height: 12,
              decoration: BoxDecoration(
                color: base,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _LegendColumn extends StatelessWidget {
  const _LegendColumn({required this.items});
  final int items;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).brightness == Brightness.dark
        ? Colors.white.withOpacity(.14)
        : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(items, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 90 + (i % 4) * 22,
                height: 12,
                decoration: BoxDecoration(
                  color: base,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _AutoScrollColumn extends StatelessWidget {
  const _AutoScrollColumn({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      return SingleChildScrollView(
        padding: const EdgeInsets.only(right: 4),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: c.maxHeight),
          child: child,
        ),
      );
    });
  }
}
