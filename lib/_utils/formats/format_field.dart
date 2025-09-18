import 'package:intl/intl.dart';

/// --- Sanitizações básicas ---

String getSanitizedText(String text) {
  // Mantém apenas dígitos
  return text.replaceAll(RegExp(r'[^\d]'), '');
}

String getSanitizedPrice(String text) {
  // Troca vírgula por ponto (ex.: "1,23" -> "1.23")
  return text.replaceAll(',', '.');
}

/// --- Moeda / números ---

/// Formata moeda BR. Se [number] for null, retorna '' (ou personalize via [empty]).
String priceToString(double? number, {String empty = ''}) {
  if (number == null) return empty;
  // Garante 2 casas e símbolo "R$"
  final n = double.parse(number.toStringAsFixed(2));
  return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(n);
}

/// Alias mais explícito para moeda que aceita nulos.
String fmtPriceNullable(double? number, {String empty = '-'}) {
  return priceToString(number, empty: empty);
}

/// Formata double com casas decimais e locale BR. Se null, retorna [empty].
String doubleToString(double? value, {int fractionDigits = 2, String empty = '-'}) {
  if (value == null) return empty;
  final pattern = switch (fractionDigits) {
    0 => '###,##0',
    1 => '###,##0.0',
    2 => '###,##0.00',
    3 => '###,##0.000',
    4 => '###,##0.0000',
    _ => '###,##0.00',
  };
  // usa pt_BR e deixa o Intl trocar vírgula/ponto
  return NumberFormat(pattern, 'pt_BR').format(value);
}

/// Converte texto “BR” em double.
/// Aceita entradas como: "R$ 1.234,56", "1,23", "1.234", "-1.234,56"
double? stringToDouble(String? input) {
  if (input == null || input.isEmpty) return null;
  final sanitized = input
      .replaceAll(RegExp(r'[^\d,.\-]'), '') // mantém dígitos, vírgula, ponto e sinal
      .replaceAll('.', '')                  // remove separador de milhar
      .replaceAll(',', '.');                // vírgula decimal -> ponto
  return double.tryParse(sanitized);
}

/// Converte string de moeda BR para double.
/// Ex.: "R$ 12.345,67" -> 12345.67
double parseCurrencyToDouble(String text) {
  final cleaned = text
      .replaceAll('R\$', '')
      .replaceAll('.', '')
      .replaceAll(',', '.')
      .replaceAll(' ', '')
      .trim();
  return double.tryParse(cleaned) ?? 0.0;
}

/// Formata valor compacto com símbolo (R$ 1,2 mi)
String formatToMillions(double value) {
  final formatter = NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');
  return formatter.format(value);
}

/// Percentual: 0.1234 -> "12,34%"
String convertDoubleToPercentageString(double? value, {int fractionDigits = 2, String empty = ''}) {
  if (value == null) return empty;
  final percent = value; // se já vier em 0–100, troque para: final percent = value;
  final pattern = switch (fractionDigits) {
    0 => '##0',
    1 => '##0.0',
    2 => '##0.00',
    3 => '##0.000',
    _ => '##0.00',
  };
  final formatted = NumberFormat(pattern, 'pt_BR').format(percent);
  return '$formatted%';
}

/// Remove % e converte para double (ex.: "12,34%" -> 12.34)
double? removePercentToDouble(String value) {
  try {
    final clean = value
        .replaceAll('%', '')
        .replaceAll('.', '')   // milhar
        .replaceAll(',', '.')  // decimal
        .trim();
    return double.tryParse(clean);
  } catch (_) {
    return null;
  }
}

/// --- Datas / horas ---

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
  return DateFormat('dd/MM/yyyy', 'pt_BR').format(datetime);
}

String resumedDateToString(DateTime datetime) {
  return DateFormat('dd/MM/yy', 'pt_BR').format(datetime);
}

String monthAndYearToString(DateTime datetime) {
  return DateFormat('MM/yy', 'pt_BR').format(datetime);
}

String dayAndMonthToString(DateTime datetime) {
  return DateFormat('dd/MM', 'pt_BR').format(datetime);
}

String convertTimestampYYYY(DateTime datetime) {
  return DateFormat('yyyy', 'pt_BR').format(datetime);
}

String convertTimestampHHMM(DateTime datetime) {
  return DateFormat('HH:mm', 'pt_BR').format(datetime);
}

String convertTimestampHH(DateTime datetime) {
  return DateFormat('HH', 'pt_BR').format(datetime);
}

String convertTimestampMM(DateTime datetime) {
  return DateFormat('mm', 'pt_BR').format(datetime);
}

String convertTimestampNameDay(DateTime datetime) {
  return DateFormat('EE', 'pt_BR').format(datetime);
}

String timestampToHour(DateTime dateTime) {
  return DateFormat('HH:mm', 'pt_BR').format(dateTime);
}

/// Converte 'dd/MM/yyyy' para DateTime (ou null).
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

/// --- Documentos / textos ---

String addFormatCpf(String inputCpf) {
  final text = inputCpf.replaceAll(RegExp(r'\D'), '');
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
  final text = inputCpf.toString().replaceAll(RegExp(r'\D'), '');
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
  return inputCpf.replaceAll(RegExp(r'\D'), '');
}

/// Normaliza acentos e caixa, útil para buscas.
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
