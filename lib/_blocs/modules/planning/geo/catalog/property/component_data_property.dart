import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data.dart';

enum ComponentPropertyType {
  text,
  number,
  select,
  binding,
}

enum GeoWorkspaceSnapEdge {
  left,
  centerX,
  right,
  top,
  centerY,
  bottom,
}

enum ComponentType {
  barVertical,
  donut,
  line,
  card,
}

@immutable
class ComponentDataProperty {
  final String key;
  final String label;
  final ComponentPropertyType type;
  final String? hint;
  final bool acceptsDrop;

  final String? textValue;
  final double? numberValue;
  final String? selectedValue;
  final List<String>? options;
  final AttributeData? bindingValue;

  const ComponentDataProperty({
    required this.key,
    required this.label,
    required this.type,
    this.hint,
    this.acceptsDrop = false,
    this.textValue,
    this.numberValue,
    this.selectedValue,
    this.options,
    this.bindingValue,
  });

  static const Object _sentinel = Object();

  ComponentDataProperty copyWith({
    String? key,
    String? label,
    ComponentPropertyType? type,
    String? hint,
    bool? acceptsDrop,
    Object? textValue = _sentinel,
    Object? numberValue = _sentinel,
    Object? selectedValue = _sentinel,
    List<String>? options,
    Object? bindingValue = _sentinel,
  }) {
    return ComponentDataProperty(
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
      selectedValue: identical(selectedValue, _sentinel)
          ? this.selectedValue
          : selectedValue as String?,
      options: options ?? this.options,
      bindingValue: identical(bindingValue, _sentinel)
          ? this.bindingValue
          : bindingValue as AttributeData?,
    );
  }

  String get displayValue {
    switch (type) {
      case ComponentPropertyType.text:
        return textValue ?? '';
      case ComponentPropertyType.number:
        return numberValue?.toString() ?? '';
      case ComponentPropertyType.select:
        return selectedValue ?? '';
      case ComponentPropertyType.binding:
        return bindingValue?.displayValue ?? '';
    }
  }

  @override
  bool operator ==(Object other) {
    return other is ComponentDataProperty &&
        other.key == key &&
        other.label == label &&
        other.type == type &&
        other.hint == hint &&
        other.acceptsDrop == acceptsDrop &&
        other.textValue == textValue &&
        other.numberValue == numberValue &&
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
    selectedValue,
    Object.hashAll(options ?? const []),
    bindingValue,
  );
}

extension ComponentTypeMapper on ComponentType {
  String get catalogItemId {
    switch (this) {
      case ComponentType.barVertical:
        return 'chart_bar_vertical';
      case ComponentType.donut:
        return 'chart_donut';
      case ComponentType.line:
        return 'chart_line';
      case ComponentType.card:
        return 'widget_card';
    }
  }

  String get defaultTitle {
    switch (this) {
      case ComponentType.barVertical:
        return 'Barra vertical';
      case ComponentType.donut:
        return 'Rosca';
      case ComponentType.line:
        return 'Linha';
      case ComponentType.card:
        return 'Card resumo';
    }
  }

  Size get defaultSize {
    switch (this) {
      case ComponentType.barVertical:
        return const Size(420, 280);
      case ComponentType.donut:
        return const Size(360, 260);
      case ComponentType.line:
        return const Size(420, 280);
      case ComponentType.card:
        return const Size(260, 140);
    }
  }

  static ComponentType? fromCatalogItemId(String id) {
    switch (id) {
      case 'chart_bar_vertical':
        return ComponentType.barVertical;
      case 'chart_donut':
        return ComponentType.donut;
      case 'chart_line':
        return ComponentType.line;
      case 'widget_card':
        return ComponentType.card;
      default:
        return null;
    }
  }

  List<ComponentDataProperty> get defaultProperties {
    switch (this) {
      case ComponentType.barVertical:
        return const [
          ComponentDataProperty(
            key: 'labelField',
            label: 'Label',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo label',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'valueField',
            label: 'Valor',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: ComponentPropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          ComponentDataProperty(
            key: 'chartTitle',
            label: 'Título',
            type: ComponentPropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
          ComponentDataProperty(
            key: 'widthBar',
            label: 'Largura barra',
            type: ComponentPropertyType.number,
            hint: 'Ex.: 18',
          ),
          ComponentDataProperty(
            key: 'widthTitleBar',
            label: 'Largura label',
            type: ComponentPropertyType.number,
            hint: 'Ex.: 120',
          ),
          ComponentDataProperty(
            key: 'sortType',
            label: 'Ordenação',
            type: ComponentPropertyType.select,
            selectedValue: 'descending',
            options: ['none', 'ascending', 'descending', 'labelAZ', 'labelZA'],
          ),
        ];

      case ComponentType.donut:
        return const [
          ComponentDataProperty(
            key: 'labelField',
            label: 'Label',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo que será usado como label',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'valueField',
            label: 'Valor',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: ComponentPropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          ComponentDataProperty(
            key: 'chartTitle',
            label: 'Título',
            type: ComponentPropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
        ];

      case ComponentType.line:
        return const [
          ComponentDataProperty(
            key: 'labelField',
            label: 'Label',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo do eixo X',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'valueField',
            label: 'Valor',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo do eixo Y',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: ComponentPropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          ComponentDataProperty(
            key: 'chartTitle',
            label: 'Título',
            type: ComponentPropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
        ];

      case ComponentType.card:
        return const [
          ComponentDataProperty(
            key: 'label',
            label: 'Label',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo de descrição',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'value',
            label: 'Valor',
            type: ComponentPropertyType.binding,
            hint: 'Arraste o campo principal',
            acceptsDrop: true,
          ),
          ComponentDataProperty(
            key: 'aggregation',
            label: 'Agregação',
            type: ComponentPropertyType.select,
            selectedValue: 'Contagem',
            options: ['Contagem', 'Soma', 'Média', 'Máximo', 'Mínimo'],
          ),
          ComponentDataProperty(
            key: 'title',
            label: 'Título do card',
            type: ComponentPropertyType.text,
            hint: 'Informe o título',
          ),
          ComponentDataProperty(
            key: 'subtitle',
            label: 'Subtítulo',
            type: ComponentPropertyType.text,
            hint: 'Informe o subtítulo',
          ),
        ];
    }
  }
}