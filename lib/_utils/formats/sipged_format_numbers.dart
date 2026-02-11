import 'package:flutter/services.dart';

class SipGedFormatNumbers {
  const SipGedFormatNumbers._();

  /// Parse robusto:
  /// - "1.234,56"  -> 1234.56
  /// - "1,234.56"  -> 1234.56
  /// - "1234.56"   -> 1234.56
  /// - "1234,56"   -> 1234.56
  /// - "R$ 1.234,56" -> 1234.56
  ///
  /// Regra:
  /// - Mantém apenas dígitos, '.' ',' e '-'
  /// - Se tiver '.' e ',', o separador decimal é o que aparece por ÚLTIMO.
  /// - O outro separador vira milhar e é removido.
  static double? toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();

    if (v is String) {
      final cleaned = _normalizeNumericString(v);
      if (cleaned == null || cleaned.isEmpty) return null;
      return double.tryParse(cleaned);
    }
    return null;
  }

  static int? toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();

    if (v is String) {
      final s = v.replaceAll(RegExp(r'[^0-9\-]'), '');
      if (s.isEmpty || s == '-') return null;
      return int.tryParse(s);
    }
    return null;
  }

  /// Parse “solto” (útil p/ lat/long etc.)
  /// Aceita:
  /// - "-35,123" -> -35.123
  /// - "-35.123" -> -35.123
  /// - "1.234,56" / "1,234.56" também funciona
  static double? parseLoose(String s) => toDouble(s);

  // ---------------- FORMAT HELPERS ----------------
  /// "1000000" -> "1.000.000"
  static String formatDigitsWithDots(String digits) {
    final normalized = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
    final s = normalized.isEmpty ? '0' : normalized;

    final buf = StringBuffer();
    int count = 0;
    for (int i = s.length - 1; i >= 0; i--) {
      buf.write(s[i]);
      count++;
      if (count == 3 && i != 0) {
        buf.write('.');
        count = 0;
      }
    }
    return buf.toString().split('').reversed.join();
  }

  /// Formata decimal pt-BR (sem intl): 1234.5 => "1.234,50"
  static String decimalPtBr(double value, {int fractionDigits = 2}) {
    final neg = value.isNegative;
    final abs = value.abs();

    final fixed = abs.toStringAsFixed(fractionDigits);
    final parts = fixed.split('.');
    final intPart = parts[0];
    final decPart = (parts.length > 1) ? parts[1] : '';

    final intWithDots = formatDigitsWithDots(intPart);
    final out = fractionDigits > 0 ? '$intWithDots,$decPart' : intWithDots;

    return neg ? '-$out' : out;
  }

  /// Percentual (sem intl): 12.345 => "12,35%"
  static String percent(double? value, {int fractionDigits = 2, String empty = ''}) {
    if (value == null) return empty;
    return '${decimalPtBr(value, fractionDigits: fractionDigits)}%';
  }

  static String formatCPF(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return input;

    return '${digits.substring(0, 3)}.'
        '${digits.substring(3, 6)}.'
        '${digits.substring(6, 9)}-'
        '${digits.substring(9, 11)}';
  }

  // ---------------- INTERNAL ----------------
  static String? _normalizeNumericString(String input) {
    // mantém apenas dígitos, . , e -
    var s = input.trim().replaceAll(RegExp(r'[^\d,.\-]'), '');
    if (s.isEmpty || s == '-') return null;

    final hasDot = s.contains('.');
    final hasComma = s.contains(',');

    if (hasDot && hasComma) {
      // decimal é o separador que aparece por último
      final lastDot = s.lastIndexOf('.');
      final lastComma = s.lastIndexOf(',');
      final decimalSep = lastDot > lastComma ? '.' : ',';
      final thousandSep = decimalSep == '.' ? ',' : '.';

      s = s.replaceAll(thousandSep, '');
      if (decimalSep == ',') s = s.replaceAll(',', '.');
      return s;
    }

    if (hasComma && !hasDot) {
      // assume vírgula decimal
      s = s.replaceAll('.', '').replaceAll(',', '.');
      return s;
    }

    // só ponto ou nenhum: assume ponto decimal (e remove vírgulas se vier "1,234")
    s = s.replaceAll(',', '');
    return s;
  }
}

/// Inteiros com milhar enquanto digita: "1000000" -> "1.000.000"
/// OBS: versão simples -> cursor vai pro final
class SipGedThousandsIntFormatter extends TextInputFormatter {
  const SipGedThousandsIntFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final formatted = SipGedFormatNumbers.formatDigitsWithDots(digits);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}

/// Inteiros com milhar enquanto digita, preservando posição do cursor
class SipGedThousandsIntCursorFormatter extends TextInputFormatter {
  const SipGedThousandsIntCursorFormatter();

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    final digitsBeforeCursor =
    _countDigitsBefore(newValue.text, newValue.selection.extentOffset);

    final formatted = SipGedFormatNumbers.formatDigitsWithDots(digits);
    final newCursorPos = _cursorPosForDigitsCount(formatted, digitsBeforeCursor);

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

/// Decimais fixos enquanto digita (ex.: 3 casas => "0.000")
class FixedDecimalsFormatter extends TextInputFormatter {
  final int decimals;
  final String decimalSeparator;

  const FixedDecimalsFormatter({
    this.decimals = 3,
    this.decimalSeparator = '.',
  });

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      final zero = '0$decimalSeparator${'0' * decimals}';
      return TextEditingValue(
        text: zero,
        selection: TextSelection.collapsed(offset: zero.length),
        composing: TextRange.empty,
      );
    }

    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.length <= decimals) {
      digits = digits.padLeft(decimals + 1, '0');
    }

    final intPart = digits.substring(0, digits.length - decimals);
    final decPart = digits.substring(digits.length - decimals);
    final formatted = '${int.parse(intPart)}$decimalSeparator$decPart';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
      composing: TextRange.empty,
    );
  }
}
