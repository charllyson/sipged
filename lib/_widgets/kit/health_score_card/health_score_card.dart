import 'package:flutter/material.dart';

class HealthScoreCard extends StatelessWidget {
  final double cpi;
  final double spi;
  final double quality;
  final double riskScore;
  final List<double> weights;

  const HealthScoreCard({
    super.key,
    required this.cpi,
    required this.spi,
    required this.quality,
    required this.riskScore,
    this.weights = const [0.35, 0.35, 0.15, 0.15],
  });

  @override
  Widget build(BuildContext context) {
    final prazo = _mapTo100(spi);
    final custo = _mapTo100(cpi);

    final score = (prazo * weights[0]) +
        (custo * weights[1]) +
        (quality * weights[2]) +
        (riskScore * weights[3]);

    Color badge;
    if (score >= 80) {
      badge = Colors.green;
    } else if (score >= 60) badge = Colors.orange;
    else badge = Colors.red;

    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SizedBox(
        height: 165,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dot(score.toInt().toString(), badge),
              const SizedBox(width: 12),
              _kv('Prazo (SPI)', '${spi.toStringAsFixed(2)} • ${prazo.toStringAsFixed(0)}'),
              const SizedBox(width: 12),
              _kv('Custo (CPI)', '${cpi.toStringAsFixed(2)} • ${custo.toStringAsFixed(0)}'),
              const SizedBox(width: 12),
              _kv('Qualidade', quality.toStringAsFixed(0)),
              const SizedBox(width: 12),
              _kv('Riscos', riskScore.toStringAsFixed(0)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(String text, Color color) {
    return Container(
      width: 56, height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(.1),
        border: Border.all(color: color, width: 2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(text, style: TextStyle(
        color: color, fontSize: 18, fontWeight: FontWeight.w800,
      )),
    );
  }

  Widget _kv(String k, String v) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(k, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 2),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  double _mapTo100(double index) {
    final x = index.clamp(0.0, 1.5);
    if (x >= 1.0) return 100.0;
    return (x / 1.0) * 100.0;
  }
}
