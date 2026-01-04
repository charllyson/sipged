// lib/_widgets/charts/linear_bar/chart_legend.dart
import 'package:flutter/material.dart';
import 'package:siged/_widgets/cards/basic/basic_card.dart';
import 'package:siged/_widgets/charts/linear_bar/types.dart';

class ChartLegend extends StatelessWidget {
  final List<String> labels;
  final List<List<double>> values;
  final List<String> groupLegendLabels;
  final List<Color> colors;

  /// ✅ Tipo padrão de exibição de valores (money/unit/percent/custom)
  final ValueType valueType;

  /// Opcional: override total do formatter (se quiser)
  final StackedValueFormatter? customFormatter;

  /// Para unit/percent
  final int fractionDigits;
  final String unitSuffix;

  /// Tema atual (dark / light)
  final bool isDark;

  /// Se true, cards um pouco menores (para encaixar em layouts mais apertados)
  final bool compact;

  /// Modo “small”: nome do item em cima e chips abaixo
  final bool isSmall;

  /// Índice da linha selecionada (opcional)
  final int? selectedRowIndex;

  /// Índice da slice selecionada dentro da linha (opcional)
  final int? selectedSliceIndex;

  /// Largura/altura FIXAS do card – o pai controla essas dimensões.
  final double widthCard;
  final double heightCard;

  /// Quando true, mostra shimmer nas linhas da legenda.
  final bool isLoading;

  /// Callback quando clicar em um item da legenda.
  final void Function(
      int rowIndex,
      int sliceIndex,
      String rowLabel,
      String? sliceLabel,
      )? onLegendTap;

  // =========================================================
  // ✅ Controle explícito do negrito por ÍNDICE (sliceIndex)
  // - Ex.: {1, 3} deixa em negrito a slice 1 e 3 (label + valor)
  // - Se null/vazio: nenhum em negrito
  // =========================================================
  final Set<int>? boldLegendIndices;

  const ChartLegend({
    super.key,
    required this.labels,
    required this.values,
    required this.groupLegendLabels,
    required this.colors,
    required this.isDark,
    this.valueType = ValueType.unit,
    this.customFormatter,
    this.fractionDigits = 2,
    this.unitSuffix = '',
    this.compact = false,
    this.isSmall = false,
    this.selectedRowIndex,
    this.selectedSliceIndex,
    this.widthCard = 250,
    this.heightCard = 100,
    this.isLoading = false,
    this.onLegendTap,
    this.boldLegendIndices,
  });

  String _fmt(double v) => formatStackedValue(
    v,
    type: valueType,
    custom: customFormatter,
    fractionDigits: fractionDigits,
    unitSuffix: unitSuffix,
  );

  bool _isBoldIndex(int sliceIndex) {
    if (boldLegendIndices == null || boldLegendIndices!.isEmpty) return false;
    return boldLegendIndices!.contains(sliceIndex);
  }

  @override
  Widget build(BuildContext context) {
    // Se não está carregando e não tem dados, não mostra nada.
    if (!isLoading && (labels.isEmpty || groupLegendLabels.isEmpty)) {
      return const SizedBox.shrink();
    }

    // Quantidade de linhas a desenhar.
    final int rowCount = labels.isNotEmpty ? labels.length : (isLoading ? 1 : 0);
    if (rowCount == 0) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: List.generate(rowCount, (rowIndex) {
        final String rowLabel = labels.isNotEmpty ? labels[rowIndex] : '';

        final List<double> rowValues =
        (!isLoading && values.length > rowIndex)
            ? values[rowIndex]
            : (values.isNotEmpty ? values.first : const <double>[]);

        final bool isSelectedRow =
            !isLoading && selectedRowIndex != null && selectedRowIndex == rowIndex;

        // Borda azul quando linha selecionada.
        final Color? customBorderColor = isSelectedRow ? Colors.blueAccent : null;

        const EdgeInsets cardPadding = EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        );

        // O SizedBox garante altura/largura exatamente como o pai pediu
        return SizedBox(
          width: widthCard,
          height: heightCard,
          child: BasicCard(
            isDark: isDark,
            width: widthCard,
            height: heightCard,
            padding: cardPadding,
            borderColor: customBorderColor,
            enableShadow: true,
            animationDuration: const Duration(milliseconds: 150),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho: nome da região / obra / serviço
                if (rowLabel.isNotEmpty && !isLoading)
                  Text(
                    rowLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: isSelectedRow ? FontWeight.w700 : FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  )
                else
                  _ShimmerBox(
                    width: widthCard * 0.4,
                    height: 12,
                    borderRadius: BorderRadius.circular(4),
                  ),
                const SizedBox(height: 4),

                if (!isSmall)
                  ..._buildNormalMode(rowIndex, rowLabel, rowValues, isSelectedRow)
                else
                  ..._buildSmallMode(rowIndex, rowLabel, rowValues, isSelectedRow),
              ],
            ),
          ),
        );
      }),
    );
  }

  // =========================================================
  // MODO NORMAL: UMA LINHA POR SLICE
  // =========================================================
  List<Widget> _buildNormalMode(
      int rowIndex,
      String rowLabel,
      List<double> rowValues,
      bool isSelectedRow,
      ) {
    final List<Widget> children = [];

    int itemsCount;
    if (isLoading) {
      itemsCount = groupLegendLabels.isNotEmpty ? groupLegendLabels.length : 3;
      if (itemsCount > 4) itemsCount = 4;
    } else {
      itemsCount = rowValues.length;
    }

    for (int sliceIndex = 0; sliceIndex < itemsCount; sliceIndex++) {
      final String label =
      (!isLoading && sliceIndex < groupLegendLabels.length)
          ? groupLegendLabels[sliceIndex]
          : ' ';

      final bool isBold = _isBoldIndex(sliceIndex);

      final double value =
      (!isLoading && sliceIndex < rowValues.length) ? rowValues[sliceIndex] : 0.0;

      final Color dotColor =
      colors.isNotEmpty ? colors[sliceIndex % colors.length] : Colors.grey;

      final bool isSelectedSliceHere = !isLoading &&
          isSelectedRow &&
          selectedSliceIndex != null &&
          selectedSliceIndex == sliceIndex;

      final Color lineBg = isSelectedSliceHere
          ? (isDark
          ? Colors.orange.withOpacity(0.18)
          : Colors.orange.withOpacity(0.4))
          : Colors.transparent;

      children.add(
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () {
            if (!isLoading) {
              onLegendTap?.call(rowIndex, sliceIndex, rowLabel, label);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            decoration: BoxDecoration(
              color: lineBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: isLoading
                      ? _ShimmerBox(
                    height: 10,
                    borderRadius: BorderRadius.circular(999),
                  )
                      : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey.shade900,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                isLoading
                    ? _ShimmerBox(
                  width: 40,
                  height: 10,
                  borderRadius: BorderRadius.circular(999),
                )
                    : Text(
                  _fmt(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: compact ? 11 : 12,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                    color: isDark ? Colors.white : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return children;
  }

  // =========================================================
  // MODO SMALL: TODAS AS LEGENDAS NA MESMA LINHA
  // =========================================================
  List<Widget> _buildSmallMode(
      int rowIndex,
      String rowLabel,
      List<double> rowValues,
      bool isSelectedRow,
      ) {
    int itemsCount;
    if (isLoading) {
      itemsCount = groupLegendLabels.isNotEmpty ? groupLegendLabels.length : 3;
      if (itemsCount > 4) itemsCount = 4;
    } else {
      itemsCount = rowValues.length;
    }

    return [
      const SizedBox(height: 4),
      Wrap(
        spacing: 12,
        runSpacing: 4,
        children: List.generate(itemsCount, (sliceIndex) {
          final String label =
          (!isLoading && sliceIndex < groupLegendLabels.length)
              ? groupLegendLabels[sliceIndex]
              : ' ';

          final bool isBold = _isBoldIndex(sliceIndex);

          final double value =
          (!isLoading && sliceIndex < rowValues.length) ? rowValues[sliceIndex] : 0.0;

          final Color dotColor =
          colors.isNotEmpty ? colors[sliceIndex % colors.length] : Colors.grey;

          final bool isSelectedSliceHere = !isLoading &&
              isSelectedRow &&
              selectedSliceIndex != null &&
              selectedSliceIndex == sliceIndex;

          final Color chipBg = isSelectedSliceHere
              ? (isDark
              ? Colors.orange.withOpacity(0.18)
              : Colors.orange.withOpacity(0.3))
              : Colors.transparent;

          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () {
              if (!isLoading) {
                onLegendTap?.call(rowIndex, sliceIndex, rowLabel, label);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 4),
                  isLoading
                      ? _ShimmerBox(
                    width: 60,
                    height: 10,
                    borderRadius: BorderRadius.circular(999),
                  )
                      : Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
                      color: isDark
                          ? Colors.white.withOpacity(0.9)
                          : Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(width: 4),
                  isLoading
                      ? _ShimmerBox(
                    width: 40,
                    height: 10,
                    borderRadius: BorderRadius.circular(999),
                  )
                      : Text(
                    _fmt(value),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                      color: isDark ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    ];
  }
}

/// Shimmer simples para as linhas da legenda.
class _ShimmerBox extends StatefulWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;

  const _ShimmerBox({
    this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade600 : Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final color = Color.lerp(baseColor, highlightColor, _animation.value)!;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: widget.borderRadius,
          ),
        );
      },
    );
  }
}
