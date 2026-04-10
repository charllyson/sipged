import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/attribute/attribute_data.dart';

enum CatalogPropertyType {
  text,
  number,
  select,
  binding,
}

enum CatalogType {
  barVertical,
  donut,
  line,
  card,
}

@immutable
class CatalogData {
  final String id;
  final String title;
  final IconData? icon;
  final String? category;
  final String? description;

  final String? key;
  final String? label;
  final CatalogPropertyType? type;
  final String? hint;
  final bool acceptsDrop;

  final String? textValue;
  final double? numberValue;
  final String? selectedValue;
  final List<String>? options;
  final AttributeData? bindingValue;

  const CatalogData({
    this.id = '',
    this.title = '',
    this.icon,
    this.category,
    this.description,
    this.key,
    this.label,
    this.type,
    this.hint,
    this.acceptsDrop = false,
    this.textValue,
    this.numberValue,
    this.selectedValue,
    this.options,
    this.bindingValue,
  });

  static const Object _sentinel = Object();

  CatalogData copyWith({
    String? id,
    String? title,
    IconData? icon,
    String? category,
    String? description,
    String? key,
    String? label,
    CatalogPropertyType? type,
    String? hint,
    bool? acceptsDrop,
    Object? textValue = _sentinel,
    Object? numberValue = _sentinel,
    Object? selectedValue = _sentinel,
    List<String>? options,
    Object? bindingValue = _sentinel,
  }) {
    return CatalogData(
      id: id ?? this.id,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      category: category ?? this.category,
      description: description ?? this.description,
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
      case CatalogPropertyType.text:
        return textValue ?? '';
      case CatalogPropertyType.number:
        return numberValue?.toString() ?? '';
      case CatalogPropertyType.select:
        return selectedValue ?? '';
      case CatalogPropertyType.binding:
        return bindingValue?.displayValue ?? '';
      case null:
        return '';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'icon': icon == null
          ? null
          : {
        'codePoint': icon!.codePoint,
        'fontFamily': icon!.fontFamily,
        'fontPackage': icon!.fontPackage,
        'matchTextDirection': icon!.matchTextDirection,
      },
      'category': category,
      'description': description,
      'key': key,
      'label': label,
      'type': type?.name,
      'hint': hint,
      'acceptsDrop': acceptsDrop,
      'textValue': textValue,
      'numberValue': numberValue,
      'selectedValue': selectedValue,
      'options': options,
      'bindingValue': bindingValue?.toMap(),
    };
  }

  factory CatalogData.fromMap(Map<String, dynamic> map) {
    IconData? parsedIcon;
    final rawIcon = map['icon'];
    if (rawIcon is Map<String, dynamic>) {
      parsedIcon = IconData(
        rawIcon['codePoint'] as int,
        fontFamily: rawIcon['fontFamily']?.toString(),
        fontPackage: rawIcon['fontPackage']?.toString(),
        matchTextDirection: rawIcon['matchTextDirection'] == true,
      );
    }

    return CatalogData(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      icon: parsedIcon,
      category: map['category']?.toString(),
      description: map['description']?.toString(),
      key: map['key']?.toString(),
      label: map['label']?.toString(),
      type: map['type'] == null
          ? null
          : CatalogPropertyType.values.firstWhere(
            (e) => e.name == map['type'],
        orElse: () => CatalogPropertyType.text,
      ),
      hint: map['hint']?.toString(),
      acceptsDrop: map['acceptsDrop'] == true,
      textValue: map['textValue']?.toString(),
      numberValue: (map['numberValue'] is num)
          ? (map['numberValue'] as num).toDouble()
          : double.tryParse(map['numberValue']?.toString() ?? ''),
      selectedValue: map['selectedValue']?.toString(),
      options: (map['options'] as List?)?.map((e) => e.toString()).toList(),
      bindingValue: map['bindingValue'] is Map<String, dynamic>
          ? AttributeData.fromMap(map['bindingValue'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogData &&
        other.id == id &&
        other.title == title &&
        other.icon == icon &&
        other.category == category &&
        other.description == description &&
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
    id,
    title,
    icon,
    category,
    description,
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

extension ComponentTypeMapper on CatalogType {
  String get catalogItemId {
    switch (this) {
      case CatalogType.barVertical:
        return 'chart_bar_vertical';
      case CatalogType.donut:
        return 'chart_donut';
      case CatalogType.line:
        return 'chart_line';
      case CatalogType.card:
        return 'widget_card';
    }
  }

  String get defaultTitle {
    switch (this) {
      case CatalogType.barVertical:
        return 'Barra vertical';
      case CatalogType.donut:
        return 'Rosca';
      case CatalogType.line:
        return 'Linha';
      case CatalogType.card:
        return 'Card resumo';
    }
  }

  Size get defaultSize {
    switch (this) {
      case CatalogType.barVertical:
        return const Size(420, 280);
      case CatalogType.donut:
        return const Size(360, 260);
      case CatalogType.line:
        return const Size(420, 280);
      case CatalogType.card:
        return const Size(260, 140);
    }
  }

  static CatalogType? fromCatalogItemId(String id) {
    switch (id) {
      case 'chart_bar_vertical':
        return CatalogType.barVertical;
      case 'chart_donut':
        return CatalogType.donut;
      case 'chart_line':
        return CatalogType.line;
      case 'widget_card':
        return CatalogType.card;
      default:
        return null;
    }
  }

  List<CatalogData> get defaultProperties {
    switch (this) {
      case CatalogType.barVertical:
        return const [
          CatalogData(
            key: 'labelField',
            label: 'Label',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo label',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'valueField',
            label: 'Valor',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'aggregation',
            label: 'Agregação',
            type: CatalogPropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          CatalogData(
            key: 'chartTitle',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
          CatalogData(
            key: 'widthBar',
            label: 'Largura barra',
            type: CatalogPropertyType.number,
            hint: 'Ex.: 18',
          ),
          CatalogData(
            key: 'widthTitleBar',
            label: 'Largura label',
            type: CatalogPropertyType.number,
            hint: 'Ex.: 120',
          ),
          CatalogData(
            key: 'sortType',
            label: 'Ordenação',
            type: CatalogPropertyType.select,
            selectedValue: 'descending',
            options: ['none', 'ascending', 'descending', 'labelAZ', 'labelZA'],
          ),
        ];

      case CatalogType.donut:
        return const [
          CatalogData(
            key: 'labelField',
            label: 'Label',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo que será usado como label',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'valueField',
            label: 'Valor',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo numérico',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'aggregation',
            label: 'Agregação',
            type: CatalogPropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          CatalogData(
            key: 'chartTitle',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
        ];

      case CatalogType.line:
        return const [
          CatalogData(
            key: 'labelField',
            label: 'Label',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo do eixo X',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'valueField',
            label: 'Valor',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo do eixo Y',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'aggregation',
            label: 'Agregação',
            type: CatalogPropertyType.select,
            selectedValue: 'Soma',
            options: ['Soma', 'Média', 'Contagem', 'Máximo', 'Mínimo'],
          ),
          CatalogData(
            key: 'chartTitle',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título exibido no gráfico',
          ),
        ];

      case CatalogType.card:
        return const [
          CatalogData(
            key: 'label',
            label: 'Label',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo de descrição',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'value',
            label: 'Valor',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o campo principal',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'aggregation',
            label: 'Agregação',
            type: CatalogPropertyType.select,
            selectedValue: 'Contagem',
            options: ['Contagem', 'Soma', 'Média', 'Máximo', 'Mínimo'],
          ),
          CatalogData(
            key: 'title',
            label: 'Título do card',
            type: CatalogPropertyType.text,
            hint: 'Informe o título',
          ),
          CatalogData(
            key: 'subtitle',
            label: 'Subtítulo',
            type: CatalogPropertyType.text,
            hint: 'Informe o subtítulo',
          ),
        ];
    }
  }
}

abstract final class CatalogRegistry {
  static const List<CatalogData> items = [
    CatalogData(
      id: 'chart_bar_vertical',
      title: 'Barra vertical',
      icon: Icons.bar_chart_rounded,
      category: 'Gráficos',
      description: 'Categoria + valor agregado',
    ),
    CatalogData(
      id: 'chart_donut',
      title: 'Rosca',
      icon: Icons.donut_large_rounded,
      category: 'Gráficos',
      description: 'Segmentos proporcionais',
    ),
    CatalogData(
      id: 'chart_line',
      title: 'Linha',
      icon: Icons.show_chart_rounded,
      category: 'Gráficos',
      description: 'Série temporal ou evolução',
    ),
    CatalogData(
      id: 'widget_card',
      title: 'Card resumo',
      icon: Icons.crop_7_5_rounded,
      category: 'Widgets',
      description: 'Resumo com título e valor',
    ),
  ];

  static final Map<String, List<CatalogData>> groupedItems = _buildGroupedItems();

  static Map<String, List<CatalogData>> _buildGroupedItems() {
    final grouped = <String, List<CatalogData>>{};

    for (final item in items) {
      final category = (item.category ?? 'Outros').trim();
      grouped.putIfAbsent(category, () => <CatalogData>[]);
      grouped[category]!.add(item);
    }

    return grouped;
  }
}