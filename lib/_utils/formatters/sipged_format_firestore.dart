import 'package:cloud_firestore/cloud_firestore.dart';

import 'sipged_format_dates.dart';
import 'sipged_format_numbers.dart';

class SipGedFormatFirestore {
  const SipGedFormatFirestore._();

  /// Converte valores para um formato seguro de persistência no Firestore.
  /// - DateTime => Timestamp
  /// - String => trim()
  /// - num/int/bool => 그대로
  static dynamic toFirestoreValue(dynamic value) {
    if (value == null) return null;

    if (value is Timestamp) return value;
    if (value is DateTime) return Timestamp.fromDate(value);

    if (value is num) return value;
    if (value is bool) return value;

    if (value is String) return value.trim();

    // Map/List e outros tipos são retornados como vieram
    return value;
  }

  /// Lê DateTime de um campo Firestore ou string.
  /// Aceita:
  /// - Timestamp
  /// - DateTime
  /// - "dd/MM/yyyy"
  /// - ISO 8601 (DateTime.parse)
  static DateTime? toDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();

    if (v is String) {
      final s = v.trim();
      if (s.isEmpty) return null;

      // tenta dd/MM/yyyy primeiro
      final ptbr = SipGedFormatDates.ddMMyyyyToDate(s);
      if (ptbr != null) return ptbr;

      // depois ISO
      return DateTime.tryParse(s);
    }

    return null;
  }

  /// Parse de double para leitura de Firestore / forms / compat legado.
  static double? toDouble(dynamic v) => SipGedFormatNumbers.toDouble(v);

  /// Parse de int para leitura de Firestore / forms / compat legado.
  static int? toInt(dynamic v) => SipGedFormatNumbers.toInt(v);
}
