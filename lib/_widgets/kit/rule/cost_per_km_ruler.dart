import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:siged/_utils/formats/format_field.dart';
import 'package:siged/_widgets/kit/rule/ruler_painter.dart';

class CostPerKmRuler extends StatefulWidget {
  final double totalValueBRL;
  final double lengthKm;
  final String title;
  final double? minPerKm;
  final double? maxPerKm;
  final Map<String, double>? benchmarks;
  final double height;
  final EdgeInsetsGeometry padding;
  final double width;
  final String? serviceName;

  const CostPerKmRuler({
    super.key,
    required this.totalValueBRL,
    required this.lengthKm,
    this.title = 'R\$/km',
    this.minPerKm,
    this.maxPerKm,
    this.benchmarks,
    this.height = 80,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
    this.width = 420,
    this.serviceName,
  });

  @override
  State<CostPerKmRuler> createState() => _CostPerKmRulerState();
}

class _CostPerKmRulerState extends State<CostPerKmRuler> {
  bool _hoverContract = false;
  bool _hoverMedia = false;
  bool _hoverTeto = false;

  bool _activeContract = false;
  bool _activeMedia = false;
  bool _activeTeto = false;

  void _ping(VoidCallback setFlag) async {
    setFlag();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 180));
    setFlag();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final perKm = (widget.lengthKm > 0) ? (widget.totalValueBRL / widget.lengthKm) : 0.0;

    final allVals = <double>[
      perKm,
      ...(widget.benchmarks?.values ?? const <double>[]),
    ].where((v) => v.isFinite && v >= 0).toList();

    double minV = widget.minPerKm ?? 0;
    double maxV = widget.maxPerKm ??
        (allVals.isNotEmpty ? _niceMax(allVals.reduce(math.max)) : 100000.0);

    if (minV >= maxV) maxV = minV + 1;

    final (double? media, double? teto) = RulerPainter.pickThresholds(widget.benchmarks);

    return SizedBox(
      width: widget.width,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFF4C6BFF), width: 2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.straighten, size: 18, color: Color(0xFF4C6BFF)),
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
            ),
            const SizedBox(height: 20),

            // Régua + hotspots
            Padding(
              padding: widget.padding,
              child: SizedBox(
                height: widget.height,
                child: LayoutBuilder(
                  builder: (context, c) {
                    double clamp(double v) => v < minV ? minV : (v > maxV ? maxV : v);
                    double toX(double v) {
                      final t = (clamp(v) - minV) / (maxV - minV);
                      final left = 6.0;
                      final right = c.maxWidth - 6.0;
                      return left + t * (right - left);
                    }

                    final double markerX = toX(perKm);
                    final double? mediaX = (media != null) ? toX(media) : null;
                    final double? tetoX = (teto != null) ? toX(teto) : null;

                    const double hitW = 28.0;
                    final double hitH = widget.height;

                    final service = (widget.serviceName ?? '').trim();
                    final servTxt = service.isEmpty ? '' : ' de $service';

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        CustomPaint(
                          painter: RulerPainter(
                            min: minV,
                            max: maxV,
                            value: perKm,
                            benchmarks: widget.benchmarks,
                            textStyle: Theme.of(context).textTheme.bodySmall,
                            highlightContract: _hoverContract || _activeContract,
                            highlightMedia: _hoverMedia || _activeMedia,
                            highlightTeto: _hoverTeto || _activeTeto,
                          ),
                          size: Size(c.maxWidth, widget.height),
                        ),

                        // CONTRATO
                        Positioned(
                          left: markerX - hitW / 2,
                          top: 0,
                          width: hitW,
                          height: hitH,
                          child: MouseRegion(
                            onEnter: (_) => setState(() => _hoverContract = true),
                            onExit: (_) => setState(() => _hoverContract = false),
                            child: GestureDetector(
                              onTap: () => _ping(() => _activeContract = !_activeContract),
                              child: Tooltip(
                                message: _buildTooltipContrato(
                                  perKm: perKm,
                                  media: media,
                                  teto: teto,
                                ),
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
                                  message: 'Média por km$servTxt: ${priceToString(media!)}',
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
                                  message: 'Valor máximo por km$servTxt: ${priceToString(teto!)}',
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
  }

  static String _buildTooltipContrato({
    required double perKm,
    double? media,
    double? teto,
  }) {
    final parts = <String>[
      'Custo por km: ${priceToString(perKm)}',
      if (media != null) 'Média: ${priceToString(media)}',
      if (teto != null) 'Teto: ${priceToString(teto)}',
    ];
    return parts.join('\n');
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
