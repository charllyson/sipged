import 'package:flutter/material.dart';

class ServiceColors {
  // Paleta estável para serviços "desconhecidos"
  static const List<Color> _palette = <Color>[
    Color(0xFF42A5F5), // 0  PRELIMINARES — blue
    Color(0xFFE76F51), // 1  TERRAPLENAGEM — terra/laranja queimado
    Color(0xFF43A047), // 2  BASE / SUB-BASE — green
    Color(0xFF795548), // 3  PAVIMENTAÇÃO — brown
    Color(0xFF455A64), // 4  ASFALTO — slate (asfalto)
    Color(0xFFFFB300), // 5  SINALIZAÇÃO — amber
    Color(0xFF26A69A), // 6  COMPLEMENTARES — teal
    Color(0xFF00ACC1), // 7  DRENAGEM — cyan (água)
    Color(0xFF8E24AA), // 8  OBRAS ESPECIAIS — purple
    Color(0xFF8D6E63), // 9  RESERVA — brown (fallback)
  ];

  static String _norm(String s) => s.trim().toUpperCase();

  /// cor do botão para um serviço (dinâmico)
  static Color buttonColor(String rawKey) {
    final k = _norm(rawKey);
    if (k == 'GERAL') return Colors.black54;
    if (k.contains('PRELIMINAR')) return _palette[0];
    if (k.contains('TERRAPLEN')) return _palette[1];
    if (k.contains('BASE') || k.contains('SUB-BASE')) return _palette[2];
    if (k.contains('PAVIMENTA')) return _palette[3];
    if (k.contains('ASFALT')) return _palette[4];
    if (k.contains('SINALIZA')) return _palette[5];
    if (k.contains('COMPLEMENT')) return _palette[6];
    if (k.contains('DRENAGEM')) return _palette[7];
    if (k.contains('ESPECIA')) return _palette[8];


    // hash estável -> índice na paleta
    int hash = 0;
    for (final c in k.codeUnits) {
      hash = 0x1fffffff & (hash + c);
      hash = 0x1fffffff & (hash + ((hash & 0x0007ffff) << 10));
      hash ^= (hash >> 6);
    }
    hash = 0x1fffffff & (hash + ((hash & 0x03ffffff) << 3));
    hash ^= (hash >> 11);
    hash = 0x1fffffff & (hash + ((hash & 0x00003fff) << 15));
    return _palette[hash % _palette.length];
  }
}
