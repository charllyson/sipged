import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'schedule_linear_services_data.dart';

class ScheduleLinearLaneData extends Equatable {
  final int faixaIndex;
  final String pos;
  final String nome;
  final double altura;
  final int? anchor;
  final Color color;
  final String iconKey;
  final IconData icon;
  final Map<String, bool> allowedByService;

  /// Campos locais de edição/UI.
  /// Não devem ser persistidos no Firestore.
  final String? editorId;
  final TextEditingController? posCtrl;
  final TextEditingController? nameCtrl;

  const ScheduleLinearLaneData({
    required this.faixaIndex,
    required this.pos,
    required this.nome,
    required this.altura,
    this.anchor,
    required this.color,
    required this.iconKey,
    required this.icon,
    this.allowedByService = const <String, bool>{},
    this.editorId,
    this.posCtrl,
    this.nameCtrl,
  });

  static const String laneKey = 'lane';

  static const String defaultLaneIconKey = 'view_stream_outlined';
  static const Color defaultLaneColor = Colors.grey;
  static const double defaultLaneHeight = 20.0;

  factory ScheduleLinearLaneData.create({
    required int faixaIndex,
    required String pos,
    required String nome,
    double altura = defaultLaneHeight,
    int? anchor,
    Map<String, bool> allowedByService = const <String, bool>{},
    Color? color,
    String? iconKey,
    IconData? icon,
  }) {
    final resolvedIconKey = ScheduleLinearServicesData.normalizeIconKey(
      iconKey,
      fallback: defaultLaneIconKey,
    );

    return ScheduleLinearLaneData(
      faixaIndex: faixaIndex,
      pos: pos.trim(),
      nome: nome.trim(),
      altura: altura,
      anchor: anchor,
      color: ScheduleLinearServicesData.normalizeColor(
        color,
        fallback: defaultLaneColor,
      ),
      iconKey: resolvedIconKey,
      icon: icon ?? ScheduleLinearServicesData.iconForKey(resolvedIconKey),
      allowedByService: allowedByService,
    );
  }

  factory ScheduleLinearLaneData.editor({
    required int faixaIndex,
    required String pos,
    required String nome,
    double altura = defaultLaneHeight,
    int? anchor,
    Map<String, bool> allowedByService = const <String, bool>{},
    Color? color,
    String? iconKey,
    IconData? icon,
    String? editorId,
  }) {
    final resolvedIconKey = ScheduleLinearServicesData.normalizeIconKey(
      iconKey,
      fallback: defaultLaneIconKey,
    );

    final cleanPos = pos.trim();
    final cleanNome = nome.trim();

    return ScheduleLinearLaneData(
      faixaIndex: faixaIndex,
      pos: cleanPos,
      nome: cleanNome,
      altura: altura,
      anchor: anchor,
      color: ScheduleLinearServicesData.normalizeColor(
        color,
        fallback: defaultLaneColor,
      ),
      iconKey: resolvedIconKey,
      icon: icon ?? ScheduleLinearServicesData.iconForKey(resolvedIconKey),
      allowedByService: allowedByService,
      editorId: editorId ?? UniqueKey().toString(),
      posCtrl: TextEditingController(text: cleanPos),
      nameCtrl: TextEditingController(text: cleanNome),
    );
  }

  factory ScheduleLinearLaneData.fromMap(Map<String, dynamic> map) {
    final iconKey = _asString(map['iconKey']) ?? defaultLaneIconKey;

    return ScheduleLinearLaneData(
      faixaIndex: _asInt(map['faixaIndex']) ?? 0,
      pos: _asString(map['pos']) ?? '',
      nome: _asString(map['nome']) ?? '',
      altura: _asDouble(map['altura']) ?? defaultLaneHeight,
      anchor: _asInt(map['anchor']),
      color: _asColor(map['color']) ?? defaultLaneColor,
      iconKey: iconKey,
      icon: ScheduleLinearServicesData.iconForKey(iconKey),
      allowedByService: _asBoolMap(map['allowedByService']),
    );
  }

  String get laneLabel {
    final p = resolvedPos;
    final n = resolvedNome;

    if (p.isEmpty) return n;
    if (n.isEmpty) return p;

    return '$p - $n';
  }

  String get resolvedPos {
    return (posCtrl?.text ?? pos).trim();
  }

  String get resolvedNome {
    return (nameCtrl?.text ?? nome).trim();
  }

  double get resolvedAltura {
    return altura <= 0 ? defaultLaneHeight : altura;
  }

  bool isAllowed(String serviceKey) {
    final cleanServiceKey = serviceKey.trim();

    if (cleanServiceKey.isEmpty ||
        cleanServiceKey == ScheduleLinearServicesData.geralKey) {
      return true;
    }

    return allowedByService[cleanServiceKey] ?? true;
  }

  void disposeEditorControllers() {
    posCtrl?.dispose();
    nameCtrl?.dispose();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'faixaIndex': faixaIndex,
      'pos': resolvedPos,
      'nome': resolvedNome,
      'altura': resolvedAltura,
      if (anchor != null) 'anchor': anchor,
      'color': color.toARGB32(),
      'iconKey': iconKey,
      if (allowedByService.isNotEmpty) 'allowedByService': allowedByService,
    };
  }

  ScheduleLinearLaneData copyWith({
    int? faixaIndex,
    String? pos,
    String? nome,
    double? altura,
    int? anchor,
    Color? color,
    String? iconKey,
    IconData? icon,
    Map<String, bool>? allowedByService,
    String? editorId,
    TextEditingController? posCtrl,
    TextEditingController? nameCtrl,
  }) {
    final nextIconKey = iconKey ?? this.iconKey;

    final nextIcon = icon ??
        (iconKey != null
            ? ScheduleLinearServicesData.iconForKey(nextIconKey)
            : this.icon);

    return ScheduleLinearLaneData(
      faixaIndex: faixaIndex ?? this.faixaIndex,
      pos: pos ?? this.pos,
      nome: nome ?? this.nome,
      altura: altura ?? this.altura,
      anchor: anchor ?? this.anchor,
      color: color ?? this.color,
      iconKey: nextIconKey,
      icon: nextIcon,
      allowedByService: allowedByService ?? this.allowedByService,
      editorId: editorId ?? this.editorId,
      posCtrl: posCtrl ?? this.posCtrl,
      nameCtrl: nameCtrl ?? this.nameCtrl,
    );
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

  static double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is num) return value.toDouble();

    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.');

      if (cleaned.isEmpty) return null;

      return double.tryParse(cleaned);
    }

    return null;
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;

    final text = value.toString().trim();

    if (text.isEmpty) return null;

    return text;
  }

  static Color? _asColor(dynamic value) {
    final colorInt = _asInt(value);

    if (colorInt == null) return null;

    return Color(colorInt);
  }

  static Map<String, bool> _asBoolMap(dynamic value) {
    if (value is Map) {
      return <String, bool>{
        for (final entry in value.entries)
          entry.key.toString().trim(): entry.value == true,
      }..removeWhere(
            (key, _) =>
        key.isEmpty || key == ScheduleLinearServicesData.geralKey,
      );
    }

    return const <String, bool>{};
  }

  @override
  List<Object?> get props => <Object?>[
    faixaIndex,
    pos,
    nome,
    altura,
    anchor,
    color.toARGB32(),
    iconKey,
    icon.codePoint,
    allowedByService,
    editorId,
    posCtrl?.text,
    nameCtrl?.text,
  ];
}