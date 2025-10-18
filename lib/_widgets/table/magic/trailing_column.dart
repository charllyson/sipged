import 'package:flutter/material.dart';
import 'package:siged/_widgets/table/magic/magic_table_changed.dart';
import 'package:siged/_widgets/table/magic/trailing_col_meta.dart';

class MagicTrailingColumn extends StatelessWidget {
  const MagicTrailingColumn({
    super.key,
    required this.rowCount,
    required this.rowHeight,
    required this.bottomScrollGap,
    required this.trailingCols,
    required this.trailingRowBuilder,
    required this.cellPad,
    required this.rowStyleResolver,
  });

  final int rowCount; // inclui header
  final double rowHeight;
  final double bottomScrollGap;

  final List<TrailingColMeta> trailingCols;
  final TrailingRowBuilder? trailingRowBuilder;
  final EdgeInsets cellPad;

  final RowStyleResolver rowStyleResolver;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ...List.generate(rowCount - 1, (i) {
          final r = i + 1;
          final cells = trailingRowBuilder?.call(context, r) ?? const <Widget>[];
          final style = rowStyleResolver(r);

          return Row(
            children: [
              for (int k = 0; k < trailingCols.length; k++)
                _TrailingCellWrapper(
                  height: rowHeight,
                  width: trailingCols[k].width,
                  align: trailingCols[k].align,
                  cellPad: cellPad,
                  bgColor: style.bg,
                  textStyle: style.text,
                  editable: trailingCols[k].editable,
                  readOnlyHint: trailingCols[k].readOnlyHint,
                  // 🔹 aplica formatação automática quando possível
                  child: _formatAccordingToMeta(
                    meta: trailingCols[k],
                    original: (k < cells.length) ? cells[k] : const SizedBox.shrink(),
                  ),
                ),
            ],
          );
        }),
        SizedBox(height: bottomScrollGap),
      ],
    );
  }

  /// Tenta formatar automaticamente quando o widget é um Text simples.
  Widget _formatAccordingToMeta({
    required TrailingColMeta meta,
    required Widget original,
  }) {
    if (original is! Text) return original; // mantém widgets custom

    final raw = original.data ?? _extractPlainText(original);
    if (raw == null) return original;

    switch (meta.type) {
      case TrailingValueType.text:
        return original;

      case TrailingValueType.number:
        final d = _tryParseBRorEN(raw);
        if (d == null) return original;
        final s = _formatNumberBR(d, decimals: meta.decimals);
        return Text(
          s,
          key: original.key,
          textAlign: original.textAlign,
          maxLines: original.maxLines,
          overflow: original.overflow,
          style: original.style,
          textWidthBasis: original.textWidthBasis,
          textHeightBehavior: original.textHeightBehavior,
          softWrap: original.softWrap,
        );

      case TrailingValueType.money:
        final d = _tryParseBRorEN(raw);
        if (d == null) return original;
        final s = '${meta.moneyPrefix}${_formatNumberBR(d, decimals: meta.decimals)}';
        return Text(
          s,
          key: original.key,
          textAlign: original.textAlign,
          maxLines: original.maxLines,
          overflow: original.overflow,
          style: original.style,
          textWidthBasis: original.textWidthBasis,
          textHeightBehavior: original.textHeightBehavior,
          softWrap: original.softWrap,
        );
    }
  }

  /// Extrai texto de um Text com TextSpan simples (fallback)
  String? _extractPlainText(Text t) {
    final span = t.textSpan;
    if (span == null) return null;
    if (span is TextSpan && span.children == null) return span.text;
    return null;
  }

  /// Aceita "1234,56", "1.234,56", "1234.56", "1,234.56"
  double? _tryParseBRorEN(String s) {
    final v = s.trim();
    if (v.isEmpty) return null;

    // remove símbolos e espaços
    final cleaned = v
        .replaceAll(RegExp(r'[Rr]\$'), '')
        .replaceAll(RegExp(r'[^0-9,.\-]'), '')
        .trim();

    if (cleaned.isEmpty) return null;

    // Heurística: se tem vírgula e ponto, decide qual é decimal pelo último símbolo
    if (cleaned.contains(',') && cleaned.contains('.')) {
      final lastComma = cleaned.lastIndexOf(',');
      final lastDot = cleaned.lastIndexOf('.');
      final decimalIsComma = lastComma > lastDot;

      final canonical = decimalIsComma
          ? cleaned.replaceAll('.', '').replaceAll(',', '.')
          : cleaned.replaceAll(',', '');
      return double.tryParse(canonical);
    }

    // Só vírgula → BR
    if (cleaned.contains(',') && !cleaned.contains('.')) {
      final canonical = cleaned.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(canonical);
    }

    // Só ponto → EN
    return double.tryParse(cleaned);
  }

  /// Formata número no padrão BR: milhares com '.', decimais com ','
  String _formatNumberBR(double d, {int decimals = 2}) {
    final neg = d < 0;
    final v = d.abs();

    String s = v.toStringAsFixed(decimals);
    final parts = s.split('.'); // [int, dec]

    String intPart = parts[0];
    final dec = (parts.length > 1) ? parts[1] : '';

    // milhares
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final idx = intPart.length - i - 1;
      buf.write(intPart[idx]);
      if (i % 3 == 2 && idx != 0) buf.write('.');
    }
    final intBR = buf.toString().split('').reversed.join();

    final sign = neg ? '-' : '';
    return dec.isEmpty ? '$sign$intBR' : '$sign$intBR,$dec';
  }
}

/// 🔹 Wrapper que aplica bordas/cores e bloqueia interação quando read-only.
/// Também pinta texto cinza em modo bloqueado.
class _TrailingCellWrapper extends StatelessWidget {
  const _TrailingCellWrapper({
    required this.height,
    required this.width,
    required this.align,
    required this.cellPad,
    required this.bgColor,
    required this.textStyle,
    required this.editable,
    required this.readOnlyHint,
    required this.child,
  });

  final double height;
  final double width;
  final TextAlign align;
  final EdgeInsets cellPad;
  final Color bgColor;
  final TextStyle textStyle;
  final bool editable;
  final String readOnlyHint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final alignment = align == TextAlign.left
        ? Alignment.centerLeft
        : (align == TextAlign.center ? Alignment.center : Alignment.centerRight);

    final effectiveBg = editable
        ? bgColor
        : (bgColor == Colors.white ? Colors.grey.shade50 : bgColor);

    final effectiveTextStyle = editable
        ? textStyle
        : textStyle.merge(TextStyle(color: Colors.grey.shade600));

    final box = Container(
      width: width,
      height: height,
      alignment: alignment,
      padding: cellPad,
      decoration: BoxDecoration(
        color: effectiveBg,
        border: Border(
          left: BorderSide(color: Colors.grey.shade300, width: 1),
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: DefaultTextStyle.merge(
        style: effectiveTextStyle,
        child: child,
      ),
    );

    if (editable) return box;

    return Tooltip(
      message: readOnlyHint,
      waitDuration: const Duration(milliseconds: 300),
      child: IgnorePointer(ignoring: true, child: box),
    );
  }
}
