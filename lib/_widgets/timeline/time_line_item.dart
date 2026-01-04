
class TimelineItem {
  final String title;
  final DateTime? date;
  final String source;
  final dynamic original;
  final int? diasParalisados;

  TimelineItem({
    required this.title,
    required this.date,
    required this.source,
    this.original,
    this.diasParalisados,
  });
}