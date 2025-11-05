import 'package:flutter/material.dart';

/// -------------------------
/// 1) CABEÇALHO (título)
/// -------------------------
class ScheduleHeader extends StatelessWidget {
  final String title;
  final Color colorStripe;
  final double leftPadding;
  final TextStyle? titleStyle;

  /// Se true, reduz levemente a escala para caber em 1 linha; se false, usa reticências.
  final bool shrinkToFit;

  const ScheduleHeader({
    super.key,
    required this.title,
    required this.colorStripe,
    this.leftPadding = 0,
    this.titleStyle,
    this.shrinkToFit = true,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      title,
      maxLines: 1,
      overflow: shrinkToFit ? TextOverflow.visible : TextOverflow.ellipsis,
      style: (titleStyle ??
          const TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
          )),
    );

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 10, height: 20, margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: colorStripe, borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: shrinkToFit
                ? FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: text,
            )
                : text,
          ),
        ],
      ),
    );
  }
}