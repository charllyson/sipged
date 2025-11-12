

String formatNumber(double v) {
  final abs = v.abs();
  if (abs >= 1e9) return '${(v / 1e9).toStringAsFixed(2)} bi';
  if (abs >= 1e6) return '${(v / 1e6).toStringAsFixed(2)} mi';
  if (abs >= 1e3) return '${(v / 1e3).toStringAsFixed(2)} mil';
  return v.toStringAsFixed(2);
}