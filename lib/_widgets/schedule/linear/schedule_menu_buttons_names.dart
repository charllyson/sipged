import 'package:flutter/material.dart';

import 'package:siged/_blocs/sectors/operation/road/schedule_road_style.dart';

class ScheduleMenuButtonsNames {
  final String key;        // ex.: "terraplenagem"
  final String label;      // rótulo original do orçamento (com acentos)
  final String collection; // ex.: schedules_terraplenagem
  final Color color;       // cor semântica (ex.: ASFALTO → paleta asfalto)
  final IconData icon;     // ícone semântico (ex.: ASFALTO → carro)

  const ScheduleMenuButtonsNames({
    required this.key,
    required this.label,
    required this.collection,
    required this.color,
    required this.icon,
  });

  ScheduleMenuButtonsNames copyWith({
    String? key,
    String? label,
    String? collection,
    Color? color,
    IconData? icon,
  }) {
    return ScheduleMenuButtonsNames(
      key: key ?? this.key,
      label: label ?? this.label,
      collection: collection ?? this.collection,
      color: color ?? this.color,
      icon: icon ?? this.icon,
    );
  }
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
  // remove underscores duplicados/iniciais/finais
  final once = cleaned.replaceAll(RegExp(r'_+'), '_');
  return once.replaceAll(RegExp(r'^_+|_+$'), '');
}

/// Cria a opção diretamente do título do orçamento (⚠️ usa paleta semântica!)
ScheduleMenuButtonsNames optionFromTitle(String title) {
  final slug = slugFromTitle(title);
  final label = title.trim().isEmpty ? slug : title.trim();
  return ScheduleMenuButtonsNames(
    key: slug,
    label: label,
    collection: 'schedules_$slug',
    color: ScheduleRoadStyle.colorForService(label),  // 🎯 semântico por label
    icon: ScheduleRoadStyle.pickIconForTitle(label),  // 🎯 ícone semântico
  );
}

/// Opção fixa "GERAL"
ScheduleMenuButtonsNames geralOption() => const ScheduleMenuButtonsNames(
  key: 'geral',
  label: 'GERAL',
  collection: '', // não usado no GERAL
  color: Color(0xFF1B2031),
  icon: Icons.clear_all,
);
