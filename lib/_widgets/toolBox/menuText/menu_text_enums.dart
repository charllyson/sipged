// lib/_widgets/toolBox/menuText/text_overlay_painter.dart
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
/// - [vertical]: se `true`, representa texto vertical (você pode tratar na
///   renderização com rotação, se desejar).
/// - [monospace]: usa família monoespaçada.
/// - [fontSize], [weight], [color]: estilo básico.
/// - [align]: alinhamento do texto (aplicável quando houver múltiplas linhas).
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

  /// Se `true`, texto com orientação vertical (controle é do host).
  final bool vertical;

  /// Se `true`, usa fonte monoespaçada.
  final bool monospace;

  /// Tamanho da fonte.
  final double fontSize;

  /// Peso da fonte.
  final FontWeight weight;

  /// Cor do texto.
  final Color color;

  /// Alinhamento (útil para áreas com múltiplas linhas).
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

  // ---------- (opcionais) Serialização p/ persistência ----------

  Map<String, dynamic> toMap() => {
    'position': {'dx': position.dx, 'dy': position.dy},
    if (areaSize != null)
      'areaSize': {'w': areaSize!.width, 'h': areaSize!.height},
    'text': text,
    'vertical': vertical,
    'monospace': monospace,
    'fontSize': fontSize,
    'weight': weight.index, // usa índice do enum FontWeight
    'color': color.value,
    'align': align.index,
  };

  factory TextItem.fromMap(Map<String, dynamic> map) {
    final pos = map['position'] as Map<String, dynamic>;
    final area =
    map['areaSize'] == null ? null : map['areaSize'] as Map<String, dynamic>;
    return TextItem(
      position: Offset(
        (pos['dx'] as num).toDouble(),
        (pos['dy'] as num).toDouble(),
      ),
      text: (map['text'] ?? '') as String,
      areaSize: area == null
          ? null
          : Size(
        (area['w'] as num).toDouble(),
        (area['h'] as num).toDouble(),
      ),
      vertical: (map['vertical'] ?? false) as bool,
      monospace: (map['monospace'] ?? false) as bool,
      fontSize: (map['fontSize'] is num)
          ? (map['fontSize'] as num).toDouble()
          : 16.0,
      weight: _fontWeightFromIndex(map['weight'] as int?),
      color: Color((map['color'] ?? Colors.white.value) as int),
      align: _textAlignFromIndex(map['align'] as int?),
    );
  }

  static FontWeight _fontWeightFromIndex(int? i) {
    // Mapeamento simples: 0..8 -> w100..w900
    switch (i) {
      case 0:
        return FontWeight.w100;
      case 1:
        return FontWeight.w200;
      case 2:
        return FontWeight.w300;
      case 3:
        return FontWeight.w400;
      case 4:
        return FontWeight.w500;
      case 5:
        return FontWeight.w600;
      case 6:
        return FontWeight.w700;
      case 7:
        return FontWeight.w800;
      case 8:
        return FontWeight.w900;
      default:
        return FontWeight.w600;
    }
  }

  static TextAlign _textAlignFromIndex(int? i) {
    if (i == null) return TextAlign.start;
    return TextAlign.values[i.clamp(0, TextAlign.values.length - 1)];
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
