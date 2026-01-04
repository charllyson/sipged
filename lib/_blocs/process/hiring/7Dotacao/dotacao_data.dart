import 'package:equatable/equatable.dart';

import 'dotacao_sections.dart';

class DotacaoData extends Equatable {
  // 1) Identificação
  final String? exercicio;
  final String? processoSei;
  final String? responsavelOrcUserId;
  final String? responsavelOrcNome;

  // 2) Vinculação Programática
  final String? uo;
  final String? ug;
  final String? programa;
  final String? acao;
  final String? ptres;
  final String? planoOrc;
  final String? fonteRecurso;

  // 3) Natureza da Despesa
  final String? modalidadeAplicacao;
  final String? elementoDespesa;
  final String? subelemento;
  final String? descricaoNd;

  // 4) Reserva
  final String? reservaNumero;
  final String? reservaData;
  final String? reservaValor;
  final String? reservaObservacoes;

  // 5) Empenho
  final String? empenhoModalidade;
  final String? empenhoNumero;
  final String? empenhoData;
  final String? empenhoValor;

  // 6) Cronograma de Desembolso
  final String? desembolsoPeriodicidade;
  final String? desembolsoMeses;
  final String? desembolsoObservacoes;

  // 7) Documentos / Links
  final String? links;

  const DotacaoData({
    this.exercicio,
    this.processoSei,
    this.responsavelOrcUserId,
    this.responsavelOrcNome,
    this.uo,
    this.ug,
    this.programa,
    this.acao,
    this.ptres,
    this.planoOrc,
    this.fonteRecurso,
    this.modalidadeAplicacao,
    this.elementoDespesa,
    this.subelemento,
    this.descricaoNd,
    this.reservaNumero,
    this.reservaData,
    this.reservaValor,
    this.reservaObservacoes,
    this.empenhoModalidade,
    this.empenhoNumero,
    this.empenhoData,
    this.empenhoValor,
    this.desembolsoPeriodicidade,
    this.desembolsoMeses,
    this.desembolsoObservacoes,
    this.links,
  });

  /// Construtor "vazio" no mesmo padrão dos outros Data
  const DotacaoData.empty()
      : exercicio = '',
        processoSei = '',
        responsavelOrcUserId = null,
        responsavelOrcNome = '',
        uo = '',
        ug = '',
        programa = '',
        acao = '',
        ptres = '',
        planoOrc = '',
        fonteRecurso = '',
        modalidadeAplicacao = '',
        elementoDespesa = '',
        subelemento = '',
        descricaoNd = '',
        reservaNumero = '',
        reservaData = '',
        reservaValor = '',
        reservaObservacoes = '',
        empenhoModalidade = '',
        empenhoNumero = '',
        empenhoData = '',
        empenhoValor = '',
        desembolsoPeriodicidade = '',
        desembolsoMeses = '',
        desembolsoObservacoes = '',
        links = '';

  // ---------------------------------------------------------------------------
  // Map "flat" — compatível com doc único no Firestore
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    'exercicio': exercicio,
    'processoSei': processoSei,
    'responsavelOrcUserId': responsavelOrcUserId,
    'responsavelOrcNome': responsavelOrcNome,
    'uo': uo,
    'ug': ug,
    'programa': programa,
    'acao': acao,
    'ptres': ptres,
    'planoOrc': planoOrc,
    'fonteRecurso': fonteRecurso,
    'modalidadeAplicacao': modalidadeAplicacao,
    'elementoDespesa': elementoDespesa,
    'subelemento': subelemento,
    'descricaoNd': descricaoNd,
    'reservaNumero': reservaNumero,
    'reservaData': reservaData,
    'reservaValor': reservaValor,
    'reservaObservacoes': reservaObservacoes,
    'empenhoModalidade': empenhoModalidade,
    'empenhoNumero': empenhoNumero,
    'empenhoData': empenhoData,
    'empenhoValor': empenhoValor,
    'desembolsoPeriodicidade': desembolsoPeriodicidade,
    'desembolsoMeses': desembolsoMeses,
    'desembolsoObservacoes': desembolsoObservacoes,
    'links': links,
  };

  factory DotacaoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DotacaoData.empty();

    return DotacaoData(
      exercicio: (map['exercicio'] ?? '').toString(),
      processoSei: (map['processoSei'] ?? '').toString(),
      responsavelOrcUserId: map['responsavelOrcUserId']?.toString(),
      responsavelOrcNome: (map['responsavelOrcNome'] ?? '').toString(),
      uo: (map['uo'] ?? '').toString(),
      ug: (map['ug'] ?? '').toString(),
      programa: (map['programa'] ?? '').toString(),
      acao: (map['acao'] ?? '').toString(),
      ptres: (map['ptres'] ?? '').toString(),
      planoOrc: (map['planoOrc'] ?? '').toString(),
      fonteRecurso: (map['fonteRecurso'] ?? '').toString(),
      modalidadeAplicacao: (map['modalidadeAplicacao'] ?? '').toString(),
      elementoDespesa: (map['elementoDespesa'] ?? '').toString(),
      subelemento: (map['subelemento'] ?? '').toString(),
      descricaoNd: (map['descricaoNd'] ?? '').toString(),
      reservaNumero: (map['reservaNumero'] ?? '').toString(),
      reservaData: (map['reservaData'] ?? '').toString(),
      reservaValor: (map['reservaValor'] ?? '').toString(),
      reservaObservacoes: (map['reservaObservacoes'] ?? '').toString(),
      empenhoModalidade: (map['empenhoModalidade'] ?? '').toString(),
      empenhoNumero: (map['empenhoNumero'] ?? '').toString(),
      empenhoData: (map['empenhoData'] ?? '').toString(),
      empenhoValor: (map['empenhoValor'] ?? '').toString(),
      desembolsoPeriodicidade:
      (map['desembolsoPeriodicidade'] ?? '').toString(),
      desembolsoMeses: (map['desembolsoMeses'] ?? '').toString(),
      desembolsoObservacoes:
      (map['desembolsoObservacoes'] ?? '').toString(),
      links: (map['links'] ?? '').toString(),
    );
  }

  /// A partir da estrutura em seções usada no Firestore
  factory DotacaoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final i  = sections[DotacaoSections.identificacao]
        ?? const <String, dynamic>{};
    final v  = sections[DotacaoSections.vinculacaoProgramatica]
        ?? const <String, dynamic>{};
    final n  = sections[DotacaoSections.naturezaDespesa]
        ?? const <String, dynamic>{};
    final r  = sections[DotacaoSections.reserva]
        ?? const <String, dynamic>{};
    final e  = sections[DotacaoSections.empenho]
        ?? const <String, dynamic>{};
    final c  = sections[DotacaoSections.cronograma]
        ?? const <String, dynamic>{};
    final d  = sections[DotacaoSections.documentos]
        ?? const <String, dynamic>{};

    return DotacaoData(
      // 1) Identificação
      exercicio: (i['exercicio'] ?? '').toString(),
      processoSei: (i['processoSei'] ?? '').toString(),
      responsavelOrcUserId: i['responsavelOrcUserId']?.toString(),
      responsavelOrcNome: (i['responsavelOrcNome'] ?? '').toString(),

      // 2) Vinculação Programática
      uo: (v['uo'] ?? '').toString(),
      ug: (v['ug'] ?? '').toString(),
      programa: (v['programa'] ?? '').toString(),
      acao: (v['acao'] ?? '').toString(),
      ptres: (v['ptres'] ?? '').toString(),
      planoOrc: (v['planoOrc'] ?? '').toString(),
      fonteRecurso: (v['fonteRecurso'] ?? '').toString(),

      // 3) Natureza da Despesa
      modalidadeAplicacao:
      (n['modalidadeAplicacao'] ?? '').toString(),
      elementoDespesa:
      (n['elementoDespesa'] ?? '').toString(),
      subelemento: (n['subelemento'] ?? '').toString(),
      descricaoNd: (n['descricaoNd'] ?? '').toString(),

      // 4) Reserva
      reservaNumero:
      (r['reservaNumero'] ?? '').toString(),
      reservaData:
      (r['reservaData'] ?? '').toString(),
      reservaValor:
      (r['reservaValor'] ?? '').toString(),
      reservaObservacoes:
      (r['reservaObservacoes'] ?? '').toString(),

      // 5) Empenho
      empenhoModalidade:
      (e['empenhoModalidade'] ?? '').toString(),
      empenhoNumero:
      (e['empenhoNumero'] ?? '').toString(),
      empenhoData:
      (e['empenhoData'] ?? '').toString(),
      empenhoValor:
      (e['empenhoValor'] ?? '').toString(),

      // 6) Cronograma
      desembolsoPeriodicidade:
      (c['desembolsoPeriodicidade'] ?? '').toString(),
      desembolsoMeses:
      (c['desembolsoMeses'] ?? '').toString(),
      desembolsoObservacoes:
      (c['desembolsoObservacoes'] ?? '').toString(),

      // 7) Documentos
      links: (d['links'] ?? '').toString(),
    );
  }

  DotacaoData copyWith({
    String? exercicio,
    String? processoSei,
    String? responsavelOrcUserId,
    String? responsavelOrcNome,
    String? uo,
    String? ug,
    String? programa,
    String? acao,
    String? ptres,
    String? planoOrc,
    String? fonteRecurso,
    String? modalidadeAplicacao,
    String? elementoDespesa,
    String? subelemento,
    String? descricaoNd,
    String? reservaNumero,
    String? reservaData,
    String? reservaValor,
    String? reservaObservacoes,
    String? empenhoModalidade,
    String? empenhoNumero,
    String? empenhoData,
    String? empenhoValor,
    String? desembolsoPeriodicidade,
    String? desembolsoMeses,
    String? desembolsoObservacoes,
    String? links,
  }) {
    return DotacaoData(
      exercicio: exercicio ?? this.exercicio,
      processoSei: processoSei ?? this.processoSei,
      responsavelOrcUserId:
      responsavelOrcUserId ?? this.responsavelOrcUserId,
      responsavelOrcNome:
      responsavelOrcNome ?? this.responsavelOrcNome,
      uo: uo ?? this.uo,
      ug: ug ?? this.ug,
      programa: programa ?? this.programa,
      acao: acao ?? this.acao,
      ptres: ptres ?? this.ptres,
      planoOrc: planoOrc ?? this.planoOrc,
      fonteRecurso: fonteRecurso ?? this.fonteRecurso,
      modalidadeAplicacao:
      modalidadeAplicacao ?? this.modalidadeAplicacao,
      elementoDespesa:
      elementoDespesa ?? this.elementoDespesa,
      subelemento: subelemento ?? this.subelemento,
      descricaoNd: descricaoNd ?? this.descricaoNd,
      reservaNumero: reservaNumero ?? this.reservaNumero,
      reservaData: reservaData ?? this.reservaData,
      reservaValor: reservaValor ?? this.reservaValor,
      reservaObservacoes:
      reservaObservacoes ?? this.reservaObservacoes,
      empenhoModalidade:
      empenhoModalidade ?? this.empenhoModalidade,
      empenhoNumero:
      empenhoNumero ?? this.empenhoNumero,
      empenhoData: empenhoData ?? this.empenhoData,
      empenhoValor: empenhoValor ?? this.empenhoValor,
      desembolsoPeriodicidade:
      desembolsoPeriodicidade ?? this.desembolsoPeriodicidade,
      desembolsoMeses:
      desembolsoMeses ?? this.desembolsoMeses,
      desembolsoObservacoes:
      desembolsoObservacoes ?? this.desembolsoObservacoes,
      links: links ?? this.links,
    );
  }

  @override
  List<Object?> get props => [
    exercicio,
    processoSei,
    responsavelOrcUserId,
    responsavelOrcNome,
    uo,
    ug,
    programa,
    acao,
    ptres,
    planoOrc,
    fonteRecurso,
    modalidadeAplicacao,
    elementoDespesa,
    subelemento,
    descricaoNd,
    reservaNumero,
    reservaData,
    reservaValor,
    reservaObservacoes,
    empenhoModalidade,
    empenhoNumero,
    empenhoData,
    empenhoValor,
    desembolsoPeriodicidade,
    desembolsoMeses,
    desembolsoObservacoes,
    links,
  ];
}

// -----------------------------------------------------------------------------
// Mapeamento para estrutura em seções (Firestore)
// -----------------------------------------------------------------------------
extension DotacaoDataSections on DotacaoData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      DotacaoSections.identificacao: {
        'exercicio': exercicio,
        'processoSei': processoSei,
        'responsavelOrcUserId': responsavelOrcUserId,
        'responsavelOrcNome': responsavelOrcNome,
      },
      DotacaoSections.vinculacaoProgramatica: {
        'uo': uo,
        'ug': ug,
        'programa': programa,
        'acao': acao,
        'ptres': ptres,
        'planoOrc': planoOrc,
        'fonteRecurso': fonteRecurso,
      },
      DotacaoSections.naturezaDespesa: {
        'modalidadeAplicacao': modalidadeAplicacao,
        'elementoDespesa': elementoDespesa,
        'subelemento': subelemento,
        'descricaoNd': descricaoNd,
      },
      DotacaoSections.reserva: {
        'reservaNumero': reservaNumero,
        'reservaData': reservaData,
        'reservaValor': reservaValor,
        'reservaObservacoes': reservaObservacoes,
      },
      DotacaoSections.empenho: {
        'empenhoModalidade': empenhoModalidade,
        'empenhoNumero': empenhoNumero,
        'empenhoData': empenhoData,
        'empenhoValor': empenhoValor,
      },
      DotacaoSections.cronograma: {
        'desembolsoPeriodicidade': desembolsoPeriodicidade,
        'desembolsoMeses': desembolsoMeses,
        'desembolsoObservacoes': desembolsoObservacoes,
      },
      DotacaoSections.documentos: {
        'links': links,
      },
    };
  }
}
