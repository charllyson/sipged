// lib/_blocs/modules/contracts/hiring/2Etp/etp_data.dart

import 'package:equatable/equatable.dart';

class EtpData extends Equatable {
  /// Chaves estáveis das seções do ETP.
  /// Substitui o antigo arquivo etp_sections.dart.
  static const sectionIdentificacao = 'identificacao';
  static const sectionMotivacao = 'motivacao';
  static const sectionAlternativas = 'alternativas';
  static const sectionMercado = 'mercado';
  static const sectionCronograma = 'gallery';
  static const sectionPremissas = 'premissas';
  static const sectionDocumentos = 'documentos';
  static const sectionConclusao = 'conclusao';

  static const sectionKeys = <String>[
    sectionIdentificacao,
    sectionMotivacao,
    sectionAlternativas,
    sectionMercado,
    sectionCronograma,
    sectionPremissas,
    sectionDocumentos,
    sectionConclusao,
  ];

  // 1) Identificação
  final String? numero;
  final String? dataElaboracao;
  final String? responsavelElaboracaoUserId;
  final String? responsavelElaboracaoNome;
  final String? artNumero;

  // 2) Motivação / Objetivos / Requisitos
  final String? motivacao;
  final String? objetivos;
  final String? requisitosMinimos;

  // 3) Alternativas e solução
  final String? alternativasAvaliadas;
  final String? solucaoRecomendada;
  final String? complexidade;
  final String? nivelRisco;
  final String? justificativaSolucao;

  // 4) Mercado / Estimativa
  final String? analiseMercado;
  final String? estimativaValor;
  final String? metodoEstimativa;
  final String? beneficiosEsperados;

  // 5) Cronograma / Indicadores / Aceite
  final String? prazoExecucaoDias;
  final String? tempoVigenciaMeses;
  final String? criteriosAceite;
  final String? indicadoresDesempenho;

  // 6) Premissas / Restrições / Licenciamento
  final String? premissas;
  final String? restricoes;
  final String? licenciamentoAmbiental;
  final String? observacoesAmbientais;

  // 7) Documentos / Equipe
  final String? levantamentosCampo;
  final String? projetoExistente;
  final String? linksEvidencias;
  final String? equipeEnvolvida;

  // 8) Conclusão
  final String? conclusao;

  const EtpData({
    this.numero,
    this.dataElaboracao,
    this.responsavelElaboracaoUserId,
    this.responsavelElaboracaoNome,
    this.artNumero,
    this.motivacao,
    this.objetivos,
    this.requisitosMinimos,
    this.alternativasAvaliadas,
    this.solucaoRecomendada,
    this.complexidade,
    this.nivelRisco,
    this.justificativaSolucao,
    this.analiseMercado,
    this.estimativaValor,
    this.metodoEstimativa,
    this.beneficiosEsperados,
    this.prazoExecucaoDias,
    this.tempoVigenciaMeses,
    this.criteriosAceite,
    this.indicadoresDesempenho,
    this.premissas,
    this.restricoes,
    this.licenciamentoAmbiental,
    this.observacoesAmbientais,
    this.levantamentosCampo,
    this.projetoExistente,
    this.linksEvidencias,
    this.equipeEnvolvida,
    this.conclusao,
  });

  const EtpData.empty()
      : numero = '',
        dataElaboracao = '',
        responsavelElaboracaoUserId = null,
        responsavelElaboracaoNome = '',
        artNumero = '',
        motivacao = '',
        objetivos = '',
        requisitosMinimos = '',
        alternativasAvaliadas = '',
        solucaoRecomendada = '',
        complexidade = '',
        nivelRisco = '',
        justificativaSolucao = '',
        analiseMercado = '',
        estimativaValor = '',
        metodoEstimativa = '',
        beneficiosEsperados = '',
        prazoExecucaoDias = '',
        tempoVigenciaMeses = '',
        criteriosAceite = '',
        indicadoresDesempenho = '',
        premissas = '',
        restricoes = '',
        licenciamentoAmbiental = '',
        observacoesAmbientais = '',
        levantamentosCampo = '',
        projetoExistente = '',
        linksEvidencias = '',
        equipeEnvolvida = '',
        conclusao = '';

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'numero': numero,
      'dataElaboracao': dataElaboracao,
      'responsavelElaboracaoUserId': responsavelElaboracaoUserId,
      'responsavelElaboracaoNome': responsavelElaboracaoNome,
      'artNumero': artNumero,
      'motivacao': motivacao,
      'objetivos': objetivos,
      'requisitosMinimos': requisitosMinimos,
      'alternativasAvaliadas': alternativasAvaliadas,
      'solucaoRecomendada': solucaoRecomendada,
      'complexidade': complexidade,
      'nivelRisco': nivelRisco,
      'justificativaSolucao': justificativaSolucao,
      'analiseMercado': analiseMercado,
      'estimativaValor': estimativaValor,
      'metodoEstimativa': metodoEstimativa,
      'beneficiosEsperados': beneficiosEsperados,
      'prazoExecucaoDias': prazoExecucaoDias,
      'tempoVigenciaMeses': tempoVigenciaMeses,
      'criteriosAceite': criteriosAceite,
      'indicadoresDesempenho': indicadoresDesempenho,
      'premissas': premissas,
      'restricoes': restricoes,
      'licenciamentoAmbiental': licenciamentoAmbiental,
      'observacoesAmbientais': observacoesAmbientais,
      'levantamentosCampo': levantamentosCampo,
      'projetoExistente': projetoExistente,
      'linksEvidencias': linksEvidencias,
      'equipeEnvolvida': equipeEnvolvida,
      'conclusao': conclusao,
    };
  }

  factory EtpData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EtpData.empty();

    String read(dynamic value) => (value ?? '').toString();

    return EtpData(
      numero: read(map['numero']),
      dataElaboracao: read(map['dataElaboracao']),
      responsavelElaboracaoUserId:
      map['responsavelElaboracaoUserId']?.toString(),
      responsavelElaboracaoNome: read(map['responsavelElaboracaoNome']),
      artNumero: read(map['artNumero']),
      motivacao: read(map['motivacao']),
      objetivos: read(map['objetivos']),
      requisitosMinimos: read(map['requisitosMinimos']),
      alternativasAvaliadas: read(map['alternativasAvaliadas']),
      solucaoRecomendada: read(map['solucaoRecomendada']),
      complexidade: read(map['complexidade']),
      nivelRisco: read(map['nivelRisco']),
      justificativaSolucao: read(map['justificativaSolucao']),
      analiseMercado: read(map['analiseMercado']),
      estimativaValor: read(map['estimativaValor']),
      metodoEstimativa: read(map['metodoEstimativa']),
      beneficiosEsperados: read(map['beneficiosEsperados']),
      prazoExecucaoDias: read(map['prazoExecucaoDias']),
      tempoVigenciaMeses: read(map['tempoVigenciaMeses']),
      criteriosAceite: read(map['criteriosAceite']),
      indicadoresDesempenho: read(map['indicadoresDesempenho']),
      premissas: read(map['premissas']),
      restricoes: read(map['restricoes']),
      licenciamentoAmbiental: read(map['licenciamentoAmbiental']),
      observacoesAmbientais: read(map['observacoesAmbientais']),
      levantamentosCampo: read(map['levantamentosCampo']),
      projetoExistente: read(map['projetoExistente']),
      linksEvidencias: read(map['linksEvidencias']),
      equipeEnvolvida: read(map['equipeEnvolvida']),
      conclusao: read(map['conclusao']),
    );
  }

  factory EtpData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final identificacao = sections[sectionIdentificacao] ?? const {};
    final motivacaoMap = sections[sectionMotivacao] ?? const {};
    final alternativas = sections[sectionAlternativas] ?? const {};
    final mercado = sections[sectionMercado] ?? const {};
    final cronograma = sections[sectionCronograma] ?? const {};
    final premissasMap = sections[sectionPremissas] ?? const {};
    final documentos = sections[sectionDocumentos] ?? const {};
    final conclusaoMap = sections[sectionConclusao] ?? const {};

    String read(Map<String, dynamic> map, String key) {
      return (map[key] ?? '').toString();
    }

    return EtpData(
      numero: read(identificacao, 'numero'),
      dataElaboracao: read(identificacao, 'dataElaboracao'),
      responsavelElaboracaoUserId:
      identificacao['responsavelElaboracaoUserId']?.toString(),
      responsavelElaboracaoNome:
      read(identificacao, 'responsavelElaboracaoNome'),
      artNumero: read(identificacao, 'artNumero'),
      motivacao: read(motivacaoMap, 'motivacao'),
      objetivos: read(motivacaoMap, 'objetivos'),
      requisitosMinimos: read(motivacaoMap, 'requisitosMinimos'),
      alternativasAvaliadas:
      read(alternativas, 'alternativasAvaliadas'),
      solucaoRecomendada:
      read(alternativas, 'solucaoRecomendada'),
      complexidade: read(alternativas, 'complexidade'),
      nivelRisco: read(alternativas, 'nivelRisco'),
      justificativaSolucao:
      read(alternativas, 'justificativaSolucao'),
      analiseMercado: read(mercado, 'analiseMercado'),
      estimativaValor: read(mercado, 'estimativaValor'),
      metodoEstimativa: read(mercado, 'metodoEstimativa'),
      beneficiosEsperados: read(mercado, 'beneficiosEsperados'),
      prazoExecucaoDias: read(cronograma, 'prazoExecucaoDias'),
      tempoVigenciaMeses: read(cronograma, 'tempoVigenciaMeses'),
      criteriosAceite: read(cronograma, 'criteriosAceite'),
      indicadoresDesempenho:
      read(cronograma, 'indicadoresDesempenho'),
      premissas: read(premissasMap, 'premissas'),
      restricoes: read(premissasMap, 'restricoes'),
      licenciamentoAmbiental:
      read(premissasMap, 'licenciamentoAmbiental'),
      observacoesAmbientais:
      read(premissasMap, 'observacoesAmbientais'),
      levantamentosCampo:
      read(documentos, 'levantamentosCampo'),
      projetoExistente: read(documentos, 'projetoExistente'),
      linksEvidencias: read(documentos, 'linksEvidencias'),
      equipeEnvolvida: read(documentos, 'equipeEnvolvida'),
      conclusao: read(conclusaoMap, 'conclusao'),
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionIdentificacao: <String, dynamic>{
        'numero': numero,
        'dataElaboracao': dataElaboracao,
        'responsavelElaboracaoUserId': responsavelElaboracaoUserId,
        'responsavelElaboracaoNome': responsavelElaboracaoNome,
        'artNumero': artNumero,
      },
      sectionMotivacao: <String, dynamic>{
        'motivacao': motivacao,
        'objetivos': objetivos,
        'requisitosMinimos': requisitosMinimos,
      },
      sectionAlternativas: <String, dynamic>{
        'alternativasAvaliadas': alternativasAvaliadas,
        'solucaoRecomendada': solucaoRecomendada,
        'complexidade': complexidade,
        'nivelRisco': nivelRisco,
        'justificativaSolucao': justificativaSolucao,
      },
      sectionMercado: <String, dynamic>{
        'analiseMercado': analiseMercado,
        'estimativaValor': estimativaValor,
        'metodoEstimativa': metodoEstimativa,
        'beneficiosEsperados': beneficiosEsperados,
      },
      sectionCronograma: <String, dynamic>{
        'prazoExecucaoDias': prazoExecucaoDias,
        'tempoVigenciaMeses': tempoVigenciaMeses,
        'criteriosAceite': criteriosAceite,
        'indicadoresDesempenho': indicadoresDesempenho,
      },
      sectionPremissas: <String, dynamic>{
        'premissas': premissas,
        'restricoes': restricoes,
        'licenciamentoAmbiental': licenciamentoAmbiental,
        'observacoesAmbientais': observacoesAmbientais,
      },
      sectionDocumentos: <String, dynamic>{
        'levantamentosCampo': levantamentosCampo,
        'projetoExistente': projetoExistente,
        'linksEvidencias': linksEvidencias,
        'equipeEnvolvida': equipeEnvolvida,
      },
      sectionConclusao: <String, dynamic>{
        'conclusao': conclusao,
      },
    };
  }

  EtpData copyWith({
    String? numero,
    String? dataElaboracao,
    String? responsavelElaboracaoUserId,
    String? responsavelElaboracaoNome,
    String? artNumero,
    String? motivacao,
    String? objetivos,
    String? requisitosMinimos,
    String? alternativasAvaliadas,
    String? solucaoRecomendada,
    String? complexidade,
    String? nivelRisco,
    String? justificativaSolucao,
    String? analiseMercado,
    String? estimativaValor,
    String? metodoEstimativa,
    String? beneficiosEsperados,
    String? prazoExecucaoDias,
    String? tempoVigenciaMeses,
    String? criteriosAceite,
    String? indicadoresDesempenho,
    String? premissas,
    String? restricoes,
    String? licenciamentoAmbiental,
    String? observacoesAmbientais,
    String? levantamentosCampo,
    String? projetoExistente,
    String? linksEvidencias,
    String? equipeEnvolvida,
    String? conclusao,
  }) {
    return EtpData(
      numero: numero ?? this.numero,
      dataElaboracao: dataElaboracao ?? this.dataElaboracao,
      responsavelElaboracaoUserId:
      responsavelElaboracaoUserId ??
          this.responsavelElaboracaoUserId,
      responsavelElaboracaoNome:
      responsavelElaboracaoNome ??
          this.responsavelElaboracaoNome,
      artNumero: artNumero ?? this.artNumero,
      motivacao: motivacao ?? this.motivacao,
      objetivos: objetivos ?? this.objetivos,
      requisitosMinimos:
      requisitosMinimos ?? this.requisitosMinimos,
      alternativasAvaliadas:
      alternativasAvaliadas ?? this.alternativasAvaliadas,
      solucaoRecomendada:
      solucaoRecomendada ?? this.solucaoRecomendada,
      complexidade: complexidade ?? this.complexidade,
      nivelRisco: nivelRisco ?? this.nivelRisco,
      justificativaSolucao:
      justificativaSolucao ?? this.justificativaSolucao,
      analiseMercado: analiseMercado ?? this.analiseMercado,
      estimativaValor: estimativaValor ?? this.estimativaValor,
      metodoEstimativa:
      metodoEstimativa ?? this.metodoEstimativa,
      beneficiosEsperados:
      beneficiosEsperados ?? this.beneficiosEsperados,
      prazoExecucaoDias:
      prazoExecucaoDias ?? this.prazoExecucaoDias,
      tempoVigenciaMeses:
      tempoVigenciaMeses ?? this.tempoVigenciaMeses,
      criteriosAceite:
      criteriosAceite ?? this.criteriosAceite,
      indicadoresDesempenho:
      indicadoresDesempenho ?? this.indicadoresDesempenho,
      premissas: premissas ?? this.premissas,
      restricoes: restricoes ?? this.restricoes,
      licenciamentoAmbiental:
      licenciamentoAmbiental ?? this.licenciamentoAmbiental,
      observacoesAmbientais:
      observacoesAmbientais ?? this.observacoesAmbientais,
      levantamentosCampo:
      levantamentosCampo ?? this.levantamentosCampo,
      projetoExistente:
      projetoExistente ?? this.projetoExistente,
      linksEvidencias:
      linksEvidencias ?? this.linksEvidencias,
      equipeEnvolvida:
      equipeEnvolvida ?? this.equipeEnvolvida,
      conclusao: conclusao ?? this.conclusao,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    numero,
    dataElaboracao,
    responsavelElaboracaoUserId,
    responsavelElaboracaoNome,
    artNumero,
    motivacao,
    objetivos,
    requisitosMinimos,
    alternativasAvaliadas,
    solucaoRecomendada,
    complexidade,
    nivelRisco,
    justificativaSolucao,
    analiseMercado,
    estimativaValor,
    metodoEstimativa,
    beneficiosEsperados,
    prazoExecucaoDias,
    tempoVigenciaMeses,
    criteriosAceite,
    indicadoresDesempenho,
    premissas,
    restricoes,
    licenciamentoAmbiental,
    observacoesAmbientais,
    levantamentosCampo,
    projetoExistente,
    linksEvidencias,
    equipeEnvolvida,
    conclusao,
  ];
}