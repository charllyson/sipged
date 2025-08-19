class ScheduleLaneClass {
  final String pos;      // LE, CE, LD, ...
  final String nome;     // PISTA ATUAL, CANTEIRO, DUPLICAÇÃO...
  final double altura;
  /// Slot/âncora: -1=LE atual, 0=Central, +1=LD atual, null = sem âncora
  final int? anchor;

  const ScheduleLaneClass({
    required this.pos,
    required this.nome,
    required this.altura,
    this.anchor,
  });

  String get label => pos.isEmpty ? nome : '$pos - $nome';

  ScheduleLaneClass copyWith({
    String? pos, String? nome, double? altura, int? anchor,
  }) => ScheduleLaneClass(
    pos: pos ?? this.pos,
    nome: nome ?? this.nome,
    altura: altura ?? this.altura,
    anchor: anchor ?? this.anchor,
  );
}
