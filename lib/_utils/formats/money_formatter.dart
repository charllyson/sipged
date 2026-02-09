import 'package:flutter/services.dart';

class MoneyFormatter extends TextInputFormatter {
  const MoneyFormatter();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    // Se apagou tudo
    if (newValue.text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Mantém só números
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Sempre trabalha em centavos
    final value = double.parse(digits) / 100.0;

    final formatted = _formatPtBr(value);

    // Cursor sempre no final (UX de dinheiro é assim)
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  static String _formatPtBr(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0];
    final decimal = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < integer.length; i++) {
      final pos = integer.length - i;
      buffer.write(integer[i]);
      if (pos > 1 && pos % 3 == 1) {
        buffer.write('.');
      }
    }

    return '${buffer.toString()},$decimal';
  }
}
