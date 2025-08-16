import 'package:flutter/material.dart';

class LanePreview extends StatelessWidget {
  final String label;
  final String? aboveLabel; // rótulo da faixa acima (se existir)
  final String? belowLabel; // rótulo da faixa abaixo (se existir)

  // Deve bater com seu layout de linha
  final double rowHeight;
  final double gap;
  final double railWidth;

  const LanePreview({
    super.key,
    required this.label,
    this.aboveLabel,
    this.belowLabel,
    this.rowHeight = 44,
    this.gap = 12,
    this.railWidth = 28,
  });

  @override
  Widget build(BuildContext context) {
    const double centralH = 14;   // altura do canteiro
    const double borderW  = 0.5;  // mesma borda do desenho
    const double overlap  = 1.0;  // cobre hairline

    final bool isCentral       = _isCentral(label);
    final bool hasAbove        = aboveLabel != null;
    final bool hasBelow        = belowLabel != null;
    final bool aboveIsCentral  = hasAbove && _isCentral(aboveLabel!);
    final bool belowIsCentral  = hasBelow && _isCentral(belowLabel!);

    // Regras de união:
    // - só a faixa de BAIXO sobe para fechar o vão (evita sobrepor a de cima)
    final bool connectsAbove = hasAbove && !aboveIsCentral && !isCentral;
    final bool connectsBelow = hasBelow && !belowIsCentral && !isCentral;

    // Extensão apenas para cima; para baixo = 0 (sem sobreposição)
    double extAbove = 0;
    if (connectsAbove) {
      // sobe só o vão (gap) + 1px de overlap para cobrir a borda
      extAbove = gap + overlap + borderW;
    }
    final double extBelow = 0;

    final double barWidth  = isCentral ? 8  : 18;
    final double barHeight = isCentral ? centralH : rowHeight + extAbove + extBelow;
    final double topOffset = isCentral ? (rowHeight - centralH) / 2 : -extAbove;

    // Raio: zera onde há união (plano), arredonda o restante
    final double radiusTop    = connectsAbove ? 0 : 3;
    final double radiusBottom = connectsBelow ? 0 : 3;

    return SizedBox(
      width: railWidth,
      height: rowHeight,
      child: CustomPaint(
        painter: _LaneBarPainter(
          color: _laneColor(label),
          width: barWidth,
          height: barHeight,
          topOffset: topOffset,
          radiusTop: radiusTop,
          radiusBottom: radiusBottom,
          borderWidth: borderW,
        ),
      ),
    );
  }
}

class _LaneBarPainter extends CustomPainter {
  final Color color;
  final double width;
  final double height;
  final double topOffset;
  final double radiusTop;
  final double radiusBottom;
  final double borderWidth;

  _LaneBarPainter({
    required this.color,
    required this.width,
    required this.height,
    required this.topOffset,
    required this.radiusTop,
    required this.radiusBottom,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double x = (size.width - width) / 2;

    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(x, topOffset, width, height),
      topLeft:     Radius.circular(radiusTop),
      topRight:    Radius.circular(radiusTop),
      bottomLeft:  Radius.circular(radiusBottom),
      bottomRight: Radius.circular(radiusBottom),
    );

    final fill = Paint()..color = color;
    final border = Paint()
      ..color = Colors.black12
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, fill);
    canvas.drawRRect(rrect, border);
  }

  @override
  bool shouldRepaint(_LaneBarPainter old) =>
      color != old.color ||
          width != old.width ||
          height != old.height ||
          topOffset != old.topOffset ||
          radiusTop != old.radiusTop ||
          radiusBottom != old.radiusBottom ||
          borderWidth != old.borderWidth;
}

// helpers (iguais aos que você já tem)
bool _isCentral(String l) {
  final t = l.toUpperCase();
  return t.contains('CANTEIRO') && t.contains('CENTRAL');
}
Color _laneColor(String l) {
  final t = l.toUpperCase();
  if (_isCentral(t)) return const Color(0xFFF2C94C);
  if (t.contains('ATUAL')) return Colors.black12;
  if (t.contains('DUPLICAÇÃO')) return Colors.black54;
  if (t.contains('ACOSTAMENTO')) return Colors.black12;
  if (t.contains('CICLOVIA')) return Colors.green.shade200;
  if (t.contains('PASSEIO')) return Colors.blue.shade200;
  return Colors.black54;
}
