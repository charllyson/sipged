import 'package:flutter/material.dart';

enum ScheduleStatus { concluido, emAndamento, aIniciar }

extension ScheduleStatusX on ScheduleStatus {
  String get key {
    switch (this) {
      case ScheduleStatus.concluido:
        return 'concluido';

      case ScheduleStatus.emAndamento:
        return 'em_andamento';

      case ScheduleStatus.aIniciar:
        return 'a_iniciar';
    }
  }

  String get label {
    switch (this) {
      case ScheduleStatus.concluido:
        return 'Concluído';

      case ScheduleStatus.emAndamento:
        return 'Em andamento';

      case ScheduleStatus.aIniciar:
        return 'A iniciar';
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleStatus.concluido:
        return Icons.check_circle;

      case ScheduleStatus.emAndamento:
        return Icons.build_circle_rounded;

      case ScheduleStatus.aIniciar:
        return Icons.pan_tool_alt_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ScheduleStatus.concluido:
        return Colors.green;

      case ScheduleStatus.emAndamento:
        return Colors.orange;

      case ScheduleStatus.aIniciar:
        return Colors.grey;
    }
  }

  static ScheduleStatus fromString(String? raw) {
    final value = _normalize(raw);

    if (value == 'concluido') {
      return ScheduleStatus.concluido;
    }

    if (value == 'em_andamento') {
      return ScheduleStatus.emAndamento;
    }

    if (value == 'a_iniciar') {
      return ScheduleStatus.aIniciar;
    }

    return ScheduleStatus.aIniciar;
  }

  static ScheduleStatus fromAny(dynamic value) {
    if (value is ScheduleStatus) {
      return value;
    }

    if (value is String) {
      return fromString(value);
    }

    return ScheduleStatus.aIniciar;
  }

  static String _normalize(String? value) {
    var text = (value ?? '').trim().toLowerCase();

    if (text.isEmpty) {
      return '';
    }

    text = text
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ç', 'c');

    text = text.replaceAll('-', '_');
    text = text.replaceAll(RegExp(r'\s+'), '_');
    text = text.replaceAll(RegExp(r'_+'), '_');

    if (text == 'emandamento') {
      return 'em_andamento';
    }

    if (text == 'ainiciar') {
      return 'a_iniciar';
    }

    return text;
  }
}