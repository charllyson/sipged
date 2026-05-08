// lib/_blocs/modules/contracts/hiring/7Dotacao/dotacao_data.dart

import 'package:equatable/equatable.dart';

class DotacaoData extends Equatable {
  /// Chaves estáveis das seções da Dotação.
  /// Substitui o antigo arquivo dotacao_sections.dart.
  static const sectionIdentificacao = 'identificacao';
  static const sectionVinculacaoProgramatica = 'vinculacao';
  static const sectionNaturezaDespesa = 'natureza';
  static const sectionReserva = 'reserva';
  static const sectionEmpenho = 'empenho';
  static const sectionCronograma = 'cronograma';
  static const sectionDocumentos = 'documentos';

  static const sectionKeys = <String>[
    sectionIdentificacao,
    sectionVinculacaoProgramatica,
    sectionNaturezaDespesa,
    sectionReserva,
    sectionEmpenho,
    sectionCronograma,
    sectionDocumentos,
  ];

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

  static String _text(dynamic value) {
    return (value ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
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
  }

  factory DotacaoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const DotacaoData.empty();

    return DotacaoData(
      exercicio: _text(map['exercicio']),
      processoSei: _text(map['processoSei']),
      responsavelOrcUserId: map['responsavelOrcUserId']?.toString(),
      responsavelOrcNome: _text(map['responsavelOrcNome']),
      uo: _text(map['uo']),
      ug: _text(map['ug']),
      programa: _text(map['programa']),
      acao: _text(map['acao']),
      ptres: _text(map['ptres']),
      planoOrc: _text(map['planoOrc']),
      fonteRecurso: _text(map['fonteRecurso']),
      modalidadeAplicacao: _text(map['modalidadeAplicacao']),
      elementoDespesa: _text(map['elementoDespesa']),
      subelemento: _text(map['subelemento']),
      descricaoNd: _text(map['descricaoNd']),
      reservaNumero: _text(map['reservaNumero']),
      reservaData: _text(map['reservaData']),
      reservaValor: _text(map['reservaValor']),
      reservaObservacoes: _text(map['reservaObservacoes']),
      empenhoModalidade: _text(map['empenhoModalidade']),
      empenhoNumero: _text(map['empenhoNumero']),
      empenhoData: _text(map['empenhoData']),
      empenhoValor: _text(map['empenhoValor']),
      desembolsoPeriodicidade: _text(map['desembolsoPeriodicidade']),
      desembolsoMeses: _text(map['desembolsoMeses']),
      desembolsoObservacoes: _text(map['desembolsoObservacoes']),
      links: _text(map['links']),
    );
  }

  factory DotacaoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final i = sections[sectionIdentificacao] ?? const <String, dynamic>{};
    final v =
        sections[sectionVinculacaoProgramatica] ?? const <String, dynamic>{};
    final n = sections[sectionNaturezaDespesa] ?? const <String, dynamic>{};
    final r = sections[sectionReserva] ?? const <String, dynamic>{};
    final e = sections[sectionEmpenho] ?? const <String, dynamic>{};
    final c = sections[sectionCronograma] ?? const <String, dynamic>{};
    final d = sections[sectionDocumentos] ?? const <String, dynamic>{};

    return DotacaoData(
      exercicio: _text(i['exercicio']),
      processoSei: _text(i['processoSei']),
      responsavelOrcUserId: i['responsavelOrcUserId']?.toString(),
      responsavelOrcNome: _text(i['responsavelOrcNome']),
      uo: _text(v['uo']),
      ug: _text(v['ug']),
      programa: _text(v['programa']),
      acao: _text(v['acao']),
      ptres: _text(v['ptres']),
      planoOrc: _text(v['planoOrc']),
      fonteRecurso: _text(v['fonteRecurso']),
      modalidadeAplicacao: _text(n['modalidadeAplicacao']),
      elementoDespesa: _text(n['elementoDespesa']),
      subelemento: _text(n['subelemento']),
      descricaoNd: _text(n['descricaoNd']),
      reservaNumero: _text(r['reservaNumero']),
      reservaData: _text(r['reservaData']),
      reservaValor: _text(r['reservaValor']),
      reservaObservacoes: _text(r['reservaObservacoes']),
      empenhoModalidade: _text(e['empenhoModalidade']),
      empenhoNumero: _text(e['empenhoNumero']),
      empenhoData: _text(e['empenhoData']),
      empenhoValor: _text(e['empenhoValor']),
      desembolsoPeriodicidade: _text(c['desembolsoPeriodicidade']),
      desembolsoMeses: _text(c['desembolsoMeses']),
      desembolsoObservacoes: _text(c['desembolsoObservacoes']),
      links: _text(d['links']),
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
      responsavelOrcNome: responsavelOrcNome ?? this.responsavelOrcNome,
      uo: uo ?? this.uo,
      ug: ug ?? this.ug,
      programa: programa ?? this.programa,
      acao: acao ?? this.acao,
      ptres: ptres ?? this.ptres,
      planoOrc: planoOrc ?? this.planoOrc,
      fonteRecurso: fonteRecurso ?? this.fonteRecurso,
      modalidadeAplicacao:
      modalidadeAplicacao ?? this.modalidadeAplicacao,
      elementoDespesa: elementoDespesa ?? this.elementoDespesa,
      subelemento: subelemento ?? this.subelemento,
      descricaoNd: descricaoNd ?? this.descricaoNd,
      reservaNumero: reservaNumero ?? this.reservaNumero,
      reservaData: reservaData ?? this.reservaData,
      reservaValor: reservaValor ?? this.reservaValor,
      reservaObservacoes:
      reservaObservacoes ?? this.reservaObservacoes,
      empenhoModalidade: empenhoModalidade ?? this.empenhoModalidade,
      empenhoNumero: empenhoNumero ?? this.empenhoNumero,
      empenhoData: empenhoData ?? this.empenhoData,
      empenhoValor: empenhoValor ?? this.empenhoValor,
      desembolsoPeriodicidade:
      desembolsoPeriodicidade ?? this.desembolsoPeriodicidade,
      desembolsoMeses: desembolsoMeses ?? this.desembolsoMeses,
      desembolsoObservacoes:
      desembolsoObservacoes ?? this.desembolsoObservacoes,
      links: links ?? this.links,
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionIdentificacao: <String, dynamic>{
        'exercicio': exercicio,
        'processoSei': processoSei,
        'responsavelOrcUserId': responsavelOrcUserId,
        'responsavelOrcNome': responsavelOrcNome,
      },
      sectionVinculacaoProgramatica: <String, dynamic>{
        'uo': uo,
        'ug': ug,
        'programa': programa,
        'acao': acao,
        'ptres': ptres,
        'planoOrc': planoOrc,
        'fonteRecurso': fonteRecurso,
      },
      sectionNaturezaDespesa: <String, dynamic>{
        'modalidadeAplicacao': modalidadeAplicacao,
        'elementoDespesa': elementoDespesa,
        'subelemento': subelemento,
        'descricaoNd': descricaoNd,
      },
      sectionReserva: <String, dynamic>{
        'reservaNumero': reservaNumero,
        'reservaData': reservaData,
        'reservaValor': reservaValor,
        'reservaObservacoes': reservaObservacoes,
      },
      sectionEmpenho: <String, dynamic>{
        'empenhoModalidade': empenhoModalidade,
        'empenhoNumero': empenhoNumero,
        'empenhoData': empenhoData,
        'empenhoValor': empenhoValor,
      },
      sectionCronograma: <String, dynamic>{
        'desembolsoPeriodicidade': desembolsoPeriodicidade,
        'desembolsoMeses': desembolsoMeses,
        'desembolsoObservacoes': desembolsoObservacoes,
      },
      sectionDocumentos: <String, dynamic>{
        'links': links,
      },
    };
  }

  @override
  List<Object?> get props => <Object?>[
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