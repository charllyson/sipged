import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:sisged/_widgets/formats/format_field.dart';

class GaugeCircularPercent extends StatelessWidget {
  final double percent; // de 0 a 1
  final String label;
  final double? larguraGrafico;
  final Color? progressColor;
  final Color? backgroundColor;
  final double radius;
  final double centerFontSize;
  final double footerFontSize;
  final List<double>? values;

  const GaugeCircularPercent({
    super.key,
    required this.percent,
    required this.label,
    this.larguraGrafico,
    this.progressColor,
    this.backgroundColor,
    this.radius = 60.0,
    this.centerFontSize = 20.0,
    this.footerFontSize = 14.0,
    this.values,
  });

  @override
  Widget build(BuildContext context) {
    final clampedPercent = percent.clamp(0.0, 1.0);

    return Card(
      color: Colors.white,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: RepaintBoundary(
          child: SizedBox(
            height: 220,
            width: larguraGrafico ?? double.infinity,
            child: Tooltip(
              message: 'Total: ${priceToString(values?.fold(0.0, (a, b) => a! + b))}',
              child: CircularPercentIndicator(
                radius: radius,
                lineWidth: 20.0,
                animation: true,
                percent: clampedPercent,
                center: Text(
                  '${(clampedPercent * 100).toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: centerFontSize,
                  ),
                ),
                footer: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: footerFontSize),
                    textAlign: TextAlign.center,
                  ),
                ),
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: progressColor ?? _getProgressColor(clampedPercent),
                backgroundColor: backgroundColor ?? Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double percent) {
    if (percent <= 0.2) {
      return Colors.green;
    } else if (percent <= 0.4 && percent > 0.2){
      return Colors.blue.shade600;
    } else if(percent <= 0.6 && percent > 0.4){
      return Colors.yellow.shade800;
    } else if(percent <= 0.8 && percent > 0.6){
      return Colors.orange.shade800;
    } else {
      return Colors.red;
    }
  }
}
