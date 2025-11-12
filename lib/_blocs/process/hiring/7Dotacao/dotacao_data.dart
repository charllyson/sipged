// lib/_blocs/process/hiring/7Dotacao/dotacao_data.dart
import 'package:equatable/equatable.dart';

class DotacaoData extends Equatable {
  final String? exercicio;
  final String? processoSei;
  final String? responsavelOrcUserId;
  final String? responsavelOrcNome;

  final String? uo;
  final String? ug;
  final String? programa;
  final String? acao;
  final String? ptres;
  final String? planoOrc;
  final String? fonteRecurso;

  final String? modalidadeAplicacao;
  final String? elementoDespesa;
  final String? subelemento;
  final String? descricaoNd;

  final String? reservaNumero;
  final String? reservaData;
  final String? reservaValor;
  final String? reservaObservacoes;

  final String? empenhoModalidade;
  final String? empenhoNumero;
  final String? empenhoData;
  final String? empenhoValor;

  final String? desembolsoPeriodicidade;
  final String? desembolsoMeses;
  final String? desembolsoObservacoes;

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
    if (map == null) return const DotacaoData();
    return DotacaoData(
      exercicio: map['exercicio'],
      processoSei: map['processoSei'],
      responsavelOrcUserId: map['responsavelOrcUserId'],
      responsavelOrcNome: map['responsavelOrcNome'],
      uo: map['uo'],
      ug: map['ug'],
      programa: map['programa'],
      acao: map['acao'],
      ptres: map['ptres'],
      planoOrc: map['planoOrc'],
      fonteRecurso: map['fonteRecurso'],
      modalidadeAplicacao: map['modalidadeAplicacao'],
      elementoDespesa: map['elementoDespesa'],
      subelemento: map['subelemento'],
      descricaoNd: map['descricaoNd'],
      reservaNumero: map['reservaNumero'],
      reservaData: map['reservaData'],
      reservaValor: map['reservaValor'],
      reservaObservacoes: map['reservaObservacoes'],
      empenhoModalidade: map['empenhoModalidade'],
      empenhoNumero: map['empenhoNumero'],
      empenhoData: map['empenhoData'],
      empenhoValor: map['empenhoValor'],
      desembolsoPeriodicidade: map['desembolsoPeriodicidade'],
      desembolsoMeses: map['desembolsoMeses'],
      desembolsoObservacoes: map['desembolsoObservacoes'],
      links: map['links'],
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
      responsavelOrcUserId: responsavelOrcUserId ?? this.responsavelOrcUserId,
      responsavelOrcNome: responsavelOrcNome ?? this.responsavelOrcNome,
      uo: uo ?? this.uo,
      ug: ug ?? this.ug,
      programa: programa ?? this.programa,
      acao: acao ?? this.acao,
      ptres: ptres ?? this.ptres,
      planoOrc: planoOrc ?? this.planoOrc,
      fonteRecurso: fonteRecurso ?? this.fonteRecurso,
      modalidadeAplicacao: modalidadeAplicacao ?? this.modalidadeAplicacao,
      elementoDespesa: elementoDespesa ?? this.elementoDespesa,
      subelemento: subelemento ?? this.subelemento,
      descricaoNd: descricaoNd ?? this.descricaoNd,
      reservaNumero: reservaNumero ?? this.reservaNumero,
      reservaData: reservaData ?? this.reservaData,
      reservaValor: reservaValor ?? this.reservaValor,
      reservaObservacoes: reservaObservacoes ?? this.reservaObservacoes,
      empenhoModalidade: empenhoModalidade ?? this.empenhoModalidade,
      empenhoNumero: empenhoNumero ?? this.empenhoNumero,
      empenhoData: empenhoData ?? this.empenhoData,
      empenhoValor: empenhoValor ?? this.empenhoValor,
      desembolsoPeriodicidade: desembolsoPeriodicidade ?? this.desembolsoPeriodicidade,
      desembolsoMeses: desembolsoMeses ?? this.desembolsoMeses,
      desembolsoObservacoes: desembolsoObservacoes ?? this.desembolsoObservacoes,
      links: links ?? this.links,
    );
  }

  @override
  List<Object?> get props => [
    exercicio, processoSei, responsavelOrcUserId, responsavelOrcNome,
    uo, ug, programa, acao, ptres, planoOrc, fonteRecurso,
    modalidadeAplicacao, elementoDespesa, subelemento, descricaoNd,
    reservaNumero, reservaData, reservaValor, reservaObservacoes,
    empenhoModalidade, empenhoNumero, empenhoData, empenhoValor,
    desembolsoPeriodicidade, desembolsoMeses, desembolsoObservacoes,
    links,
  ];
}
