import 'package:flutter/services.dart';

class TextInputMask extends TextInputFormatter {
  final String mask;
  TextInputMask({required this.mask});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    String newText = '';
    int digitIndex = 0;

    for (int i = 0; i < mask.length && digitIndex < digits.length; i++) {
      if (mask[i] == '9') {
        newText += digits[digitIndex];
        digitIndex++;
      } else {
        newText += mask[i];
      }
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}