import 'package:cloud_firestore/cloud_firestore.dart';

class DotacaoSlice {
  final String label;   // ex: "Asfalto", "Terraplenagem"...
  final double amount;  // valor planejado dentro da dotação

  const DotacaoSlice({
    required this.label,
    required this.amount,
  });

  Map<String, dynamic> toMap() => {
    'label': label,
    'amount': amount,
  };

  factory DotacaoSlice.fromMap(Map<String, dynamic> map) {
    return DotacaoSlice(
      label: (map['label'] ?? '').toString(),
      amount: (map['amount'] ?? 0).toDouble(),
    );
  }
}

class DotacaoData {
  String? id;

  // Identificação LOA
  String orgao;     // ex: "DER/AL"
  String unidade;   // ex: "Unidade Gestora"
  String programa;  // ex: "Infraestrutura"
  String acao;      // ex: "Manutenção Rodoviária"
  String elemento;  // ex: "3.3.90.39"
  String fonte;     // ex: "500 - Recursos Ordinários"

  // Valores LOA
  double dotacaoInicial;
  double suplementacao;
  double anulacao;

  // Distribuição interna (planejamento)
  List<DotacaoSlice> slices;

  // Metadados
  DateTime? createdAt;
  String? createdBy;

  DotacaoData({
    this.id,
    required this.orgao,
    required this.unidade,
    required this.programa,
    required this.acao,
    required this.elemento,
    required this.fonte,
    required this.dotacaoInicial,
    this.suplementacao = 0.0,
    this.anulacao = 0.0,
    this.slices = const <DotacaoSlice>[],
    this.createdAt,
    this.createdBy,
  });

  double get dotacaoAtualizada => (dotacaoInicial + suplementacao - anulacao);

  String get labelResumo {
    final el = elemento.trim().isEmpty ? '-' : elemento.trim();
    return "$orgao • $unidade • $el • $fonte";
  }

  Map<String, dynamic> toMap() => {
    'orgao': orgao,
    'unidade': unidade,
    'programa': programa,
    'acao': acao,
    'elemento': elemento,
    'fonte': fonte,
    'dotacaoInicial': dotacaoInicial,
    'suplementacao': suplementacao,
    'anulacao': anulacao,
    'slices': slices.map((e) => e.toMap()).toList(),
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'createdBy': createdBy,
  };

  factory DotacaoData.fromDoc(DocumentSnapshot doc) {
    final map = (doc.data() as Map<String, dynamic>? ?? {});
    return DotacaoData(
      id: doc.id,
      orgao: (map['orgao'] ?? '').toString(),
      unidade: (map['unidade'] ?? '').toString(),
      programa: (map['programa'] ?? '').toString(),
      acao: (map['acao'] ?? '').toString(),
      elemento: (map['elemento'] ?? '').toString(),
      fonte: (map['fonte'] ?? '').toString(),
      dotacaoInicial: (map['dotacaoInicial'] ?? 0).toDouble(),
      suplementacao: (map['suplementacao'] ?? 0).toDouble(),
      anulacao: (map['anulacao'] ?? 0).toDouble(),
      slices: ((map['slices'] ?? []) as List)
          .whereType<Map>()
          .map((e) => DotacaoSlice.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      createdAt: (map['createdAt'] is Timestamp) ? (map['createdAt'] as Timestamp).toDate() : null,
      createdBy: (map['createdBy'] ?? '').toString().isEmpty ? null : (map['createdBy'] ?? '').toString(),
    );
  }
}
