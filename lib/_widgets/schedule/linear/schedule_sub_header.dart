import 'package:flutter/material.dart';
/// -------------------------
/// 2) SUBCABEÇALHO (legenda)
/// -------------------------
class ScheduleSubHeader extends StatelessWidget {
  final bool isLoading;
  final double pctConcluido;
  final double pctAndamento;
  final double pctAIniciar;
  final double leftPadding;
  final TextStyle? textStyle;

  /// Se true, reduz levemente a escala para caber em 1 linha; se false, pode cortar com reticências.
  final bool shrinkToFit;

  const ScheduleSubHeader({
    super.key,
    required this.isLoading,
    required this.pctConcluido,
    required this.pctAndamento,
    required this.pctAIniciar,
    this.leftPadding = 0,
    this.textStyle,
    this.shrinkToFit = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = textStyle;

    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _LegendaIcone(color: Colors.green),  Text('${pctConcluido.toStringAsFixed(1)}%', style: style),
        const SizedBox(width: 14),
        const _LegendaIcone(color: Colors.orange), Text('${pctAndamento.toStringAsFixed(1)}%', style: style),
        const SizedBox(width: 14),
        const _LegendaIcone(color: Colors.grey),   Text('${pctAIniciar.toStringAsFixed(1)}%', style: style),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: isLoading
          ? const SizedBox(
        height: 24, width: 24,
        child: CircularProgressIndicator.adaptive(backgroundColor: Colors.white24),
      )
          : Align(
        alignment: Alignment.centerLeft,
        child: shrinkToFit
            ? FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: row)
            : row,
      ),
    );
  }
}

class _LegendaIcone extends StatelessWidget {
  final Color color;
  const _LegendaIcone({required this.color});
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [Icon(Icons.square, color: color, size: 12), const SizedBox(width: 4)],
  );
}
