
/// VM do Gauge
class GaugeVM {
  final String label;
  final double count;
  final double total;
  final double percent;
  const GaugeVM({
    required this.label,
    required this.count,
    required this.total,
    required this.percent,
  });

  String get subtitle =>
      '${count.toStringAsFixed(1)} km de ${total.toStringAsFixed(1)} km';
}