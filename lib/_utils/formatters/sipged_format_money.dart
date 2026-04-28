import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'sipged_format_numbers.dart';

/// Utilitário monetário oficial do SIPGED (BRL)
class SipGedFormatMoney {
  const SipGedFormatMoney._();

  // ===== Formatters Intl =====
  static final NumberFormat _currency =
  NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  static final NumberFormat _decimal2 = NumberFormat('#,##0.00', 'pt_BR');

  static final NumberFormat _compactCurrency =
  NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');

  /// R$ 1.234,56
  static String doubleToText(double? value, {String empty = ''}) {
    if (value == null) return empty;
    final v = double.parse(value.toStringAsFixed(2));
    return _currency.format(v);
  }

  /// 1234.56 → "1.234,56" (sem símbolo)
  static String brlNoSymbol(double? value, {String empty = ''}) {
    if (value == null) return empty;
    return _decimal2.format(value);
  }

  /// R$ compacto via intl → "R$ 1,2 mi"
  static String brlCompact(double? value, {String empty = ''}) {
    if (value == null) return empty;
    return _compactCurrency.format(value);
  }

  /// Compact simples (sem intl), mantendo padrão pt-BR:
  /// 1234 -> "1,23 mil"
  /// 1200000 -> "1,20 mi"
  static String compactSimple(double? value, {String empty = ''}) {
    if (value == null) return empty;

    final v = value;
    final abs = v.abs();

    if (abs >= 1e9) {
      return '${SipGedFormatNumbers.decimalPtBr(v / 1e9, fractionDigits: 2)} bi';
    }
    if (abs >= 1e6) {
      return '${SipGedFormatNumbers.decimalPtBr(v / 1e6, fractionDigits: 2)} mi';
    }
    if (abs >= 1e3) {
      return '${SipGedFormatNumbers.decimalPtBr(v / 1e3, fractionDigits: 2)} mil';
    }

    return SipGedFormatNumbers.decimalPtBr(v, fractionDigits: 2);
  }

  /// Parse BRL: "R$ 1.234,56" → 1234.56
  /// Também aceita "1.234,56" (sem símbolo)
  static double? parseBrl(String? input) {
    return SipGedFormatNumbers.toDouble(input);
  }
}

/// Formatter para digitação monetária BR (sem "R$")
/// Ex:
/// "1"       → "0,01"
/// "12"      → "0,12"
/// "1234"    → "12,34"
/// "123456"  → "1.234,56"
class SipGedMoneyFormatter extends TextInputFormatter {
  const SipGedMoneyFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // ===== 1) quantos dígitos existiam antes do cursor? =====
    final digitsBeforeCursor =
    _countDigitsBefore(newValue.text, newValue.selection.extentOffset);

    // ===== 2) formata BRL (sem símbolo) =====
    final padded = raw.padLeft(3, '0'); // garante pelo menos centavos
    final intPart = padded.substring(0, padded.length - 2);
    final decPart = padded.substring(padded.length - 2);

    final intFormatted = SipGedFormatNumbers.formatDigitsWithDots(intPart);
    final formatted = '$intFormatted,$decPart';

    // ===== 3) reposiciona cursor pela “contagem de dígitos” =====
    final newCursorPos =
    _cursorPosForDigitsCount(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPos),
      composing: TextRange.empty,
    );
  }

  static int _countDigitsBefore(String text, int cursor) {
    final safeCursor = cursor.clamp(0, text.length);
    int count = 0;
    for (int i = 0; i < safeCursor; i++) {
      final cu = text.codeUnitAt(i);
      if (cu >= 48 && cu <= 57) count++;
    }
    return count;
  }

  static int _cursorPosForDigitsCount(String formatted, int digitsCount) {
    if (digitsCount <= 0) return 0;

    int seen = 0;
    for (int i = 0; i < formatted.length; i++) {
      final cu = formatted.codeUnitAt(i);
      if (cu >= 48 && cu <= 57) {
        seen++;
        if (seen == digitsCount) return i + 1;
      }
    }
    return formatted.length;
  }
}
