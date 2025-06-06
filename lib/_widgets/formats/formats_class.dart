import 'package:flutter/services.dart';

class PercentInputFormatter extends TextInputFormatter {
  final int decimalPlaces;

  PercentInputFormatter({this.decimalPlaces = 2, required int mantissaLength});

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');

    if (newText.isEmpty) return newValue.copyWith(text: '');

    double value = double.parse(newText) / 100;
    String formatted = '${value.toStringAsFixed(decimalPlaces)}%';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}