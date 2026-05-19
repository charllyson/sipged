// lib/_blocs/modules/operation/schedule/horizontal/schedule_linear_services_data.dart

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:sipged/_widgets/draw/icons/icons_change_catalog.dart';

class ScheduleLinearServicesData extends Equatable {
  final String key;
  final String label;
  final String iconKey;
  final IconData icon;
  final Color color;

  /// Ordem vertical/camada do serviço.
  ///
  /// Quanto menor o número, mais acima o serviço fica.
  /// Exemplo:
  /// 1 = camada superior / maior prioridade visual
  /// 2 = camada intermediária
  /// 3 = camada inferior
  final int layerOrder;

  const ScheduleLinearServicesData({
    required this.key,
    required this.label,
    required this.iconKey,
    required this.icon,
    required this.color,
    this.layerOrder = defaultLayerOrder,
  });

  static const String geralKey = 'geral';

  static const String geralIconKey = 'clear_all';
  static const String defaultServiceIconKey = 'layers_outlined';

  static const Color defaultServiceColor = Colors.grey;
  static const Color defaultGeralColor = Colors.grey;

  static const int defaultLayerOrder = 100;
  static const int geralLayerOrder = -999;

  static const ScheduleLinearServicesData emptyGeral = ScheduleLinearServicesData(
    key: geralKey,
    label: 'GERAL',
    iconKey: geralIconKey,
    icon: Icons.clear_all,
    color: defaultGeralColor,
    layerOrder: geralLayerOrder,
  );

  factory ScheduleLinearServicesData.geral() {
    return emptyGeral;
  }

  factory ScheduleLinearServicesData.create({
    required String key,
    required String label,
    String? iconKey,
    IconData? icon,
    Color? color,
    int? layerOrder,
  }) {
    final cleanKey = key.trim();
    final cleanLabel = label.trim();

    final isGeral = cleanKey == geralKey;

    final resolvedIconKey = isGeral
        ? geralIconKey
        : normalizeIconKey(
      iconKey,
      fallback: defaultServiceIconKey,
    );

    final resolvedColor = isGeral
        ? defaultGeralColor
        : normalizeColor(
      color,
      fallback: defaultServiceColor,
    );

    final resolvedLayerOrder = isGeral
        ? geralLayerOrder
        : normalizeLayerOrder(layerOrder);

    return ScheduleLinearServicesData(
      key: cleanKey,
      label: cleanLabel.isEmpty ? cleanKey.toUpperCase() : cleanLabel,
      iconKey: resolvedIconKey,
      icon: icon ?? iconForKey(resolvedIconKey),
      color: resolvedColor,
      layerOrder: resolvedLayerOrder,
    );
  }

  factory ScheduleLinearServicesData.fromMap(Map<String, dynamic> map) {
    final key = _asString(map['key']) ?? geralKey;
    final label = _asString(map['label']) ?? key.toUpperCase();

    final rawIconKey = _asString(map['iconKey']) ?? _asString(map['icon']);

    final resolvedIconKey = key == geralKey
        ? geralIconKey
        : normalizeIconKey(
      rawIconKey,
      fallback: defaultServiceIconKey,
    );

    final resolvedColor = key == geralKey
        ? defaultGeralColor
        : _asColor(map['color']) ?? defaultServiceColor;

    final resolvedLayerOrder = key == geralKey
        ? geralLayerOrder
        : normalizeLayerOrder(_asInt(map['layerOrder']));

    return ScheduleLinearServicesData(
      key: key,
      label: label,
      iconKey: resolvedIconKey,
      icon: iconForKey(resolvedIconKey),
      color: resolvedColor,
      layerOrder: resolvedLayerOrder,
    );
  }

  bool get isGeral {
    return key.trim() == geralKey;
  }

  Map<String, dynamic> toMap() {
    final cleanKey = key.trim();
    final isServiceGeral = cleanKey == geralKey;

    return <String, dynamic>{
      'key': cleanKey,
      'label': label.trim(),
      'iconKey': isServiceGeral
          ? geralIconKey
          : normalizeIconKey(
        iconKey,
        fallback: defaultServiceIconKey,
      ),
      'color': color.toARGB32(),
      'layerOrder':
      isServiceGeral ? geralLayerOrder : normalizeLayerOrder(layerOrder),
    };
  }

  ScheduleLinearServicesData copyWith({
    String? key,
    String? label,
    String? iconKey,
    IconData? icon,
    Color? color,
    int? layerOrder,
  }) {
    final nextKey = key ?? this.key;
    final nextIconKey = iconKey ?? this.iconKey;
    final isNextGeral = nextKey.trim() == geralKey;

    final nextIcon = icon ??
        (iconKey != null
            ? iconForKey(nextIconKey)
            : this.icon);

    return ScheduleLinearServicesData(
      key: nextKey,
      label: label ?? this.label,
      iconKey: isNextGeral ? geralIconKey : nextIconKey,
      icon: isNextGeral ? Icons.clear_all : nextIcon,
      color: isNextGeral ? defaultGeralColor : color ?? this.color,
      layerOrder: isNextGeral
          ? geralLayerOrder
          : normalizeLayerOrder(layerOrder ?? this.layerOrder),
    );
  }

  static String normalizeIconKey(
      String? value, {
        String fallback = defaultServiceIconKey,
      }) {
    final clean = (value ?? '').trim();

    if (clean.isEmpty) return fallback;

    return clean;
  }

  static Color normalizeColor(
      Color? value, {
        Color fallback = defaultServiceColor,
      }) {
    return value ?? fallback;
  }

  static int normalizeLayerOrder(int? value) {
    if (value == null) return defaultLayerOrder;

    if (value < 1) return 1;

    return value;
  }

  static IconData iconForKey(String key) {
    final clean = key.trim();

    if (clean.isEmpty) {
      return IconsCatalog.iconFor(defaultServiceIconKey);
    }

    if (clean == geralIconKey || clean == geralKey) {
      return Icons.clear_all;
    }

    return IconsCatalog.iconFor(clean);
  }

  static int compareByLayer(
      ScheduleLinearServicesData a,
      ScheduleLinearServicesData b,
      ) {
    if (a.isGeral) return -1;
    if (b.isGeral) return 1;

    final byLayer = a.layerOrder.compareTo(b.layerOrder);

    if (byLayer != 0) return byLayer;

    return a.label.toUpperCase().compareTo(b.label.toUpperCase());
  }

  static int compareSpecificByLayer(
      ScheduleLinearServicesData a,
      ScheduleLinearServicesData b,
      ) {
    final byLayer = a.layerOrder.compareTo(b.layerOrder);

    if (byLayer != 0) return byLayer;

    return a.label.toUpperCase().compareTo(b.label.toUpperCase());
  }

  static List<ScheduleLinearServicesData> sortByLayer(
      List<ScheduleLinearServicesData> source,
      ) {
    final list = List<ScheduleLinearServicesData>.from(source);

    list.sort(compareByLayer);

    return List<ScheduleLinearServicesData>.unmodifiable(list);
  }

  static List<ScheduleLinearServicesData> specificSortedByLayer(
      List<ScheduleLinearServicesData> source,
      ) {
    final list = source.where((service) => !service.isGeral).toList();

    list.sort(compareSpecificByLayer);

    return List<ScheduleLinearServicesData>.unmodifiable(list);
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is num) return value.toInt();

    if (value is String) {
      final cleaned = value.trim();

      if (cleaned.isEmpty) return null;

      return int.tryParse(cleaned);
    }

    return null;
  }

  static Color? _asColor(dynamic value) {
    final colorInt = _asInt(value);

    if (colorInt == null) return null;

    return Color(colorInt);
  }

  @override
  List<Object?> get props => <Object?>[
    key,
    label,
    iconKey,
    icon.codePoint,
    color.toARGB32(),
    layerOrder,
  ];
}