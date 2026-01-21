// lib/_widgets/charts/neuralbar/types.dart
import 'package:siged/_utils/formats/format_field.dart';

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
      return priceToString(value);

    case ValueType.percent:
    // Aqui consideramos que o value já vem em 0–100 (como seus gráficos costumam).
    // Se estiver em 0–1, ajuste no call site.
      return convertDoubleToPercentageString(
        value,
        fractionDigits: fractionDigits,
      );

    case ValueType.unit:
      final base = doubleToString(
        value,
        fractionDigits: fractionDigits,
        empty: '0',
      );
      return unitSuffix.trim().isEmpty ? base : '$base $unitSuffix';

    case ValueType.custom:
      return (custom ?? (v) => v.toStringAsFixed(0))(value);
  }
}
