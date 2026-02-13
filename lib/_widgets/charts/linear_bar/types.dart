import 'package:sipged/_utils/formats/sipged_format_money.dart';
import 'package:sipged/_utils/formats/sipged_format_numbers.dart';

/// Tipo de valor exibido (usado para formatadores).
enum ValueType {
  money,
  unit,
  percent,
  custom,
}

/// Onde exibir o label de cada slice.
enum LabelLocation {
  none,
  aboveBar,
  insideBar,
}

/// Posição da legenda geral (mantido por compatibilidade).
enum LegendLocation {
  none,
  top,
  betweenLabelAndBar,
  bottom,
}

/// Formatter padrão (para casos custom).
typedef StackedValueFormatter = String Function(double value);

/// ✅ Formatação centralizada para gráfico/legenda/overlay
String formatStackedValue(
    double value, {
      required ValueType type,
      StackedValueFormatter? custom,
      int fractionDigits = 2,
      String unitSuffix = '',
    }) {
  switch (type) {
    case ValueType.money:
      return SipGedFormatMoney.doubleToText(value);

    case ValueType.percent:
    // value já em 0–100
      return SipGedFormatNumbers.percent(
        value,
        fractionDigits: fractionDigits,
        empty: '0',
      );

    case ValueType.unit:
      final base = SipGedFormatNumbers.decimalPtBr(
        value,
        fractionDigits: fractionDigits,
      );
      return unitSuffix.trim().isEmpty ? base : '$base $unitSuffix';

    case ValueType.custom:
      return (custom ?? (v) => v.toStringAsFixed(0))(value);
  }
}
