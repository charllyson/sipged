import 'dart:math' as math;
import 'package:flutter/material.dart';

class ServiceOption {
  final String key;        // ex.: "terraplenagem"
  final String label;      // rótulo original do orçamento (com acentos)
  final String collection; // ex.: schedules_terraplenagem
  final Color color;       // cor estável a partir do slug
  final IconData icon;     // ícone padrão (ou vindo de config)

  const ServiceOption({
    required this.key,
    required this.label,
    required this.collection,
    required this.color,
    required this.icon,
  });
}

/// Remove acentos (PT-BR) e normaliza
String _removeDiacritics(String s) {
  const from = 'ÀÁÂÃÄÅàáâãäåÈÉÊËèéêëÌÍÎÏìíîïÒÓÔÕÖòóôõöÙÚÛÜùúûüÇçÑñÝýÿ';
  const to   = 'AAAAAAaaaaaaEEEEeeeeIIIIiiiiOOOOOoooooUUUUuuuuCcNnYyy';
  final map = { for (var i = 0; i < from.length; i++) from[i]: to[i] };
  return s.split('').map((c) => map[c] ?? c).join();
}

/// slug -> minúsculo, sem acentos, [a-z0-9_]
String slugFromTitle(String title) {
  final noAccents = _removeDiacritics(title);
  final lower = noAccents.toLowerCase();
  final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  return cleaned.replaceAll(RegExp(r'^_+|_+$'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Cor estável a partir do slug (hash -> hue)
Color colorFromSlug(String slug, {double s = 0.55, double v = 0.85}) {
  int hash = 0;
  for (var i = 0; i < slug.length; i++) {
    hash = 31 * hash + slug.codeUnitAt(i);
  }
  final hue = (hash % 360).toDouble();
  return HSVColor.fromAHSV(1.0, hue, s, v).toColor();
}

/// Ícone padrão (pode vir de config depois)
IconData iconFromSlug(String slug) => Icons.layers_outlined;

/// Cria a opção diretamente do título do orçamento
ServiceOption optionFromTitle(String title) {
  final slug = slugFromTitle(title);
  return ServiceOption(
    key: slug,
    label: title.trim().isEmpty ? slug : title.trim(),
    collection: 'schedules_$slug',
    color: colorFromSlug(slug),
    icon: iconFromSlug(slug),
  );
}

/// Opção fixa "GERAL"
ServiceOption geralOption() => const ServiceOption(
  key: 'geral',
  label: 'GERAL',
  collection: '', // não usado no GERAL
  color: Color(0xFF1B2031),
  icon: Icons.clear_all,
);
