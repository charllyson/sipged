
import 'package:cloud_firestore/cloud_firestore.dart';

class ConvertersUtils{

  // ---------------------------------------------------------------------------
  // Helpers de conversão
  // ---------------------------------------------------------------------------

  static double? converterToDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    if (v is String) {
      // aceita "1.234,56" ou "1234.56"
      final s = v.replaceAll('.', '').replaceAll(',', '.');
      return double.tryParse(s);
    }
    return null;
  }

  static int? converterToInt(dynamic v) {
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

  static DateTime? converterToDate(dynamic v) {
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
}