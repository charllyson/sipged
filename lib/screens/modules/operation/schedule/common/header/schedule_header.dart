import 'package:flutter/material.dart';

/// -------------------------
/// 1) CABEÇALHO (título)
/// -------------------------
class ScheduleHeader extends StatelessWidget {
  const ScheduleHeader({
    super.key,
    required this.title,
    required this.colorStripe,
    this.leftPadding = 0,
    this.titleStyle,
    this.shrinkToFit = true,
    this.maxWidth,
  });

  final String title;
  final Color colorStripe;
  final double leftPadding;
  final TextStyle? titleStyle;

  /// Se true, reduz levemente a escala para caber em 1 linha.
  /// Se false, usa reticências.
  final bool shrinkToFit;

  /// Importante para uso dentro de SingleChildScrollView horizontal.
  /// Evita Row com largura infinita.
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxWidth = maxWidth ?? 360.0;

    final text = Text(
      title,
      maxLines: 1,
      softWrap: false,
      overflow: shrinkToFit ? TextOverflow.visible : TextOverflow.ellipsis,
      style: titleStyle ??
          const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
    );

    return Padding(
      padding: EdgeInsets.only(left: leftPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: effectiveMaxWidth,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 10,
              height: 20,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colorStripe,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
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
      ),
    );
  }
}