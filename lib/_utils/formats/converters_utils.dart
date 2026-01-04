
import 'package:cloud_firestore/cloud_firestore.dart';


  // ---------------------------------------------------------------------------
  // Helpers de conversão
  // ---------------------------------------------------------------------------

  DateTime? convertDDMMYYYYToDateTime(String input) {
    if (input.isEmpty) return null;
    final parts = input.split('/');
    if (parts.length != 3) return null;

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }

  String dateTimeToDDMMYYYY(DateTime? date) {
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  double? converterToDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      // aceita "1.234,56" ou "1234.56"
      final s = v.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(s);
    }
    return null;
  }

  int? converterToInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) {
      final onlyDigits =
      v.replaceAll(RegExp(r'[^0-9-]'), ''); // remove texto e símbolos
      if (onlyDigits.isEmpty) return null;
      return int.tryParse(onlyDigits);
    }
    return null;
  }

  DateTime? converterToDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      // tenta dd/MM/yyyy; se não der, tenta DateTime.parse padrão
      try {
        final parts = v.split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          return DateTime(y, m, d);
        }
      } catch (_) {
        // ignora e tenta parse padrão
      }
      return DateTime.tryParse(v);
    }
    return null;
  }

String formatNumber(double v) {
  final abs = v.abs();
  if (abs >= 1e9) return '${(v / 1e9).toStringAsFixed(2)} bi';
  if (abs >= 1e6) return '${(v / 1e6).toStringAsFixed(2)} mi';
  if (abs >= 1e3) return '${(v / 1e3).toStringAsFixed(2)} mil';
  return v.toStringAsFixed(2);
}