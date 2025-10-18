import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/trailing_col_meta.dart';

class MagicBandsHeader extends StatelessWidget {
  const MagicBandsHeader({
    super.key,
    required this.bandHeight,
    required this.mainGridWidth,
    required this.trailingCols,
    required this.contratoWidth,
    required this.quantidadeWidth,
    required this.valorWidth,
  });

  final double bandHeight;
  final double mainGridWidth;
  final List<TrailingColMeta> trailingCols;

  /// Larguras calculadas externamente (mantém a mesma regra do seu código)
  final double contratoWidth;
  final double quantidadeWidth;
  final double valorWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _bandBox('Contrato', contratoWidth),
        // espaço para colunas além de F no grid principal
        SizedBox(width: mainGridWidth - contratoWidth, height: bandHeight),
        if (trailingCols.isNotEmpty) ...[
          _bandBox('Quantidade', quantidadeWidth),
          _bandBox('Valor (R\$)', valorWidth),
        ],
      ],
    );
  }

  Widget _bandBox(String label, double width) {
    if (width <= 0) return const SizedBox.shrink();
    final borderColor = Colors.grey.shade300;
    return Container(
      width: width,
      height: bandHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
          left: BorderSide(color: borderColor, width: 1),
          right: BorderSide(color: borderColor, width: 1),
          bottom: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
