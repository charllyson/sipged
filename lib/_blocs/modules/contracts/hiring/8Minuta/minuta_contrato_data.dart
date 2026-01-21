import 'package:equatable/equatable.dart';
import 'minuta_contrato_sections.dart';

class MinutaContratoData extends Equatable {
  // 1) Identificação
  final String? numero;
  final String? versao;
  final String? dataElaboracao;

  // 2) Partes / Objeto
  final String? contratante;
  final String? contratadaRazao;
  final String? contratadaCnpj;
  final String? objetoResumo;

  // 3) Valor
  final String? valorGlobal;

  // 4) Gestão / Referências
  final String? gestorUserId;
  final String? gestorNome;
  final String? fiscalUserId;
  final String? fiscalNome;
  final String? linksAnexos;
  final String? regimeExecucaoRef;
  final String? prazosRef;

  const MinutaContratoData({
    this.numero,
    this.versao,
    this.dataElaboracao,
    this.contratante,
    this.contratadaRazao,
    this.contratadaCnpj,
    this.objetoResumo,
    this.valorGlobal,
    this.gestorUserId,
    this.gestorNome,
    this.fiscalUserId,
    this.fiscalNome,
    this.linksAnexos,
    this.regimeExecucaoRef,
    this.prazosRef,
  });

  /// Construtor "vazio" no mesmo padrão dos outros Data
  const MinutaContratoData.empty()
      : numero = '',
        versao = '',
        dataElaboracao = '',
        contratante = '',
        contratadaRazao = '',
        contratadaCnpj = '',
        objetoResumo = '',
        valorGlobal = '',
        gestorUserId = null,
        gestorNome = '',
        fiscalUserId = null,
        fiscalNome = '',
        linksAnexos = '',
        regimeExecucaoRef = '',
        prazosRef = '';

  // ---------------------------------------------------------------------------
  // Map "flat" — compatível com doc único no Firestore
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    'numero': numero,
    'versao': versao,
    'dataElaboracao': dataElaboracao,
    'contratante': contratante,
    'contratadaRazao': contratadaRazao,
    'contratadaCnpj': contratadaCnpj,
    'objetoResumo': objetoResumo,
    'valorGlobal': valorGlobal,
    'gestorUserId': gestorUserId,
    'gestorNome': gestorNome,
    'fiscalUserId': fiscalUserId,
    'fiscalNome': fiscalNome,
    'linksAnexos': linksAnexos,
    'regimeExecucaoRef': regimeExecucaoRef,
    'prazosRef': prazosRef,
  };

  factory MinutaContratoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MinutaContratoData.empty();

    return MinutaContratoData(
      numero: (map['numero'] ?? '').toString(),
      versao: (map['versao'] ?? '').toString(),
      dataElaboracao: (map['dataElaboracao'] ?? '').toString(),
      contratante: (map['contratante'] ?? '').toString(),
      contratadaRazao: (map['contratadaRazao'] ?? '').toString(),
      contratadaCnpj: (map['contratadaCnpj'] ?? '').toString(),
      objetoResumo: (map['objetoResumo'] ?? '').toString(),
      valorGlobal: (map['valorGlobal'] ?? '').toString(),
      gestorUserId: map['gestorUserId']?.toString(),
      gestorNome: (map['gestorNome'] ?? '').toString(),
      fiscalUserId: map['fiscalUserId']?.toString(),
      fiscalNome: (map['fiscalNome'] ?? '').toString(),
      linksAnexos: (map['linksAnexos'] ?? '').toString(),
      regimeExecucaoRef: (map['regimeExecucaoRef'] ?? '').toString(),
      prazosRef: (map['prazosRef'] ?? '').toString(),
    );
  }

  /// A partir da estrutura em seções usada no Firestore
  factory MinutaContratoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final id  = sections[MinutaSections.identificacao]
        ?? const <String, dynamic>{};
    final po  = sections[MinutaSections.partesObjeto]
        ?? const <String, dynamic>{};
    final val = sections[MinutaSections.valor]
        ?? const <String, dynamic>{};
    final gr  = sections[MinutaSections.gestaoRefs]
        ?? const <String, dynamic>{};

    return MinutaContratoData(
      // 1) Identificação
      numero: (id['numero'] ?? '').toString(),
      versao: (id['versao'] ?? '').toString(),
      dataElaboracao: (id['dataElaboracao'] ?? '').toString(),

      // 2) Partes / Objeto
      contratante: (po['contratante'] ?? '').toString(),
      contratadaRazao: (po['contratadaRazao'] ?? '').toString(),
      contratadaCnpj: (po['contratadaCnpj'] ?? '').toString(),
      objetoResumo: (po['objetoResumo'] ?? '').toString(),

      // 3) Valor
      valorGlobal: (val['valorGlobal'] ?? '').toString(),

      // 4) Gestão / Referências
      gestorUserId: gr['gestorUserId']?.toString(),
      gestorNome: (gr['gestorNome'] ?? '').toString(),
      fiscalUserId: gr['fiscalUserId']?.toString(),
      fiscalNome: (gr['fiscalNome'] ?? '').toString(),
      linksAnexos: (gr['linksAnexos'] ?? '').toString(),
      regimeExecucaoRef: (gr['regimeExecucaoRef'] ?? '').toString(),
      prazosRef: (gr['prazosRef'] ?? '').toString(),
    );
  }

  MinutaContratoData copyWith({
    String? numero,
    String? versao,
    String? dataElaboracao,
    String? contratante,
    String? contratadaRazao,
    String? contratadaCnpj,
    String? objetoResumo,
    String? valorGlobal,
    String? gestorUserId,
    String? gestorNome,
    String? fiscalUserId,
    String? fiscalNome,
    String? linksAnexos,
    String? regimeExecucaoRef,
    String? prazosRef,
  }) {
    return MinutaContratoData(
      numero: numero ?? this.numero,
      versao: versao ?? this.versao,
      dataElaboracao: dataElaboracao ?? this.dataElaboracao,
      contratante: contratante ?? this.contratante,
      contratadaRazao: contratadaRazao ?? this.contratadaRazao,
      contratadaCnpj: contratadaCnpj ?? this.contratadaCnpj,
      objetoResumo: objetoResumo ?? this.objetoResumo,
      valorGlobal: valorGlobal ?? this.valorGlobal,
      gestorUserId: gestorUserId ?? this.gestorUserId,
      gestorNome: gestorNome ?? this.gestorNome,
      fiscalUserId: fiscalUserId ?? this.fiscalUserId,
      fiscalNome: fiscalNome ?? this.fiscalNome,
      linksAnexos: linksAnexos ?? this.linksAnexos,
      regimeExecucaoRef: regimeExecucaoRef ?? this.regimeExecucaoRef,
      prazosRef: prazosRef ?? this.prazosRef,
    );
  }

  @override
  List<Object?> get props => [
    numero,
    versao,
    dataElaboracao,
    contratante,
    contratadaRazao,
    contratadaCnpj,
    objetoResumo,
    valorGlobal,
    gestorUserId,
    gestorNome,
    fiscalUserId,
    fiscalNome,
    linksAnexos,
    regimeExecucaoRef,
    prazosRef,
  ];
}

// -----------------------------------------------------------------------------
// Mapeamento para estrutura em seções (Firestore)
// -----------------------------------------------------------------------------
extension MinutaContratoDataSections on MinutaContratoData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      MinutaSections.identificacao: {
        'numero': numero,
        'versao': versao,
        'dataElaboracao': dataElaboracao,
      },
      MinutaSections.partesObjeto: {
        'contratante': contratante,
        'contratadaRazao': contratadaRazao,
        'contratadaCnpj': contratadaCnpj,
        'objetoResumo': objetoResumo,
      },
      MinutaSections.valor: {
        'valorGlobal': valorGlobal,
      },
      MinutaSections.gestaoRefs: {
        'gestorUserId': gestorUserId,
        'gestorNome': gestorNome,
        'fiscalUserId': fiscalUserId,
        'fiscalNome': fiscalNome,
        'linksAnexos': linksAnexos,
        'regimeExecucaoRef': regimeExecucaoRef,
        'prazosRef': prazosRef,
      },
    };
  }
}
