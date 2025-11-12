import 'package:equatable/equatable.dart';

class EtpData extends Equatable {
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

  Map<String, dynamic> toMap() => {
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

  factory EtpData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EtpData();
    return EtpData(
      numero: map['numero'],
      dataElaboracao: map['dataElaboracao'],
      responsavelElaboracaoUserId: map['responsavelElaboracaoUserId'],
      responsavelElaboracaoNome: map['responsavelElaboracaoNome'],
      artNumero: map['artNumero'],
      motivacao: map['motivacao'],
      objetivos: map['objetivos'],
      requisitosMinimos: map['requisitosMinimos'],
      alternativasAvaliadas: map['alternativasAvaliadas'],
      solucaoRecomendada: map['solucaoRecomendada'],
      complexidade: map['complexidade'],
      nivelRisco: map['nivelRisco'],
      justificativaSolucao: map['justificativaSolucao'],
      analiseMercado: map['analiseMercado'],
      estimativaValor: map['estimativaValor'],
      metodoEstimativa: map['metodoEstimativa'],
      beneficiosEsperados: map['beneficiosEsperados'],
      prazoExecucaoDias: map['prazoExecucaoDias'],
      tempoVigenciaMeses: map['tempoVigenciaMeses'],
      criteriosAceite: map['criteriosAceite'],
      indicadoresDesempenho: map['indicadoresDesempenho'],
      premissas: map['premissas'],
      restricoes: map['restricoes'],
      licenciamentoAmbiental: map['licenciamentoAmbiental'],
      observacoesAmbientais: map['observacoesAmbientais'],
      levantamentosCampo: map['levantamentosCampo'],
      projetoExistente: map['projetoExistente'],
      linksEvidencias: map['linksEvidencias'],
      equipeEnvolvida: map['equipeEnvolvida'],
      conclusao: map['conclusao'],
    );
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
      responsavelElaboracaoUserId: responsavelElaboracaoUserId ?? this.responsavelElaboracaoUserId,
      responsavelElaboracaoNome: responsavelElaboracaoNome ?? this.responsavelElaboracaoNome,
      artNumero: artNumero ?? this.artNumero,
      motivacao: motivacao ?? this.motivacao,
      objetivos: objetivos ?? this.objetivos,
      requisitosMinimos: requisitosMinimos ?? this.requisitosMinimos,
      alternativasAvaliadas: alternativasAvaliadas ?? this.alternativasAvaliadas,
      solucaoRecomendada: solucaoRecomendada ?? this.solucaoRecomendada,
      complexidade: complexidade ?? this.complexidade,
      nivelRisco: nivelRisco ?? this.nivelRisco,
      justificativaSolucao: justificativaSolucao ?? this.justificativaSolucao,
      analiseMercado: analiseMercado ?? this.analiseMercado,
      estimativaValor: estimativaValor ?? this.estimativaValor,
      metodoEstimativa: metodoEstimativa ?? this.metodoEstimativa,
      beneficiosEsperados: beneficiosEsperados ?? this.beneficiosEsperados,
      prazoExecucaoDias: prazoExecucaoDias ?? this.prazoExecucaoDias,
      tempoVigenciaMeses: tempoVigenciaMeses ?? this.tempoVigenciaMeses,
      criteriosAceite: criteriosAceite ?? this.criteriosAceite,
      indicadoresDesempenho: indicadoresDesempenho ?? this.indicadoresDesempenho,
      premissas: premissas ?? this.premissas,
      restricoes: restricoes ?? this.restricoes,
      licenciamentoAmbiental: licenciamentoAmbiental ?? this.licenciamentoAmbiental,
      observacoesAmbientais: observacoesAmbientais ?? this.observacoesAmbientais,
      levantamentosCampo: levantamentosCampo ?? this.levantamentosCampo,
      projetoExistente: projetoExistente ?? this.projetoExistente,
      linksEvidencias: linksEvidencias ?? this.linksEvidencias,
      equipeEnvolvida: equipeEnvolvida ?? this.equipeEnvolvida,
      conclusao: conclusao ?? this.conclusao,
    );
  }

  @override
  List<Object?> get props => [
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
