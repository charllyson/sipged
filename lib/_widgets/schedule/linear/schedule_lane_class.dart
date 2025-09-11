import 'package:flutter/material.dart';

class ScheduleLaneClass {
  final String pos;      // LE, CE, LD, ...
  final String nome;     // PISTA ATUAL, CANTEIRO, DUPLICAÇÃO...
  final double altura;
  /// Slot/âncora: -1=LE atual, 0=Central, +1=LD atual, null = sem âncora
  final int? anchor;

  /// Permissões por serviço nesta faixa. Ex.: {'asfalto': true, 'base-sub-base': false}
  final Map<String, bool> allowedByService;

  const ScheduleLaneClass({
    required this.pos,
    required this.nome,
    required this.altura,
    this.anchor,
    this.allowedByService = const <String, bool>{},
  });

  String get label => pos.isEmpty ? nome : '$pos - $nome';

  /// Se não houver chave, considera permitido (compatibilidade retro).
  bool isAllowed(String serviceKey) {
    final v = allowedByService[serviceKey.toLowerCase()];
    return v ?? true;
  }

  ScheduleLaneClass copyWith({
    String? pos,
    String? nome,
    double? altura,
    int? anchor,
    Map<String, bool>? allowedByService,
  }) {
    return ScheduleLaneClass(
      pos: pos ?? this.pos,
      nome: nome ?? this.nome,
      altura: altura ?? this.altura,
      anchor: anchor ?? this.anchor,
      allowedByService: allowedByService ?? this.allowedByService,
    );
  }
}
