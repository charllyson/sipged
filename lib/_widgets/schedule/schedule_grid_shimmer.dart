// lib/_widgets/schedule/schedule_grid_shimmer.dart
import 'package:flutter/material.dart';

class ScheduleGridShimmer extends StatelessWidget {
  const ScheduleGridShimmer({
    super.key,
    required this.legendWidth,
    required this.estacaWidth,
    required this.headerHeight,
    this.laneCount,
    this.cellHeight,
    this.padding = const EdgeInsets.only(top: 8, bottom: 24),
  });

  final double legendWidth;
  final double estacaWidth;
  final double headerHeight;
  final int? laneCount;
  final double? cellHeight;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height;

        // Largura útil para as células (tirando a legenda)
        final usable = (totalWidth - legendWidth).clamp(120.0, totalWidth);

        // Altura “bonita” para a célula se não for informada
        final hCell = (cellHeight ?? estacaWidth.clamp(18.0, 28.0)).toDouble();

        // Layout das linhas
        final headerGhost = headerHeight * 0.35;
        const gapBelowHeader = 6.0;
        const separator = 16.0;
        const gap = 1.5; // espaçamento entre quadradinhos
        final oneRowHeight = headerGhost + gapBelowHeader + hCell + separator;

        final rows = (laneCount ??
            (totalHeight.isFinite
                ? (totalHeight / oneRowHeight).ceil()
                : 6))
            .clamp(3, 40);

        // Nº de colunas aproximado pela largura alvo de cada estaca
        final approxCols = (usable / estacaWidth).floor().clamp(8, 600);

        // Largura exata de CADA quadradinho para fechar a linha sem sobras:
        // soma = cols * cellW + (cols - 1) * gap  == usable
        final cellW = (usable - (approxCols - 1) * gap) / approxCols;

        return _Shimmer(
          child: ListView.builder(
            padding: padding,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: rows,
            itemBuilder: (_, i) {
              return Padding(
                padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : separator),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    children: [
                      // Cabeçalho “fantasma”
                      Align(
                        alignment: Alignment.centerRight,
                        child: _SkelBox(
                          width: usable,
                          height: headerGhost,
                          radius: 8,
                        ),
                      ),
                      const SizedBox(height: gapBelowHeader),

                      // Linha: legenda + grid de quadradinhos
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Legenda “fantasma”
                          _SkelBox(
                            width: legendWidth - 12,
                            height: hCell,
                            radius: 10,
                          ),
                          const SizedBox(width: 8),

                          // Quadradinhos que FECHAM a largura sem sobras
                          SizedBox(
                            width: usable,
                            child: Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: List.generate(
                                approxCols,
                                    (_) => _SkelBox(
                                  width: cellW,
                                  height: hCell,
                                  radius: 4,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ------------------------ efeitos internos ------------------------

class _SkelBox extends StatelessWidget {
  const _SkelBox({required this.width, required this.height, this.radius = 8});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.child, this.duration = const Duration(seconds: 2)});
  final Widget child;
  final Duration duration;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Colors.grey.shade300;
    final highlight = Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (_, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            final dx = rect.width * (1.5 * _c.value - 0.5);
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
              transform: _GradientTranslation(dx, 0),
            ).createShader(Rect.fromLTWH(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.srcATop,
          child: child,
        );
      },
    );
  }
}

class _GradientTranslation extends GradientTransform {
  const _GradientTranslation(this.dx, this.dy);
  final double dx;
  final double dy;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, dy, 0.0);
  }
}
