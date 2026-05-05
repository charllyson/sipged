import 'package:flutter/material.dart';

/// Ferramentas de texto disponíveis na toolbox.
enum TextTool {
  /// Texto de ponto (uma linha, cresce conforme o conteúdo).
  point,

  /// Caixa de texto com largura/altura fixas (quebra de linha).
  area,

  /// Texto vertical (uma linha), orientação vertical.
  verticalPoint,

  /// Caixa de texto vertical (quebra de linha na vertical).
  verticalArea,

  /// Texto monoespaçado (útil para medidas/códigos).
  monospace,
}

/// Modelo de um item de texto inserido sobre a página.
///
/// - [position]: coordenada em "page space" (mesmo espaço dos polígonos).
/// - [text]: conteúdo textual.
/// - [areaSize]: se não for `null`, o texto é um "texto em área" (com quebra),
///   limitado a essa largura/altura. Se `null`, é texto de ponto.
/// - [vertical]: se `true`, representa texto vertical.
/// - [monospace]: usa família monoespaçada.
/// - [fontSize], [weight], [color]: estilo básico.
/// - [align]: alinhamento do texto.
class TextItem {
  const TextItem({
    required this.position,
    required this.text,
    this.areaSize,
    this.vertical = false,
    this.monospace = false,
    this.fontSize = 16.0,
    this.weight = FontWeight.w600,
    this.color = Colors.white,
    this.align = TextAlign.start,
  });

  /// Posição (em coordenadas da página) do canto superior esquerdo do texto.
  final Offset position;

  /// Conteúdo textual.
  final String text;

  /// Dimensões da área de texto (se `null`, é texto de ponto).
  final Size? areaSize;

  /// Se `true`, texto com orientação vertical.
  final bool vertical;

  /// Se `true`, usa fonte monoespaçada.
  final bool monospace;

  /// Tamanho da fonte.
  final double fontSize;

  /// Peso da fonte.
  final FontWeight weight;

  /// Cor do texto.
  final Color color;

  /// Alinhamento do texto.
  final TextAlign align;

  /// Constrói o [TextStyle] correspondente às propriedades atuais.
  TextStyle get style => TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: weight,
    fontFamily: monospace ? 'monospace' : null,
  );

  /// Cópia com alterações.
  TextItem copyWith({
    Offset? position,
    String? text,
    Size? areaSize,
    bool? vertical,
    bool? monospace,
    double? fontSize,
    FontWeight? weight,
    Color? color,
    TextAlign? align,
  }) {
    return TextItem(
      position: position ?? this.position,
      text: text ?? this.text,
      areaSize: areaSize ?? this.areaSize,
      vertical: vertical ?? this.vertical,
      monospace: monospace ?? this.monospace,
      fontSize: fontSize ?? this.fontSize,
      weight: weight ?? this.weight,
      color: color ?? this.color,
      align: align ?? this.align,
    );
  }

  Map<String, dynamic> toMap() => {
    'position': {
      'dx': position.dx,
      'dy': position.dy,
    },
    if (areaSize != null)
      'areaSize': {
        'w': areaSize!.width,
        'h': areaSize!.height,
      },
    'text': text,
    'vertical': vertical,
    'monospace': monospace,
    'fontSize': fontSize,
    'weight': weight.value,
    'color': color.toARGB32(),
    'align': align.name,
  };

  factory TextItem.fromMap(Map<String, dynamic> map) {
    final pos = Map<String, dynamic>.from(
      (map['position'] as Map?) ?? const <String, dynamic>{},
    );

    final area = map['areaSize'] == null
        ? null
        : Map<String, dynamic>.from(map['areaSize'] as Map);

    return TextItem(
      position: Offset(
        ((pos['dx'] ?? 0) as num).toDouble(),
        ((pos['dy'] ?? 0) as num).toDouble(),
      ),
      text: (map['text'] ?? '') as String,
      areaSize: area == null
          ? null
          : Size(
        ((area['w'] ?? 0) as num).toDouble(),
        ((area['h'] ?? 0) as num).toDouble(),
      ),
      vertical: (map['vertical'] ?? false) as bool,
      monospace: (map['monospace'] ?? false) as bool,
      fontSize: (map['fontSize'] is num)
          ? (map['fontSize'] as num).toDouble()
          : 16.0,
      weight: _fontWeightFromValue(map['weight']),
      color: _colorFromMapValue(map['color']) ?? Colors.white,
      align: _textAlignFromValue(map['align']),
    );
  }

  static Color? _colorFromMapValue(dynamic value) {
    if (value == null) return null;

    if (value is int) return Color(value);
    if (value is num) return Color(value.toInt());

    if (value is String) {
      final asInt = int.tryParse(value);
      if (asInt != null) return Color(asInt);
    }

    return null;
  }

  static FontWeight _fontWeightFromValue(dynamic v) {
    final value = v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');

    switch (value) {
      case 100:
        return FontWeight.w100;
      case 200:
        return FontWeight.w200;
      case 300:
        return FontWeight.w300;
      case 400:
        return FontWeight.w400;
      case 500:
        return FontWeight.w500;
      case 600:
        return FontWeight.w600;
      case 700:
        return FontWeight.w700;
      case 800:
        return FontWeight.w800;
      case 900:
        return FontWeight.w900;
      default:
        return FontWeight.w600;
    }
  }

  static TextAlign _textAlignFromValue(dynamic value) {
    if (value is String) {
      for (final item in TextAlign.values) {
        if (item.name == value) return item;
      }
    }

    if (value is int) {
      final safeIndex = value.clamp(0, TextAlign.values.length - 1);
      return TextAlign.values[safeIndex];
    }

    return TextAlign.start;
  }

  @override
  String toString() =>
      'TextItem(text="$text", pos=$position, area=$areaSize, vertical=$vertical, '
          'mono=$monospace, size=$fontSize, weight=$weight, color=$color, align=$align)';

  @override
  bool operator ==(Object other) {
    return other is TextItem &&
        other.position == position &&
        other.text == text &&
        other.areaSize == areaSize &&
        other.vertical == vertical &&
        other.monospace == monospace &&
        other.fontSize == fontSize &&
        other.weight == weight &&
        other.color == color &&
        other.align == align;
  }

  @override
  int get hashCode => Object.hash(
    position,
    text,
    areaSize,
    vertical,
    monospace,
    fontSize,
    weight,
    color,
    align,
  );
}