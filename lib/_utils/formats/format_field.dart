import 'package:intl/intl.dart';

String getSanitizedText(String text) {
  return text.replaceAll(RegExp(r'[^\d]',), '',);
}

String getSanitizedPrice(String text) {
  return text.replaceAll(RegExp(',',), '.',);
}

String priceToString(double? number) {
  if (number == null){
    return '';
  }
  final safeNumber = number;
  return NumberFormat('R\$ ###,##0.00', 'pt-br',)
      .format(double.parse(safeNumber.toStringAsFixed(2,),),);

}

String dateAndTimeHumanized(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final inputDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

  final time = DateFormat('HH:mm', 'pt_BR').format(dateTime);

  if (inputDate == today) {
    return 'Hoje, $time';
  } else if (inputDate == today.subtract(const Duration(days: 1))) {
    return 'Ontem, $time';
  } else {
    return '${DateFormat('dd/MM', 'pt_BR').format(dateTime)}, $time';
  }
}

String dateToString(DateTime datetime) {
  return DateFormat('dd/MM/yyyy ', 'pt-br',).format(datetime);
}
double? stringToDouble(String? input) {
  if (input == null || input.isEmpty) return null;
  final sanitized = input.replaceAll(RegExp(r'[^\d,.-]'), '').replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(sanitized);
}

int stringToInt(String? value) {
  if (value == null || value.isEmpty) return 0;
  return int.tryParse(value) ?? 0;
}

String resumedDateToString(DateTime datetime) {
  return DateFormat('dd/MM/yy ', 'pt-br',).format(datetime);
}

String monthAndYearToString(DateTime datetime) {
  return DateFormat('MM/yy ', 'pt-br',).format(datetime);
}

String dayAndMonthToString(DateTime datetime) {
  return DateFormat('dd/MM ', 'pt-br',).format(datetime);
}

double parseCurrencyToDouble(String text) {
  final cleaned = text
      .replaceAll('R\$', '')     // remove símbolo
      .replaceAll('.', '')       // remove pontos de milhar
      .replaceAll(',', '.')      // substitui vírgula por ponto
      .replaceAll(' ', '')       // remove espaços
      .trim();

  return double.tryParse(cleaned) ?? 0.0;
}

String convertTimestampYYYY(DateTime datetime) {
  return DateFormat('yyyy', 'pt-br',).format(datetime);
}

String convertTimestampHHMM(DateTime datetime) {
  return DateFormat('HH:mm', 'pt-br',).format(datetime);
}

String convertTimestampHH(DateTime datetime) {
  return DateFormat('HH', 'pt-br',).format(datetime);
}

String convertTimestampMM(DateTime datetime) {
  return DateFormat('mm', 'pt-br',).format(datetime);
}

String convertTimestampNameDay(DateTime datetime) {
  return DateFormat('EE', 'pt-br',).format(datetime);
}

String timestampToHour(DateTime dateTime) {
  final formatter = DateFormat('HH:mm',);
  final String formatted = formatter.format(dateTime);
  return formatted;
}

DateTime? stringToDate(String input) {
  final parts = input.split('/');
  if (parts.length == 3) {
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day != null && month != null && year != null) {
      return DateTime(year, month, day);
    }
  }
  return null;
}

String normalize(String input) {
  return input
      .toLowerCase()
      .replaceAll(RegExp(r'[áàâãä]', caseSensitive: false), 'a')
      .replaceAll(RegExp(r'[éèêë]', caseSensitive: false), 'e')
      .replaceAll(RegExp(r'[íìîï]', caseSensitive: false), 'i')
      .replaceAll(RegExp(r'[óòôõö]', caseSensitive: false), 'o')
      .replaceAll(RegExp(r'[úùûü]', caseSensitive: false), 'u')
      .replaceAll(RegExp(r'[ç]', caseSensitive: false), 'c');
}

String formatToMillions(double value) {
  final NumberFormat formatter = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(value);
}

String addFormatCpf(String inputCpf) {
  String text = inputCpf.replaceAll(RegExp(r'\D'), '');
  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    if (i == 3 || i == 6) buffer.write('.');
    if (i == 9) buffer.write('-');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

String addFormatCpfDynamicToString(dynamic inputCpf) {
  if (inputCpf == null) return '';

  // Garante que é string e remove tudo que não é número
  final text = inputCpf.toString().replaceAll(RegExp(r'\D'), '');

  // Valida se tem 11 dígitos
  if (text.length != 11) return inputCpf.toString();

  final buffer = StringBuffer();
  for (int i = 0; i < text.length; i++) {
    if (i == 3 || i == 6) buffer.write('.');
    if (i == 9) buffer.write('-');
    buffer.write(text[i]);
  }
  return buffer.toString();
}

String removeCharacters(String inputCpf) {
  String text = inputCpf.replaceAll(RegExp(r'\D'), '');
  return text.toString();
}

String doubleToString(double? value) {
  return NumberFormat('###,##0.00', 'pt-br',).format(value);
}

/*String convertDoubleToPercentageString(double? value) {
  if (value == null) return '';
  final formatted = NumberFormat('###,##0.00', 'pt-br').format(value);
  return '$formatted%';
}*/

String convertDoubleToPercentageString(double? value) {
  final raw = value.toString().replaceAll('%', '').replaceAll(',', '.');
  final parsed = double.tryParse(raw);
  if (parsed != null && parsed <= 100) {
    return '$parsed';
  }
  return '';
}

double? removePercentToDouble(String value) {
  try {
    final clean = value
        .replaceAll('%', '')
        .replaceAll('.', '')     // Remove milhar
        .replaceAll(',', '.')   // Troca vírgula decimal
        .trim();

    return double.tryParse(clean);
  } catch (_) {
    return null;
  }
}

