import 'package:flutter/material.dart';

class ScheduleRoadStyle {
  static Color colorFromSlug(String slug, {double s = 0.55, double v = 0.85}) {
    int hash = 0;
    for (var i = 0; i < slug.length; i++) {
      hash = 31 * hash + slug.codeUnitAt(i);
    }
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1.0, hue, s, v).toColor();
  }

  static IconData iconFromSlug(String slug) => Icons.layers_outlined;

  static const List<Color> _palette = <Color>[
    Color(0xFF42A5F5),
    Color(0xFFE76F51),
    Color(0xFF43A047),
    Color(0xFF795548),
    Color(0xFF455A64),
    Color(0xFFFFB300),
    Color(0xFF26A69A),
    Color(0xFF00ACC1),
    Color(0xFF8E24AA),
    Color(0xFF8D6E63),
  ];

  static String _strip(String s) => s
      .trim()
      .toUpperCase()
      .replaceAll('Á', 'A')
      .replaceAll('À', 'A')
      .replaceAll('Â', 'A')
      .replaceAll('Ã', 'A')
      .replaceAll('É', 'E')
      .replaceAll('Ê', 'E')
      .replaceAll('Í', 'I')
      .replaceAll('Ó', 'O')
      .replaceAll('Ô', 'O')
      .replaceAll('Õ', 'O')
      .replaceAll('Ú', 'U')
      .replaceAll('Ç', 'C')
      .replaceAll('|', ' ')
      .replaceAll('/', ' ')
      .replaceAll('-', ' ');

  static Color colorForService(String raw) {
    final k = _strip(raw);
    if (k == 'GERAL') return Colors.black54;

    bool has(String token) => k.contains(token);

    if (has('PRELIMINAR') || has('PRELIMINARES')) return _palette[0];
    if (has('TERRAPLEN')) return _palette[1];
    if (has('BASE') || has('SUB BASE') || has('SUBBASE')) return _palette[2];
    if (has('PAVIMENTA')) return _palette[3];
    if (has('ASFALT') || has('CBUQ')) return _palette[4];
    if (has('SINALIZA')) return _palette[5];
    if (has('COMPLEMENT')) return _palette[6];
    if (has('DRENAGEM') || has('DRENAGE')) return _palette[7];
    if (has('OBRAS ESPECIAIS') || has('ESPECIA')) return _palette[8];

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

  static Color colorForFaixa(String raw) {
    final t = raw.trim().toUpperCase();

    bool any(List<String> ks) => ks.any(t.contains);

    if (any(const ['CENTRAL', 'CANTEIRO', 'CC', 'CE'])) {
      return Colors.amber.shade600;
    }
    if (any(const ['DUPLICA', 'AMPLIA', 'ADICIONAL', 'NOVA', 'NOVAS'])) {
      return Colors.grey.shade800;
    }
    if (any(const ['ATUAL', 'EXISTENTE'])) {
      return Colors.grey.shade600;
    }
    if (any(const ['ACOST', 'ACOSTAMENTO'])) {
      return Colors.grey.shade400;
    }
    if (any(const ['CICLOVIA', 'BICIC', 'CICL'])) {
      return Colors.green.shade600;
    }
    if (any(const ['PASSEIO', 'CALÇADA'])) {
      return Colors.blue.shade600;
    }
    if (any(const ['RETORNO', 'ALÇA', 'ALCA', 'ACESSO'])) {
      return Colors.purple.shade600;
    }

    return Colors.grey.shade500;
  }

  static IconData pickIconForTitle(String title) {
    final t = title.toUpperCase();
    if (t.contains('SINALIZA')) return Icons.signal_cellular_alt;
    if (t.contains('ESPECIA')) return Icons.car_repair;
    if (t.contains('ASFALT') || t.contains('PAVIMENTA')) {
      return Icons.directions_car;
    }
    if (t.contains('BASE')) return Icons.recycling;
    if (t.contains('TERRAPLEN')) return Icons.terrain;
    if (t.contains('COMPLEMENTAR')) return Icons.add_road;
    if (t.contains('DRENAGE') || t.contains('DRENAGEM')) {
      return Icons.water_drop;
    }
    if (t.contains('PRELIMIN')) {
      return Icons.broadcast_on_personal_outlined;
    }
    return Icons.layers_outlined;
  }
}