// lib/_widgets/kit/rule/cost_ruler.dart
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:siged/_utils/formats/sipged_format_money.dart';
import 'package:siged/_widgets/cards/basic/basic_card.dart';
import 'package:siged/_widgets/charts/cost_ruler/ruler_painter.dart';

class CostRuler extends StatefulWidget {
  /// Valor “numerador” (ex: custo total, energia total, volume total).
  final double value;

  /// Divisor (ex: km, horas, unidades). Se 0, o valor por unidade vira 0.
  final double divisor;

  /// Título do card.
  final String title;

  /// Unidade (apenas para contexto em tooltip). Ex: "km", "h", "un", "m²".
  final String? unitLabel;

  /// Se você já tiver o valor final calculado (ex: R$/km),
  /// passe direto aqui e ignore value/divisor.
  final double? computedValue;

  /// Mínimo e máximo do eixo (do valor final).
  final double? min;
  final double? max;

  /// Benchmarks (marcadores) no mesmo “domínio” do valor final.
  /// Ex: {"Média": 1200, "Teto": 1800}
  final Map<String, double>? benchmarks;

  /// Altura do “miolo” (painter).
  final double height;

  /// Padding interno do bloco do painter.
  final EdgeInsetsGeometry padding;

  /// ✅ Se null, ocupa a largura disponível.
  final double? width;

  /// Formatter do valor final (ticks, tooltip e label do marcador).
  /// Por padrão usa moeda BR `priceToString`.
  final String Function(double v) formatter;

  /// Formatter compacto para os ticks do eixo.
  /// Se null, usa abreviação (k, M, B).
  final String Function(double v)? tickFormatter;

  /// Config de cores (opcional).
  final Color accentColor;
  final Color trackColorStart;
  final Color trackColorEnd;

  const CostRuler({
    super.key,
    required this.value,
    required this.divisor,
    this.title = 'Régua',
    this.unitLabel,
    this.computedValue,
    this.min,
    this.max,
    this.benchmarks,
    this.height = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    this.width,
    this.formatter = _defaultMoneyFormatter,
    this.tickFormatter,
    this.accentColor = const Color(0xFF4C6BFF),
    this.trackColorStart = const Color(0xFFEFF2FF),
    this.trackColorEnd = const Color(0xFFDDE5FF),
  });

  static String _defaultMoneyFormatter(double v) => SipGedFormatMoney.doubleToText(v);

  @override
  State<CostRuler> createState() => _CostRulerState();
}

class _CostRulerState extends State<CostRuler> {
  bool _hoverValue = false;
  bool _hoverMedia = false;
  bool _hoverTeto = false;

  bool _activeValue = false;
  bool _activeMedia = false;
  bool _activeTeto = false;

  Future<void> _ping(VoidCallback toggleFlag) async {
    toggleFlag();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 180));
    toggleFlag();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final double finalValue = widget.computedValue ??
        ((widget.divisor > 0) ? (widget.value / widget.divisor) : 0.0);

    final allVals = <double>[
      finalValue,
      ...(widget.benchmarks?.values ?? const <double>[]),
    ].where((v) => v.isFinite && v >= 0).toList();

    double minV = widget.min ?? 0;
    double maxV = widget.max ??
        (allVals.isNotEmpty ? _niceMax(allVals.reduce(math.max)) : 100.0);

    if (minV >= maxV) maxV = minV + 1;

    final (double? media, double? teto) =
    RulerPainter.pickThresholds(widget.benchmarks);

    final unitTxt = (widget.unitLabel ?? '').trim();
    final unitSuffix = unitTxt.isEmpty ? '' : ' / $unitTxt';

    return LayoutBuilder(
      builder: (context, c) {
        final double effectiveWidth = widget.width ?? math.max(0, c.maxWidth);

        return SizedBox(
          width: (effectiveWidth.isFinite && effectiveWidth > 0)
              ? effectiveWidth
              : null,
          child: BasicCard(
            isDark: isDark,
            padding: const EdgeInsets.only(left: 12, right: 12, top: 10, bottom: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cabeçalho
                Row(
                  children: [
                    Container(
                      width: 28,
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.accentColor, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.straighten, size: 18, color: widget.accentColor),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Régua + hotspots
                Padding(
                  padding: widget.padding,
                  child: SizedBox(
                    height: widget.height,
                    child: LayoutBuilder(
                      builder: (context, inner) {
                        double clamp(double v) => v < minV ? minV : (v > maxV ? maxV : v);

                        double toX(double v) {
                          final t = (clamp(v) - minV) / (maxV - minV);
                          const left = 6.0;
                          final right = inner.maxWidth - 6.0;
                          return left + t * (right - left);
                        }

                        final double valueX = toX(finalValue);
                        final double? mediaX = (media != null) ? toX(media) : null;
                        final double? tetoX = (teto != null) ? toX(teto) : null;

                        const double hitW = 28.0;
                        final double hitH = widget.height;

                        final tooltipValue = '${widget.formatter(finalValue)}$unitSuffix';
                        final tooltipMedia = media != null
                            ? 'Média: ${widget.formatter(media)}$unitSuffix'
                            : null;
                        final tooltipTeto = teto != null
                            ? 'Teto: ${widget.formatter(teto)}$unitSuffix'
                            : null;

                        String tooltipContractFull() {
                          final parts = <String>[
                            'Valor: $tooltipValue',
                            if (tooltipMedia != null) tooltipMedia,
                            if (tooltipTeto != null) tooltipTeto,
                          ];
                          return parts.join('\n');
                        }

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CustomPaint(
                              painter: RulerPainter(
                                min: minV,
                                max: maxV,
                                value: finalValue,
                                valueLabel: widget.formatter(finalValue),
                                benchmarks: widget.benchmarks,
                                formatter: widget.formatter,
                                tickFormatter: widget.tickFormatter,
                                textStyle: Theme.of(context).textTheme.bodySmall,
                                highlightValue: _hoverValue || _activeValue,
                                highlightMedia: _hoverMedia || _activeMedia,
                                highlightTeto: _hoverTeto || _activeTeto,
                                accentColor: widget.accentColor,
                                trackColorStart: widget.trackColorStart,
                                trackColorEnd: widget.trackColorEnd,
                              ),
                              size: Size(inner.maxWidth, widget.height),
                            ),

                            // VALUE (principal)
                            Positioned(
                              left: valueX - hitW / 2,
                              top: 0,
                              width: hitW,
                              height: hitH,
                              child: MouseRegion(
                                onEnter: (_) => setState(() => _hoverValue = true),
                                onExit: (_) => setState(() => _hoverValue = false),
                                child: GestureDetector(
                                  onTap: () => _ping(() => _activeValue = !_activeValue),
                                  child: Tooltip(
                                    message: tooltipContractFull(),
                                    waitDuration: const Duration(milliseconds: 200),
                                    child: const SizedBox.expand(),
                                  ),
                                ),
                              ),
                            ),

                            // MÉDIA
                            if (mediaX != null)
                              Positioned(
                                left: mediaX - hitW / 2,
                                top: 0,
                                width: hitW,
                                height: hitH,
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => _hoverMedia = true),
                                  onExit: (_) => setState(() => _hoverMedia = false),
                                  child: GestureDetector(
                                    onTap: () => _ping(() => _activeMedia = !_activeMedia),
                                    child: Tooltip(
                                      message: tooltipMedia!,
                                      waitDuration: const Duration(milliseconds: 200),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                              ),

                            // TETO
                            if (tetoX != null)
                              Positioned(
                                left: tetoX - hitW / 2,
                                top: 0,
                                width: hitW,
                                height: hitH,
                                child: MouseRegion(
                                  onEnter: (_) => setState(() => _hoverTeto = true),
                                  onExit: (_) => setState(() => _hoverTeto = false),
                                  child: GestureDetector(
                                    onTap: () => _ping(() => _activeTeto = !_activeTeto),
                                    child: Tooltip(
                                      message: tooltipTeto!,
                                      waitDuration: const Duration(milliseconds: 200),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static double _niceMax(double v) {
    if (v <= 0) return 1.0;
    final exp = (math.log(v) / math.ln10).floor();
    final base = math.pow(10.0, exp).toDouble();
    final scaled = v / base;
    double nice;
    if (scaled <= 1) nice = 1;
    else if (scaled <= 2) nice = 2;
    else if (scaled <= 5) nice = 5;
    else nice = 10;
    return nice * base;
  }
}
