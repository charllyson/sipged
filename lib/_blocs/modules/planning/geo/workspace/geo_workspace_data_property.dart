
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/workspace/geo_workspace_data_field.dart';

enum GeoWorkspacePropertyType {
  text,
  number,
  stringList,
  numberList,
  select,
  binding,
}

class GeoWorkspaceDataProperty {
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
  final GeoWorkspaceFieldData? bindingValue;

  const GeoWorkspaceDataProperty({
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

  GeoWorkspaceDataProperty copyWith({
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
    return GeoWorkspaceDataProperty(
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
          : bindingValue as GeoWorkspaceFieldData?,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GeoWorkspaceDataProperty &&
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

  List<GeoWorkspaceDataProperty> get defaultProperties {
    switch (this) {
      case GeoWorkspaceWidgetType.barVertical:
        return const [
          GeoWorkspaceDataProperty(
            key: 'labelField',
            label: 'Label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo label',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'valueField',
            label: 'Valor',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspaceDataProperty(
            key: 'chartTitle',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
          GeoWorkspaceDataProperty(
            key: 'widthBar',
            label: 'Largura barra',
            type: GeoWorkspacePropertyType.number,
          ),
          GeoWorkspaceDataProperty(
            key: 'widthTitleBar',
            label: 'Largura label',
            type: GeoWorkspacePropertyType.number,
          ),
          GeoWorkspaceDataProperty(
            key: 'sortType',
            label: 'Ordenação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'descending',
            options: ['none', 'ascending', 'descending', 'labelAZ', 'labelZA'],
          ),
        ];

      case GeoWorkspaceWidgetType.donut:
        return const [
          GeoWorkspaceDataProperty(
            key: 'labelField',
            label: 'Label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo que será usado como label',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'valueField',
            label: 'Valor',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspaceDataProperty(
            key: 'chartTitle',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.line:
        return const [
          GeoWorkspaceDataProperty(
            key: 'labelField',
            label: 'Label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo do eixo X',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'valueField',
            label: 'Valor',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo do eixo Y',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspaceDataProperty(
            key: 'chartTitle',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.card:
        return const [
          GeoWorkspaceDataProperty(
            key: 'label',
            label: 'Label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo de descrição',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'value',
            label: 'Value',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo principal',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Contagem',
            options: ['Contagem', 'Soma', 'Média', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspaceDataProperty(
            key: 'title',
            label: 'Título do card',
            type: GeoWorkspacePropertyType.text,
          ),
          GeoWorkspaceDataProperty(
            key: 'subtitle',
            label: 'Subtítulo',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.kpi:
        return const [
          GeoWorkspaceDataProperty(
            key: 'label',
            label: 'Label',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo de descrição',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'value',
            label: 'Value',
            type: GeoWorkspacePropertyType.binding,
            hint: 'Arraste o campo principal',
            acceptsDrop: true,
          ),
          GeoWorkspaceDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: GeoWorkspacePropertyType.select,
            selectedValue: 'Contagem',
            options: ['Contagem', 'Soma', 'Média', 'Máximo', 'Mínimo'],
          ),
          GeoWorkspaceDataProperty(
            key: 'title',
            label: 'Título do KPI',
            type: GeoWorkspacePropertyType.text,
          ),
          GeoWorkspaceDataProperty(
            key: 'variation',
            label: 'Variação',
            type: GeoWorkspacePropertyType.text,
          ),
        ];

      case GeoWorkspaceWidgetType.table:
        return const [
          GeoWorkspaceDataProperty(
            key: 'title',
            label: 'Título',
            type: GeoWorkspacePropertyType.text,
          ),
          GeoWorkspaceDataProperty(
            key: 'columns',
            label: 'Colunas',
            type: GeoWorkspacePropertyType.stringList,
            hint: 'Ex.: nome, status, valor',
          ),
        ];
    }
  }
}