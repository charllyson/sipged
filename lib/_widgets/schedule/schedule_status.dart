// lib/_datas/sectors/operation/schedule/schedule_status.dart
import 'package:flutter/material.dart';

enum ScheduleStatus { concluido, emAndamento, aIniciar }

extension ScheduleStatusX on ScheduleStatus {
  String get key {
    switch (this) {
      case ScheduleStatus.concluido:   return 'concluido';
      case ScheduleStatus.emAndamento: return 'em andamento';
      case ScheduleStatus.aIniciar:    return 'a iniciar';
    }
  }

  String get label {
    switch (this) {
      case ScheduleStatus.concluido:   return 'Concluído';
      case ScheduleStatus.emAndamento: return 'Em andamento';
      case ScheduleStatus.aIniciar:    return 'A iniciar';
    }
  }

  IconData get icon {
    switch (this) {
      case ScheduleStatus.concluido:   return Icons.check_circle;
      case ScheduleStatus.emAndamento: return Icons.build_circle_rounded;
      case ScheduleStatus.aIniciar:    return Icons.pan_tool_alt_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ScheduleStatus.concluido:   return Colors.green;
      case ScheduleStatus.emAndamento: return Colors.orange;
      case ScheduleStatus.aIniciar:    return Colors.grey;
    }
  }

  // -------- parsing --------
  static ScheduleStatus fromString(String? raw) {
    final s = _normalize(raw);
    if (s == 'concluido')     return ScheduleStatus.concluido;
    if (s == 'em andamento')  return ScheduleStatus.emAndamento;
    return ScheduleStatus.aIniciar;
  }

  static String _normalize(String? v) {
    var s = (v ?? '').trim().toLowerCase();
    s = s
        .replaceAll('á','a').replaceAll('à','a').replaceAll('â','a').replaceAll('ã','a')
        .replaceAll('é','e').replaceAll('ê','e')
        .replaceAll('í','i')
        .replaceAll('ó','o').replaceAll('ô','o').replaceAll('õ','o')
        .replaceAll('ú','u').replaceAll('ç','c');
    return s;
  }

  // também aceita dynamic (string, null, etc.)
  static ScheduleStatus fromAny(dynamic v) {
    if (v is String) return fromString(v);
    return ScheduleStatus.aIniciar;
  }
}
