import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PercentInputFormatter extends TextInputFormatter {
  final int mantissaLength;

  PercentInputFormatter({this.mantissaLength = 2});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Remove qualquer caractere que não seja número
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (newText.isEmpty) return newValue.copyWith(text: '');

    // Converte para valor percentual (ex: '1234' -> 12.34)
    double? value = double.tryParse(newText);
    if (value == null) return oldValue;

    value = value / 100;

    if (value > 100) return oldValue;

    final formatter = NumberFormat('#,##0.${'0' * mantissaLength}', 'pt_BR');
    final formatted = '${formatter.format(value)}%';

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
