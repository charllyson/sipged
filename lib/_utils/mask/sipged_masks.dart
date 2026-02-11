import 'package:flutter/services.dart';

class GenericDigitMaskFormatter extends TextInputFormatter {
  final String mask;
  const GenericDigitMaskFormatter({required this.mask});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final oldText = oldValue.text;
    final newText = newValue.text;

    final oldDigits = _onlyDigits(oldText);
    var newDigitsRaw = _onlyDigits(newText);

    if (newDigitsRaw.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
        composing: TextRange.empty,
      );
    }

    final maxDigits = _maxDigits(mask);
    if (newDigitsRaw.length > maxDigits) {
      newDigitsRaw = newDigitsRaw.substring(0, maxDigits);
    }

    var digitsBeforeCursor =
    _countDigitsBefore(newText, newValue.selection.extentOffset);

    final isDeletion = newText.length < oldText.length;

    if (isDeletion && newDigitsRaw == oldDigits && oldDigits.isNotEmpty) {
      final oldCursor = oldValue.selection.extentOffset;
      final digitsBeforeOldCursor = _countDigitsBefore(oldText, oldCursor);

      final removeIndex =
      (digitsBeforeOldCursor - 1).clamp(0, oldDigits.length - 1);

      final modifiedDigits = _removeDigitAt(oldDigits, removeIndex);

      digitsBeforeCursor = removeIndex.clamp(0, modifiedDigits.length);

      final out = _applyMask(mask, modifiedDigits);
      final newCursorPos = _cursorPosForDigitsCount(out, digitsBeforeCursor);

      return TextEditingValue(
        text: out,
        selection: TextSelection.collapsed(offset: newCursorPos),
        composing: TextRange.empty,
      );
    }

    final out = _applyMask(mask, newDigitsRaw);
    final newCursorPos = _cursorPosForDigitsCount(out, digitsBeforeCursor);

    return TextEditingValue(
      text: out,
      selection: TextSelection.collapsed(offset: newCursorPos),
      composing: TextRange.empty,
    );
  }

  static bool _isPlaceholder(String ch) => ch == '9' || ch == '#';

  static int _maxDigits(String mask) =>
      mask.split('').where(_isPlaceholder).length;

  static String _onlyDigits(String s) => s.replaceAll(RegExp(r'\D'), '');

  static String _removeDigitAt(String digits, int index) {
    if (digits.isEmpty) return digits;
    if (index <= 0) return digits.substring(1);
    if (index >= digits.length - 1) return digits.substring(0, digits.length - 1);
    return digits.substring(0, index) + digits.substring(index + 1);
  }

  static String _applyMask(String mask, String digits) {
    final buf = StringBuffer();
    var di = 0;

    for (int i = 0; i < mask.length && di < digits.length; i++) {
      final m = mask[i];
      if (_isPlaceholder(m)) {
        buf.write(digits[di++]);
      } else {
        buf.write(m);
      }
    }
    return buf.toString();
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

class SipGedMasks {
  const SipGedMasks._();

  static const TextInputFormatter cnpj =
  GenericDigitMaskFormatter(mask: '99.999.999/9999-99');

  static const TextInputFormatter cpf =
  GenericDigitMaskFormatter(mask: '999.999.999-99');

  static const TextInputFormatter processo =
  GenericDigitMaskFormatter(mask: '#####.########/####');

  static const TextInputFormatter contract =
  GenericDigitMaskFormatter(mask: '###/####');

  static const TextInputFormatter highway =
  GenericDigitMaskFormatter(mask: 'AL-###');

  static const TextInputFormatter dateDDMMYYYY =
  GenericDigitMaskFormatter(mask: '99/99/9999');

  static const TextInputFormatter timeHHMM =
  GenericDigitMaskFormatter(mask: '99:99');

  static const TextInputFormatter dateTimeDDMMYYYYHHMM =
  GenericDigitMaskFormatter(mask: '99/99/9999 99:99');

  // ✅ NOVO: Telefone BR (celular com DDD)
  // Ex: (82) 99999-9999
  static const TextInputFormatter phoneBR =
  GenericDigitMaskFormatter(mask: '(99) 99999-9999');
}
