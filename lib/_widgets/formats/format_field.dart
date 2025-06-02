import 'package:intl/intl.dart';

String getSanitizedText(String text) {
  return text.replaceAll(RegExp(r'[^\d]',), '',);
}

String getSanitizedPrice(String text) {
  return text.replaceAll(RegExp(',',), '.',);
}

String? priceToString(double? number) {
  return NumberFormat('R\$ ###,##0.00', 'pt-br',)
      .format(double.parse(number!.toStringAsFixed(2,),),);
}

String dateAndTimeToString(DateTime datetime) {
  return DateFormat('dd/MM HH:mm', 'pt-br',).format(datetime);
}

String dateToString(DateTime datetime) {
  return DateFormat('dd/MM/yyyy ', 'pt-br',).format(datetime);
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

String yearToString(DateTime datetime) {
  return DateFormat('yyyy', 'pt-br',).format(datetime);
}

String hourToString(DateTime datetime) {
  return DateFormat('HH:mm', 'pt-br',).format(datetime);
}

String onlyHourToString(DateTime datetime) {
  return DateFormat('HH', 'pt-br',).format(datetime);
}

String onlyMinutesToString(DateTime datetime) {
  return DateFormat('mm', 'pt-br',).format(datetime);
}

String convertDateTimeToDDMMYYYY(DateTime dateTime) {
  final formatter = DateFormat('dd/MM/yyyy',);
  final String formatted = formatter.format(dateTime);
  return formatted;
}

String nameOfDayToString(DateTime datetime) {
  return DateFormat('EE', 'pt-br',).format(datetime);
}

String timestampToHour(DateTime dateTime) {
  final formatter = DateFormat('HH:mm',);
  final String formatted = formatter.format(dateTime);
  return formatted;
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

String removeFormatCpf(String inputCpf) {
  String text = inputCpf.replaceAll(RegExp(r'\D'), '');
  return text.toString();
}