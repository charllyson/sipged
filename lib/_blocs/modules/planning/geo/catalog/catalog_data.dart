import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sipged/_blocs/modules/planning/geo/feature/feature_binding.dart';

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

  // Novos componentes
  costRuler,
  gauge,
  horizontalBars,
  radar,
  treemap,
  selectorDates,
  dateField,
  switcher,
  textField,
  pagedTable,
}

abstract final class CatalogIconMapper {
  static const Map<String, IconData> _icons = {
    'bar_chart_rounded': Icons.bar_chart_rounded,
    'donut_large_rounded': Icons.donut_large_rounded,
    'show_chart_rounded': Icons.show_chart_rounded,
    'crop_7_5_rounded': Icons.crop_7_5_rounded,
    'straighten_rounded': Icons.straighten_rounded,
    'speed_rounded': Icons.speed_rounded,
    'view_stream_rounded': Icons.view_stream_rounded,
    'radar_rounded': Icons.radar_rounded,
    'grid_view_rounded': Icons.grid_view_rounded,
    'date_range_rounded': Icons.date_range_rounded,
    'event_rounded': Icons.event_rounded,
    'toggle_on_rounded': Icons.toggle_on_rounded,
    'text_fields_rounded': Icons.text_fields_rounded,
    'table_rows_rounded': Icons.table_rows_rounded,
    'help_outline_rounded': Icons.help_outline_rounded,
  };

  static IconData? fromKey(String? key) {
    if (key == null || key.trim().isEmpty) return null;
    return _icons[key];
  }

  static String? toKey(IconData? icon) {
    if (icon == null) return null;

    for (final entry in _icons.entries) {
      if (entry.value == icon) return entry.key;
    }

    return null;
  }
}

@immutable
class CatalogData {
  final String id;
  final String title;
  final IconData? icon;
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
  final FeatureDataBinding? bindingValue;

  const CatalogData({
    this.id = '',
    this.title = '',
    this.icon,
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
          : bindingValue as FeatureDataBinding?,
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
      'iconKey': CatalogIconMapper.toKey(icon),
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
    final rawIconKey = map['iconKey']?.toString();

    return CatalogData(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      icon: CatalogIconMapper.fromKey(rawIconKey),
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
          ? FeatureDataBinding.fromMap(
        map['bindingValue'] as Map<String, dynamic>,
      )
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CatalogData &&
        other.id == id &&
        other.title == title &&
        other.icon == icon &&
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
      case CatalogType.costRuler:
        return 'widget_cost_ruler';
      case CatalogType.gauge:
        return 'chart_gauge';
      case CatalogType.horizontalBars:
        return 'chart_horizontal_bars';
      case CatalogType.radar:
        return 'chart_radar';
      case CatalogType.treemap:
        return 'chart_treemap';
      case CatalogType.selectorDates:
        return 'filter_selector_dates';
      case CatalogType.dateField:
        return 'input_date_field';
      case CatalogType.switcher:
        return 'input_switch';
      case CatalogType.textField:
        return 'input_text_field';
      case CatalogType.pagedTable:
        return 'table_paged';
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
      case CatalogType.costRuler:
        return 'Régua de custo';
      case CatalogType.gauge:
        return 'Gauge';
      case CatalogType.horizontalBars:
        return 'Barras horizontais';
      case CatalogType.radar:
        return 'Radar';
      case CatalogType.treemap:
        return 'Treemap';
      case CatalogType.selectorDates:
        return 'Seletor de datas';
      case CatalogType.dateField:
        return 'Campo de data';
      case CatalogType.switcher:
        return 'Switch';
      case CatalogType.textField:
        return 'Campo de texto';
      case CatalogType.pagedTable:
        return 'Tabela paginada';
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
      case CatalogType.costRuler:
        return const Size(420, 180);
      case CatalogType.gauge:
        return const Size(280, 280);
      case CatalogType.horizontalBars:
        return const Size(420, 320);
      case CatalogType.radar:
        return const Size(420, 360);
      case CatalogType.treemap:
        return const Size(460, 320);
      case CatalogType.selectorDates:
        return const Size(520, 180);
      case CatalogType.dateField:
        return const Size(260, 90);
      case CatalogType.switcher:
        return const Size(180, 90);
      case CatalogType.textField:
        return const Size(320, 90);
      case CatalogType.pagedTable:
        return const Size(760, 360);
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
      case 'widget_cost_ruler':
        return CatalogType.costRuler;
      case 'chart_gauge':
        return CatalogType.gauge;
      case 'chart_horizontal_bars':
        return CatalogType.horizontalBars;
      case 'chart_radar':
        return CatalogType.radar;
      case 'chart_treemap':
        return CatalogType.treemap;
      case 'filter_selector_dates':
        return CatalogType.selectorDates;
      case 'input_date_field':
        return CatalogType.dateField;
      case 'input_switch':
        return CatalogType.switcher;
      case 'input_text_field':
        return CatalogType.textField;
      case 'table_paged':
        return CatalogType.pagedTable;
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

      case CatalogType.costRuler:
        return const [
          CatalogData(
            key: 'title',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título da régua',
          ),
          CatalogData(
            key: 'valueField',
            label: 'Valor',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o valor principal',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'divisorField',
            label: 'Divisor',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o divisor',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'unitLabel',
            label: 'Unidade',
            type: CatalogPropertyType.text,
            hint: 'Ex.: km, h, un, m²',
          ),
        ];

      case CatalogType.gauge:
        return const [
          CatalogData(
            key: 'headerLabel',
            label: 'Cabeçalho',
            type: CatalogPropertyType.text,
            hint: 'Texto do topo',
          ),
          CatalogData(
            key: 'centerValue',
            label: 'Valor central',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o valor percentual',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'footerLabel',
            label: 'Rodapé',
            type: CatalogPropertyType.text,
            hint: 'Texto inferior',
          ),
        ];

      case CatalogType.horizontalBars:
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
            hint: 'Arraste o campo valor',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'title',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título do gráfico',
          ),
        ];

      case CatalogType.radar:
        return const [
          CatalogData(
            key: 'labelField',
            label: 'Label',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o eixo/categoria',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'valueField',
            label: 'Valor',
            type: CatalogPropertyType.binding,
            hint: 'Arraste o valor',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'title',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título do radar',
          ),
        ];

      case CatalogType.treemap:
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
            hint: 'Arraste o valor total',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'title',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título do treemap',
          ),
        ];

      case CatalogType.selectorDates:
        return const [
          CatalogData(
            key: 'dateField',
            label: 'Campo de data',
            type: CatalogPropertyType.binding,
            hint: 'Arraste um campo de data',
            acceptsDrop: true,
          ),
          CatalogData(
            key: 'title',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título do seletor',
          ),
          CatalogData(
            key: 'enableDaySelection',
            label: 'Selecionar dia',
            type: CatalogPropertyType.select,
            selectedValue: 'false',
            options: ['true', 'false'],
          ),
        ];

      case CatalogType.dateField:
        return const [
          CatalogData(
            key: 'labelText',
            label: 'Label',
            type: CatalogPropertyType.text,
            hint: 'Texto do campo',
          ),
          CatalogData(
            key: 'hintText',
            label: 'Hint',
            type: CatalogPropertyType.text,
            hint: 'Texto de ajuda',
          ),
        ];

      case CatalogType.switcher:
        return const [
          CatalogData(
            key: 'textOn',
            label: 'Texto ON',
            type: CatalogPropertyType.text,
            hint: 'Ex.: Ligado',
          ),
          CatalogData(
            key: 'textOff',
            label: 'Texto OFF',
            type: CatalogPropertyType.text,
            hint: 'Ex.: Desligado',
          ),
        ];

      case CatalogType.textField:
        return const [
          CatalogData(
            key: 'labelText',
            label: 'Label',
            type: CatalogPropertyType.text,
            hint: 'Texto do campo',
          ),
          CatalogData(
            key: 'hintText',
            label: 'Hint',
            type: CatalogPropertyType.text,
            hint: 'Texto de ajuda',
          ),
          CatalogData(
            key: 'prefixText',
            label: 'Prefixo',
            type: CatalogPropertyType.text,
            hint: r'Ex.: R$',
          ),
        ];

      case CatalogType.pagedTable:
        return const [
          CatalogData(
            key: 'title',
            label: 'Título',
            type: CatalogPropertyType.text,
            hint: 'Título da tabela',
          ),
          CatalogData(
            key: 'rowsPerPage',
            label: 'Linhas por página',
            type: CatalogPropertyType.number,
            hint: 'Ex.: 10, 25, 50',
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
      description: 'Categoria + valor agregado',
    ),
    CatalogData(
      id: 'chart_donut',
      title: 'Rosca',
      icon: Icons.donut_large_rounded,
      description: 'Segmentos proporcionais',
    ),
    CatalogData(
      id: 'chart_line',
      title: 'Linha',
      icon: Icons.show_chart_rounded,
      description: 'Série temporal ou evolução',
    ),
    CatalogData(
      id: 'widget_card',
      title: 'Card resumo',
      icon: Icons.crop_7_5_rounded,
      description: 'Resumo com título e valor',
    ),
    CatalogData(
      id: 'widget_cost_ruler',
      title: 'Régua de custo',
      icon: Icons.straighten_rounded,
      description: 'Indicador comparativo por faixa',
    ),
    CatalogData(
      id: 'chart_gauge',
      title: 'Gauge',
      icon: Icons.speed_rounded,
      description: 'Indicador circular percentual',
    ),
    CatalogData(
      id: 'chart_horizontal_bars',
      title: 'Barras horizontais',
      icon: Icons.view_stream_rounded,
      description: 'Ranking horizontal por valor',
    ),
    CatalogData(
      id: 'chart_radar',
      title: 'Radar',
      icon: Icons.radar_rounded,
      description: 'Comparação multieixos',
    ),
    CatalogData(
      id: 'chart_treemap',
      title: 'Treemap',
      icon: Icons.grid_view_rounded,
      description: 'Distribuição proporcional por área',
    ),
    CatalogData(
      id: 'filter_selector_dates',
      title: 'Seletor de datas',
      icon: Icons.date_range_rounded,
      description: 'Filtro por ano, mês e dia',
    ),
    CatalogData(
      id: 'input_date_field',
      title: 'Campo de data',
      icon: Icons.event_rounded,
      description: 'Entrada de data',
    ),
    CatalogData(
      id: 'input_switch',
      title: 'Switch',
      icon: Icons.toggle_on_rounded,
      description: 'Controle liga/desliga',
    ),
    CatalogData(
      id: 'input_text_field',
      title: 'Campo de texto',
      icon: Icons.text_fields_rounded,
      description: 'Entrada textual',
    ),
    CatalogData(
      id: 'table_paged',
      title: 'Tabela paginada',
      icon: Icons.table_rows_rounded,
      description: 'Tabela com paginação',
    ),
  ];

  static final Map<String, List<CatalogData>> groupedItems = _buildGroupedItems();

  static Map<String, List<CatalogData>> _buildGroupedItems() {
    return {
      'Gráficos': const [
        CatalogData(
          id: 'chart_bar_vertical',
          title: 'Barra vertical',
          icon: Icons.bar_chart_rounded,
          description: 'Categoria + valor agregado',
        ),
        CatalogData(
          id: 'chart_donut',
          title: 'Rosca',
          icon: Icons.donut_large_rounded,
          description: 'Segmentos proporcionais',
        ),
        CatalogData(
          id: 'chart_line',
          title: 'Linha',
          icon: Icons.show_chart_rounded,
          description: 'Série temporal ou evolução',
        ),
        CatalogData(
          id: 'chart_gauge',
          title: 'Gauge',
          icon: Icons.speed_rounded,
          description: 'Indicador circular percentual',
        ),
        CatalogData(
          id: 'chart_horizontal_bars',
          title: 'Barras horizontais',
          icon: Icons.view_stream_rounded,
          description: 'Ranking horizontal por valor',
        ),
        CatalogData(
          id: 'chart_radar',
          title: 'Radar',
          icon: Icons.radar_rounded,
          description: 'Comparação multieixos',
        ),
        CatalogData(
          id: 'chart_treemap',
          title: 'Treemap',
          icon: Icons.grid_view_rounded,
          description: 'Distribuição proporcional por área',
        ),
      ],
      'Widgets': const [
        CatalogData(
          id: 'widget_card',
          title: 'Card resumo',
          icon: Icons.crop_7_5_rounded,
          description: 'Resumo com título e valor',
        ),
        CatalogData(
          id: 'widget_cost_ruler',
          title: 'Régua de custo',
          icon: Icons.straighten_rounded,
          description: 'Indicador comparativo por faixa',
        ),
      ],
      'Filtros e entradas': const [
        CatalogData(
          id: 'filter_selector_dates',
          title: 'Seletor de datas',
          icon: Icons.date_range_rounded,
          description: 'Filtro por ano, mês e dia',
        ),
        CatalogData(
          id: 'input_date_field',
          title: 'Campo de data',
          icon: Icons.event_rounded,
          description: 'Entrada de data',
        ),
        CatalogData(
          id: 'input_switch',
          title: 'Switch',
          icon: Icons.toggle_on_rounded,
          description: 'Controle liga/desliga',
        ),
        CatalogData(
          id: 'input_text_field',
          title: 'Campo de texto',
          icon: Icons.text_fields_rounded,
          description: 'Entrada textual',
        ),
      ],
      'Tabelas': const [
        CatalogData(
          id: 'table_paged',
          title: 'Tabela paginada',
          icon: Icons.table_rows_rounded,
          description: 'Tabela com paginação',
        ),
      ],
    };
  }
}