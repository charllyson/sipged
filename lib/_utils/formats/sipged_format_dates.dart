// lib/_utils/converters/sipged_format_dates.dart
class SipGedFormatDates {
  const SipGedFormatDates._();

  static DateTime? ddMMyyyyToDate(String input) {
    final s = input.trim();
    if (s.isEmpty) return null;

    final parts = s.split('/');
    if (parts.length != 3) return null;

    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return null;

    // validação simples de faixa
    if (y < 1900 || y > 2200) return null;
    if (m < 1 || m > 12) return null;
    if (d < 1 || d > 31) return null;

    final dt = DateTime(y, m, d);
    // garante que 31/02 não “vire” março silenciosamente
    if (dt.year != y || dt.month != m || dt.day != d) return null;

    return dt;
  }

  static String dateToDdMMyyyy(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  static String timeToHHmm(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String dateToDdMM(DateTime? date) {
    if (date == null) return '';
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    return '$d/$m';
  }

  /// "Hoje, 14:22" | "Ontem, 09:10" | "06/02, 18:40"
  static String dateAndTimeHumanized(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final input = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final time = timeToHHmm(dateTime);

    if (input == today) return 'Hoje, $time';
    if (input == today.subtract(const Duration(days: 1))) return 'Ontem, $time';
    return '${dateToDdMM(dateTime)}, $time';
  }

  /// Se você quiser um alias explícito do antigo stringToDate:
  static DateTime? stringToDate(String input) => ddMMyyyyToDate(input);
}
