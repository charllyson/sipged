import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'tipo_dado_enum.dart';

TipoDado detectarTipo(List<Map<String, dynamic>> dados, String campo) {
  for (final linha in dados) {
    final valor = linha[campo];
    if (valor == null) continue;

    if (valor is int) return TipoDado.int_;
    if (valor is double) return TipoDado.double_;
    if (valor is bool) return TipoDado.bool_;
    if (valor is DateTime) return TipoDado.dateTime;

    if (valor is String) {
      if (valor.contains('/') || valor.contains('-')) {
        final data = converterParaDateTime(valor);
        if (data != null) return TipoDado.dateTime;
      }
    }

    return TipoDado.string;
  }
  return TipoDado.string;
}

DateTime? converterParaDateTime(dynamic valor) {
  if (valor == null) return null;
  if (valor is DateTime) return valor;

  if (valor is Timestamp) return valor.toDate();

  if (valor is String) {
    final str = valor.trim();

    // Formato: dd/MM/yyyy HH:mm:ss
    final match1 = RegExp(r'^(\d{2})/(\d{2})/(\d{4})[ T](\d{2}):(\d{2}):(\d{2})(\.\d+)?$').firstMatch(str);
    if (match1 != null) {
      try {
        return DateTime(
          int.parse(match1.group(3)!),
          int.parse(match1.group(2)!),
          int.parse(match1.group(1)!),
          int.parse(match1.group(4)!),
          int.parse(match1.group(5)!),
          int.parse(match1.group(6)!),
        );
      } catch (_) {}
    }

    // Formato: dd/MM/yyyy HH:mm
    final match2 = RegExp(r'^(\d{2})/(\d{2})/(\d{4})[ T](\d{2}):(\d{2})$').firstMatch(str);
    if (match2 != null) {
      try {
        return DateTime(
          int.parse(match2.group(3)!),
          int.parse(match2.group(2)!),
          int.parse(match2.group(1)!),
          int.parse(match2.group(4)!),
          int.parse(match2.group(5)!),
        );
      } catch (_) {}
    }

    // Formato: dd/MM/yyyy
    final match3 = RegExp(r'^(\d{2})/(\d{2})/(\d{4})$').firstMatch(str);
    if (match3 != null) {
      try {
        return DateTime(
          int.parse(match3.group(3)!),
          int.parse(match3.group(2)!),
          int.parse(match3.group(1)!),
        );
      } catch (_) {}
    }

    // Fallback ISO 8601 (yyyy-MM-ddTHH:mm:ss)
    try {
      final parsed = DateTime.tryParse(str);
      if (parsed != null) return parsed;
    } catch (_) {}
  }

  return null;
}

dynamic converterValorPorTipo(dynamic valor, TipoDado tipo) {
  if (valor == null) return null;

  try {
    switch (tipo) {
      case TipoDado.string:
        return valor.toString();
      case TipoDado.int_:
        return int.tryParse(valor.toString());
      case TipoDado.double_:
        return double.tryParse(valor.toString().replaceAll(',', '.'));
      case TipoDado.bool_:
        final str = valor.toString().toLowerCase();
        return str == 'true' || str == '1' || str == 'sim';
      case TipoDado.dateTime:
        final str = valor.toString().trim();
        final regexBR = RegExp(r'^(\d{2})/(\d{2})/(\d{4})(\s+(\d{2}):(\d{2})(:(\d{2}))?)?$');
        final match = regexBR.firstMatch(str);

        if (match != null) {
          final dia = int.parse(match.group(1)!);
          final mes = int.parse(match.group(2)!);
          final ano = int.parse(match.group(3)!);
          final hora = int.tryParse(match.group(5) ?? '0') ?? 0;
          final minuto = int.tryParse(match.group(6) ?? '0') ?? 0;
          final segundo = int.tryParse(match.group(8) ?? '0') ?? 0;

          final parsed = DateTime(ano, mes, dia, hora, minuto, segundo);
          return parsed;
        } else {
        }

        return null;
      }
  } catch (e) {
    return null;
  }
}


