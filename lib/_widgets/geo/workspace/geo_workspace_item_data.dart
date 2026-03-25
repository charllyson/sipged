import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum GeoWorkspaceWidgetType {
  barVertical,
  donut,
  line,
  card,
  kpi,
  table,
}

enum GeoWorkspacePropertyType {
  text,
  number,
  stringList,
  numberList,
  select,
  binding,
}

class GeoWorkspaceFieldBinding {
  final String? sourceId;
  final String? sourceLabel;
  final String? fieldName;
  final String? aggregation;
  final dynamic fieldValue;
  final List<dynamic> fieldValues;

  const GeoWorkspaceFieldBinding({
    this.sourceId,
    this.sourceLabel,
    this.fieldName,
    this.aggregation,
    this.fieldValue,
    this.fieldValues = const [],
  });

  GeoWorkspaceFieldBinding copyWith({
    String? sourceId,
    String? sourceLabel,
    String? fieldName,
    String? aggregation,
    dynamic fieldValue = _bindingSentinel,
    List<dynamic>? fieldValues,
  }) {
    return GeoWorkspaceFieldBinding(
      sourceId: sourceId ?? this.sourceId,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      fieldName: fieldName ?? this.fieldName,
      aggregation: aggregation ?? this.aggregation,
      fieldValue: identical(fieldValue, _bindingSentinel)
          ? this.fieldValue
          : fieldValue,
      fieldValues: fieldValues ?? this.fieldValues,
    );
  }

  bool get hasBinding {
    return (sourceId ?? '').trim().isNotEmpty ||
        (fieldName ?? '').trim().isNotEmpty;
  }

  String get displayValue {
    final pieces = <String>[
      if ((sourceLabel ?? '').trim().isNotEmpty) sourceLabel!.trim(),
      if ((fieldName ?? '').trim().isNotEmpty) fieldName!.trim(),
      if ((aggregation ?? '').trim().isNotEmpty) aggregation!.trim(),
    ];

    if (pieces.isEmpty) return 'Não definido';
    return pieces.join(' • ');
  }

  String? get previewValueText {
    if (fieldValue == null) return null;
    final value = fieldValue.toString().trim();
    if (value.isEmpty) return null;
    return value;
  }

  String get valuesSummary {
    if (fieldValues.isEmpty) {
      return 'Sem valores carregados';
    }

    final sample = fieldValues
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .take(3)
        .map((e) => e.toString().trim())
        .join(', ');

    if (sample.isEmpty) {
      return '${fieldValues.length} valor(es)';
    }

    return '${fieldValues.length} valor(es) • ex: $sample';
  }

  @override
  bool operator ==(Object other) {
    return other is GeoWorkspaceFieldBinding &&
        other.sourceId == sourceId &&
        other.sourceLabel == sourceLabel &&
        other.fieldName == fieldName &&
        other.aggregation == aggregation &&
        other.fieldValue == fieldValue &&
        listEquals(other.fieldValues, fieldValues);
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    sourceLabel,
    fieldName,
    aggregation,
    fieldValue,
    Object.hashAll(fieldValues),
  );
}

const _bindingSentinel = Object();

class GeoWorkspaceFieldDragData {
  final String sourceId;
  final String sourceLabel;
  final String fieldName;
  final String? aggregation;
  final dynamic fieldValue;
  final List<dynamic> fieldValues;

  const GeoWorkspaceFieldDragData({
    required this.sourceId,
    required this.sourceLabel,
    required this.fieldName,
    this.aggregation,
    this.fieldValue,
    this.fieldValues = const [],
  });
}

class GeoWorkspacePropertyData {
  final String key;
  final String label;
  final GeoWorkspacePropertyType type;
  final String? hint;
  final bool acceptsDrop;

  final String? textValue;
  final double? numberValue;
  final List<String>? stringListValue;
  final List<double>? numberListValue;
  final String? selectedValue;
  final List<String>? options;
  final GeoWorkspaceFieldBinding? bindingValue;

  const GeoWorkspacePropertyData({
    required this.key,
    required this.label,
    required this.type,
    this.hint,
    this.acceptsDrop = false,
    this.textValue,
    this.numberValue,
    this.stringListValue,
    this.numberListValue,
    this.selectedValue,
    this.options,
    this.bindingValue,
  });

  static const Object _sentinel = Object();

  GeoWorkspacePropertyData copyWith({
    String? key,
    String? label,
    GeoWorkspacePropertyType? type,
    String? hint,
    bool? acceptsDrop,
    Object? textValue = _sentinel,
    Object? numberValue = _sentinel,
    Object? stringListValue = _sentinel,
    Object? numberListValue = _sentinel,
    Object? selectedValue = _sentinel,
    List<String>? options,
    Object? bindingValue = _sentinel,
  }) {
    return GeoWorkspacePropertyData(
      key: key ?? this.key,
      label: label ?? this.label,
      type: type ?? this.type,
      hint: hint ?? this.hint,
      acceptsDrop: acceptsDrop ?? this.acceptsDrop,
      textValue:
      identical(textValue, _sentinel) ? this.textValue : textValue as String?,
      numberValue: identical(numberValue, _sentinel)
          ? this.numberValue
          : numberValue as double?,
      stringListValue: identical(stringListValue, _sentinel)
          ? this.stringListValue
          : stringListValue as List<String>?,
      numberListValue: identical(numberListValue, _sentinel)
          ? this.numberListValue
          : numberListValue as List<double>?,
      selectedValue: identical(selectedValue, _sentinel)
          ? this.selectedValue
          : selectedValue as String?,
      options: options ?? this.options,
      bindingValue: identical(bindingValue, _sentinel)
          ? this.bindingValue
          : bindingValue as GeoWorkspaceFieldBinding?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GeoWorkspacePropertyData &&
        other.key == key &&
        other.label == label &&
        other.type == type &&
        other.hint == hint &&
        other.acceptsDrop == acceptsDrop &&
        other.textValue == textValue &&
        other.numberValue == numberValue &&
        listEquals(other.stringListValue, stringListValue) &&
        listEquals(other.numberListValue, numberListValue) &&
        other.selectedValue == selectedValue &&
        listEquals(other.options, options) &&
        other.bindingValue == bindingValue;
  }

  @override
  int get hashCode => Object.hash(
    key,
    label,
    type,
    hint,
    acceptsDrop,
    textValue,
    numberValue,
    Object.hashAll(stringListValue ?? const []),
    Object.hashAll(numberListValue ?? const []),
    selectedValue,
    Object.hashAll(options ?? const []),
    bindingValue,
  );
}

extension GeoWorkspaceWidgetTypeMapper on GeoWorkspaceWidgetType {
  String get catalogItemId {
    switch (this) {
      case GeoWorkspaceWidgetType.barVertical:
        return 'chart_bar_vertical';
      case GeoWorkspaceWidgetType.donut:
        return 'chart_donut';
      case GeoWorkspaceWidgetType.line:
        return 'chart_line';
      case GeoWorkspaceWidgetType.card:
        return 'widget_card';
      case GeoWorkspaceWidgetType.kpi:
        return 'widget_kpi';
      case GeoWorkspaceWidgetType.table:
        return 'widget_table';
    }
  }

  String get defaultTitle {
    switch (this) {
      case GeoWorkspaceWidgetType.barVertical:
        return 'Barra vertical';
      case GeoWorkspaceWidgetType.donut:
        return 'Rosca';
      case GeoWorkspaceWidgetType.line:
        return 'Linha';
      case GeoWorkspaceWidgetType.card:
        return 'Card resumo';
      case GeoWorkspaceWidgetType.kpi:
        return 'KPI';
      case GeoWorkspaceWidgetType.table:
        return 'Tabela';
    }
  }

  Size get defaultSize {
    switch (this) {
      case GeoWorkspaceWidgetType.barVertical:
        return const Size(420, 280);
      case GeoWorkspaceWidgetType.donut:
        return const Size(360, 260);
      case GeoWorkspaceWidgetType.line:
        return const Size(420, 280);
      case GeoWorkspaceWidgetType.card:
        return const Size(260, 140);
      case GeoWorkspaceWidgetType.kpi:
        return const Size(240, 140);
      case GeoWorkspaceWidgetType.table:
        return const Size(520, 300);
    }
  }

  static GeoWorkspaceWidgetType? fromCatalogItemId(String id) {
    switch (id) {
      case 'chart_bar_vertical':
        return GeoWorkspaceWidgetType.barVertical;
      case 'chart_donut':
        return GeoWorkspaceWidgetType.donut;
      case 'chart_line':
        return GeoWorkspaceWidgetType.line;
      case 'widget_card':
        return GeoWorkspaceWidgetType.card;
      case 'widget_kpi':
        return GeoWorkspaceWidgetType.kpi;
      case 'widget_table':
        return GeoWorkspaceWidgetType.table;
      default:
        return null;
    }
  }

  List<GeoWorkspacePropertyData> get defaultProperties {
    switch (this) {
      case GeoWorkspaceWidgetType.barVertical:
        return const [
          GeoWorkspacePropertyData(
            key: 'source',
            label: 'Fonte',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste um campo da camada',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'labelField',
            label: 'Campo label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo que será usado como label',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'valueField',
            label: 'Campo valor',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspacePropertyData(
            key: 'chartTitle',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
          GeoWorkspacePropertyData(
            key: 'widthBar',
            label: 'Largura barra',
            type: GeoWorkspacePropertyType.number,
          ),
          GeoWorkspacePropertyData(
            key: 'widthTitleBar',
            label: 'Largura label',
            type: GeoWorkspacePropertyType.number,
          ),
          GeoWorkspacePropertyData(
            key: 'sortType',
            label: 'Ordenação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'descending',
            options: ['none', 'ascending', 'descending', 'labelAZ', 'labelZA'],
          ),
        ];

      case GeoWorkspaceWidgetType.donut:
        return const [
          GeoWorkspacePropertyData(
            key: 'source',
            label: 'Fonte',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste um campo da camada',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'labelField',
            label: 'Campo label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo que será usado como label',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'valueField',
            label: 'Campo valor',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspacePropertyData(
            key: 'chartTitle',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.line:
        return const [
          GeoWorkspacePropertyData(
            key: 'source',
            label: 'Fonte',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste um campo da camada',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'labelField',
            label: 'Campo label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo do eixo X',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'valueField',
            label: 'Campo valor',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo do eixo Y',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspacePropertyData(
            key: 'chartTitle',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.card:
        return const [
          GeoWorkspacePropertyData(
            key: 'source',
            label: 'Fonte',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste um campo da camada',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'label',
            label: 'Label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo de descrição',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'value',
            label: 'Value',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo principal',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Contagem',
            options: ['Contagem', 'Soma', 'Média', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspacePropertyData(
            key: 'title',
            label: 'Título do card',
            type: GeoWorkspacePropertyType.text,
          ),
          GeoWorkspacePropertyData(
            key: 'subtitle',
            label: 'Subtítulo',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.kpi:
        return const [
          GeoWorkspacePropertyData(
            key: 'source',
            label: 'Fonte',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste um campo da camada',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'label',
            label: 'Label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo de descrição',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'value',
            label: 'Value',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo principal',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Contagem',
            options: ['Contagem', 'Soma', 'Média', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspacePropertyData(
            key: 'title',
            label: 'Título do KPI',
            type: GeoWorkspacePropertyType.text,
          ),
          GeoWorkspacePropertyData(
            key: 'variation',
            label: 'Variação',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.table:
        return const [
          GeoWorkspacePropertyData(
            key: 'source',
            label: 'Fonte',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste um campo da camada',
            acceptsDrop: true,
          ),
          GeoWorkspacePropertyData(
            key: 'title',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
          ),
          GeoWorkspacePropertyData(
            key: 'columns',
            label: 'Colunas',
            type: GeoWorkspacePropertyType.stringList,
            hint: 'Ex.: nome, status, valor',
          ),
        ];
    }
  }
}

class GeoWorkspaceItemData {
  final String id;
  final String title;
  final GeoWorkspaceWidgetType type;
  final Offset offset;
  final Size size;
  final List<GeoWorkspacePropertyData> properties;

  const GeoWorkspaceItemData({
    required this.id,
    required this.title,
    required this.type,
    required this.offset,
    required this.size,
    this.properties = const [],
  });

  static const Size minSize = Size(180, 120);

  String get catalogItemId => type.catalogItemId;

  GeoWorkspacePropertyData? propertyByKey(String key) {
    try {
      return properties.firstWhere((e) => e.key == key);
    } catch (_) {
      return null;
    }
  }

  String getTextProperty(String key, {String fallback = ''}) {
    final property = propertyByKey(key);
    return property?.textValue ?? fallback;
  }

  String? getNullableTextProperty(String key) {
    return propertyByKey(key)?.textValue;
  }

  double getNumberProperty(String key, {double fallback = 0}) {
    final property = propertyByKey(key);
    return property?.numberValue ?? fallback;
  }

  double? getNullableNumberProperty(String key) {
    return propertyByKey(key)?.numberValue;
  }

  List<String> getStringListProperty(String key,
      {List<String> fallback = const []}) {
    final property = propertyByKey(key);
    return property?.stringListValue ?? fallback;
  }

  List<String>? getNullableStringListProperty(String key) {
    return propertyByKey(key)?.stringListValue;
  }

  List<double> getNumberListProperty(String key,
      {List<double> fallback = const []}) {
    final property = propertyByKey(key);
    return property?.numberListValue ?? fallback;
  }

  List<double>? getNullableNumberListProperty(String key) {
    return propertyByKey(key)?.numberListValue;
  }

  String getSelectedProperty(String key, {String fallback = ''}) {
    final property = propertyByKey(key);
    return property?.selectedValue ?? fallback;
  }

  String? getNullableSelectedProperty(String key) {
    return propertyByKey(key)?.selectedValue;
  }

  GeoWorkspaceFieldBinding? getBindingProperty(String key) {
    final property = propertyByKey(key);
    return property?.bindingValue;
  }

  GeoWorkspaceItemData copyWith({
    String? id,
    String? title,
    GeoWorkspaceWidgetType? type,
    Offset? offset,
    Size? size,
    List<GeoWorkspacePropertyData>? properties,
  }) {
    return GeoWorkspaceItemData(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      offset: offset ?? this.offset,
      size: size ?? this.size,
      properties: properties ?? this.properties,
    );
  }

  GeoWorkspaceItemData copyWithUpdatedProperty(
      String propertyKey,
      GeoWorkspacePropertyData updatedProperty,
      ) {
    final nextProperties = properties.map((property) {
      if (property.key != propertyKey) return property;
      return updatedProperty;
    }).toList(growable: false);

    return copyWith(properties: nextProperties);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is GeoWorkspaceItemData &&
        other.id == id &&
        other.title == title &&
        other.type == type &&
        other.offset == offset &&
        other.size == size &&
        listEquals(other.properties, properties);
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    type,
    offset,
    size,
    Object.hashAll(properties),
  );
}