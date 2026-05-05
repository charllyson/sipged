import 'package:flutter/material.dart';
import 'package:sipged/_widgets/loading/loading_tree_dots.dart';

class ScheduleSubHeader extends StatelessWidget {
  final bool isLoading;
  final double pctConcluido;
  final double pctAndamento;
  final double pctAIniciar;
  final double leftPadding;
  final TextStyle? textStyle;
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
        const _LegendIcon(color: Colors.green),
        Text('${pctConcluido.toStringAsFixed(1)}%', style: style),
        const SizedBox(width: 14),
        const _LegendIcon(color: Colors.orange),
        Text('${pctAndamento.toStringAsFixed(1)}%', style: style),
        const SizedBox(width: 14),
        const _LegendIcon(color: Colors.grey),
        Text('${pctAIniciar.toStringAsFixed(1)}%', style: style),
      ],
    );

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: LoadingTreeDots(
          strokeWidth: 2.4,
          centered: false,
        ),
      )
          : Align(
        alignment: Alignment.centerLeft,
        child: shrinkToFit
            ? FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: row,
        )
            : row,
      ),
    );
  }
}

class _LegendIcon extends StatelessWidget {
  final Color color;

  const _LegendIcon({required this.color});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.square, color: color, size: 12),
      const SizedBox(width: 4),
    ],
  );
}