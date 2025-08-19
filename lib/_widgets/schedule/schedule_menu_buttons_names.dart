import 'package:flutter/material.dart';

import '../../_datas/sectors/operation/schedule/schedule_style.dart';

class ScheduleMenuButtonsNames {
  final String key;        // ex.: "terraplenagem"
  final String label;      // rótulo original do orçamento (com acentos)
  final String collection; // ex.: schedules_terraplenagem
  final Color color;       // cor estável a partir do slug
  final IconData icon;     // ícone padrão (ou vindo de config)

  const ScheduleMenuButtonsNames({
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


/// Cria a opção diretamente do título do orçamento
ScheduleMenuButtonsNames optionFromTitle(String title) {
  final slug = slugFromTitle(title);
  return ScheduleMenuButtonsNames(
    key: slug,
    label: title.trim().isEmpty ? slug : title.trim(),
    collection: 'schedules_$slug',
    color: ScheduleStyle.colorFromSlug(slug),
    icon: ScheduleStyle.iconFromSlug(slug),
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
