// lib/_blocs/modules/contracts/hiring/8Minuta/minuta_contrato_data.dart

import 'package:equatable/equatable.dart';

class MinutaContratoData extends Equatable {
  /// Chaves estáveis das seções da Minuta.
  /// Substitui o antigo arquivo minuta_contrato_sections.dart.
  static const sectionIdentificacao = 'identificacao';
  static const sectionPartesObjeto = 'partes_objeto';
  static const sectionValor = 'valor';
  static const sectionGestaoRefs = 'gestao_refs';

  static const sectionKeys = <String>[
    sectionIdentificacao,
    sectionPartesObjeto,
    sectionValor,
    sectionGestaoRefs,
  ];

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

  static String _text(dynamic value) {
    return (value ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
  }

  factory MinutaContratoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const MinutaContratoData.empty();

    return MinutaContratoData(
      numero: _text(map['numero']),
      versao: _text(map['versao']),
      dataElaboracao: _text(map['dataElaboracao']),
      contratante: _text(map['contratante']),
      contratadaRazao: _text(map['contratadaRazao']),
      contratadaCnpj: _text(map['contratadaCnpj']),
      objetoResumo: _text(map['objetoResumo']),
      valorGlobal: _text(map['valorGlobal']),
      gestorUserId: map['gestorUserId']?.toString(),
      gestorNome: _text(map['gestorNome']),
      fiscalUserId: map['fiscalUserId']?.toString(),
      fiscalNome: _text(map['fiscalNome']),
      linksAnexos: _text(map['linksAnexos']),
      regimeExecucaoRef: _text(map['regimeExecucaoRef']),
      prazosRef: _text(map['prazosRef']),
    );
  }

  factory MinutaContratoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final id = sections[sectionIdentificacao] ?? const <String, dynamic>{};
    final po = sections[sectionPartesObjeto] ?? const <String, dynamic>{};
    final val = sections[sectionValor] ?? const <String, dynamic>{};
    final gr = sections[sectionGestaoRefs] ?? const <String, dynamic>{};

    return MinutaContratoData(
      numero: _text(id['numero']),
      versao: _text(id['versao']),
      dataElaboracao: _text(id['dataElaboracao']),
      contratante: _text(po['contratante']),
      contratadaRazao: _text(po['contratadaRazao']),
      contratadaCnpj: _text(po['contratadaCnpj']),
      objetoResumo: _text(po['objetoResumo']),
      valorGlobal: _text(val['valorGlobal']),
      gestorUserId: gr['gestorUserId']?.toString(),
      gestorNome: _text(gr['gestorNome']),
      fiscalUserId: gr['fiscalUserId']?.toString(),
      fiscalNome: _text(gr['fiscalNome']),
      linksAnexos: _text(gr['linksAnexos']),
      regimeExecucaoRef: _text(gr['regimeExecucaoRef']),
      prazosRef: _text(gr['prazosRef']),
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

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionIdentificacao: <String, dynamic>{
        'numero': numero,
        'versao': versao,
        'dataElaboracao': dataElaboracao,
      },
      sectionPartesObjeto: <String, dynamic>{
        'contratante': contratante,
        'contratadaRazao': contratadaRazao,
        'contratadaCnpj': contratadaCnpj,
        'objetoResumo': objetoResumo,
      },
      sectionValor: <String, dynamic>{
        'valorGlobal': valorGlobal,
      },
      sectionGestaoRefs: <String, dynamic>{
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

  @override
  List<Object?> get props => <Object?>[
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