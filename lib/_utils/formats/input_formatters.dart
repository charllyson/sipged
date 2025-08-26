import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

final processoMaskFormatter = MaskTextInputFormatter(
  mask: '#####.########/####',
  filter: {"#": RegExp(r'[0-9]')},
);

final contractMaskFormatter = MaskTextInputFormatter(
  mask: '###/####',
  filter: {"#": RegExp(r'[0-9]')},
);

final highwayMaskFormatter = MaskTextInputFormatter(
  mask: 'AL-###',
  filter: {"#": RegExp(r'[0-9]')},
);
class ThreeDecimalTextInputFormatter extends TextInputFormatter {
  final int decimalDigits;

  ThreeDecimalTextInputFormatter({this.decimalDigits = 3});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.isEmpty) {
      return const TextEditingValue(
        text: '0.000',
        selection: TextSelection.collapsed(offset: 5),
      );
    }

    // Remove zeros à esquerda
    digitsOnly = digitsOnly.replaceFirst(RegExp(r'^0+'), '');

    // Garante mínimo de dígitos
    if (digitsOnly.length <= decimalDigits) {
      digitsOnly = digitsOnly.padLeft(decimalDigits + 1, '0');
    }

    final intPart = digitsOnly.substring(0, digitsOnly.length - decimalDigits);
    final decPart = digitsOnly.substring(digitsOnly.length - decimalDigits);
    final formatted = '${int.parse(intPart)}.$decPart'; // remove leading zeros do inteiro

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
