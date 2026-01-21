import 'package:equatable/equatable.dart';

import 'etp_sections.dart';

class EtpData extends Equatable {
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

    // 2) Motivação / Objetivos / Requisitos
    this.motivacao,
    this.objetivos,
    this.requisitosMinimos,

    // 3) Alternativas e solução
    this.alternativasAvaliadas,
    this.solucaoRecomendada,
    this.complexidade,
    this.nivelRisco,
    this.justificativaSolucao,

    // 4) Mercado / Estimativa
    this.analiseMercado,
    this.estimativaValor,
    this.metodoEstimativa,
    this.beneficiosEsperados,

    // 5) Cronograma / Indicadores / Aceite
    this.prazoExecucaoDias,
    this.tempoVigenciaMeses,
    this.criteriosAceite,
    this.indicadoresDesempenho,

    // 6) Premissas / Restrições / Licenciamento
    this.premissas,
    this.restricoes,
    this.licenciamentoAmbiental,
    this.observacoesAmbientais,

    // 7) Documentos / Equipe
    this.levantamentosCampo,
    this.projetoExistente,
    this.linksEvidencias,
    this.equipeEnvolvida,

    // 8) Conclusão
    this.conclusao,
  });

  /// Construtor "vazio" no mesmo padrão do DfdData.empty
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

  // ---------------------------------------------------------------------------
  // Map "flat" (sem seções) — compat direto com Firestore
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    // 1) Identificação
    'numero': numero,
    'dataElaboracao': dataElaboracao,
    'responsavelElaboracaoUserId': responsavelElaboracaoUserId,
    'responsavelElaboracaoNome': responsavelElaboracaoNome,
    'artNumero': artNumero,

    // 2) Motivação / Objetivos / Requisitos
    'motivacao': motivacao,
    'objetivos': objetivos,
    'requisitosMinimos': requisitosMinimos,

    // 3) Alternativas e solução
    'alternativasAvaliadas': alternativasAvaliadas,
    'solucaoRecomendada': solucaoRecomendada,
    'complexidade': complexidade,
    'nivelRisco': nivelRisco,
    'justificativaSolucao': justificativaSolucao,

    // 4) Mercado / Estimativa
    'analiseMercado': analiseMercado,
    'estimativaValor': estimativaValor,
    'metodoEstimativa': metodoEstimativa,
    'beneficiosEsperados': beneficiosEsperados,

    // 5) Cronograma / Indicadores / Aceite
    'prazoExecucaoDias': prazoExecucaoDias,
    'tempoVigenciaMeses': tempoVigenciaMeses,
    'criteriosAceite': criteriosAceite,
    'indicadoresDesempenho': indicadoresDesempenho,

    // 6) Premissas / Restrições / Licenciamento
    'premissas': premissas,
    'restricoes': restricoes,
    'licenciamentoAmbiental': licenciamentoAmbiental,
    'observacoesAmbientais': observacoesAmbientais,

    // 7) Documentos / Equipe
    'levantamentosCampo': levantamentosCampo,
    'projetoExistente': projetoExistente,
    'linksEvidencias': linksEvidencias,
    'equipeEnvolvida': equipeEnvolvida,

    // 8) Conclusão
    'conclusao': conclusao,
  };

  factory EtpData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EtpData.empty();

    return EtpData(
      // 1) Identificação
      numero: (map['numero'] ?? '').toString(),
      dataElaboracao: (map['dataElaboracao'] ?? '').toString(),
      responsavelElaboracaoUserId:
      map['responsavelElaboracaoUserId']?.toString(),
      responsavelElaboracaoNome:
      (map['responsavelElaboracaoNome'] ?? '').toString(),
      artNumero: (map['artNumero'] ?? '').toString(),

      // 2) Motivação / Objetivos / Requisitos
      motivacao: (map['motivacao'] ?? '').toString(),
      objetivos: (map['objetivos'] ?? '').toString(),
      requisitosMinimos: (map['requisitosMinimos'] ?? '').toString(),

      // 3) Alternativas e solução
      alternativasAvaliadas:
      (map['alternativasAvaliadas'] ?? '').toString(),
      solucaoRecomendada:
      (map['solucaoRecomendada'] ?? '').toString(),
      complexidade: (map['complexidade'] ?? '').toString(),
      nivelRisco: (map['nivelRisco'] ?? '').toString(),
      justificativaSolucao:
      (map['justificativaSolucao'] ?? '').toString(),

      // 4) Mercado / Estimativa
      analiseMercado: (map['analiseMercado'] ?? '').toString(),
      estimativaValor: (map['estimativaValor'] ?? '').toString(),
      metodoEstimativa: (map['metodoEstimativa'] ?? '').toString(),
      beneficiosEsperados:
      (map['beneficiosEsperados'] ?? '').toString(),

      // 5) Cronograma / Indicadores / Aceite
      prazoExecucaoDias:
      (map['prazoExecucaoDias'] ?? '').toString(),
      tempoVigenciaMeses:
      (map['tempoVigenciaMeses'] ?? '').toString(),
      criteriosAceite: (map['criteriosAceite'] ?? '').toString(),
      indicadoresDesempenho:
      (map['indicadoresDesempenho'] ?? '').toString(),

      // 6) Premissas / Restrições / Licenciamento
      premissas: (map['premissas'] ?? '').toString(),
      restricoes: (map['restricoes'] ?? '').toString(),
      licenciamentoAmbiental:
      (map['licenciamentoAmbiental'] ?? '').toString(),
      observacoesAmbientais:
      (map['observacoesAmbientais'] ?? '').toString(),

      // 7) Documentos / Equipe
      levantamentosCampo:
      (map['levantamentosCampo'] ?? '').toString(),
      projetoExistente:
      (map['projetoExistente'] ?? '').toString(),
      linksEvidencias: (map['linksEvidencias'] ?? '').toString(),
      equipeEnvolvida:
      (map['equipeEnvolvida'] ?? '').toString(),

      // 8) Conclusão
      conclusao: (map['conclusao'] ?? '').toString(),
    );
  }

  /// Mesmo padrão do DfdData.fromSectionsMap
  factory EtpData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final i = sections[EtpSections.identificacao] ??
        const <String, dynamic>{};
    final m = sections[EtpSections.motivacao] ??
        const <String, dynamic>{};
    final alt = sections[EtpSections.alternativas] ??
        const <String, dynamic>{};
    final mer = sections[EtpSections.mercado] ??
        const <String, dynamic>{};
    final c = sections[EtpSections.cronograma] ??
        const <String, dynamic>{};
    final p = sections[EtpSections.premissas] ??
        const <String, dynamic>{};
    final d = sections[EtpSections.documentos] ??
        const <String, dynamic>{};
    final con = sections[EtpSections.conclusao] ??
        const <String, dynamic>{};

    return EtpData(
      // 1) Identificação
      numero: (i['numero'] ?? '').toString(),
      dataElaboracao: (i['dataElaboracao'] ?? '').toString(),
      responsavelElaboracaoUserId:
      i['responsavelElaboracaoUserId']?.toString(),
      responsavelElaboracaoNome:
      (i['responsavelElaboracaoNome'] ?? '').toString(),
      artNumero: (i['artNumero'] ?? '').toString(),

      // 2) Motivação / Objetivos / Requisitos
      motivacao: (m['motivacao'] ?? '').toString(),
      objetivos: (m['objetivos'] ?? '').toString(),
      requisitosMinimos:
      (m['requisitosMinimos'] ?? '').toString(),

      // 3) Alternativas e solução
      alternativasAvaliadas:
      (alt['alternativasAvaliadas'] ?? '').toString(),
      solucaoRecomendada:
      (alt['solucaoRecomendada'] ?? '').toString(),
      complexidade: (alt['complexidade'] ?? '').toString(),
      nivelRisco: (alt['nivelRisco'] ?? '').toString(),
      justificativaSolucao:
      (alt['justificativaSolucao'] ?? '').toString(),

      // 4) Mercado / Estimativa
      analiseMercado:
      (mer['analiseMercado'] ?? '').toString(),
      estimativaValor:
      (mer['estimativaValor'] ?? '').toString(),
      metodoEstimativa:
      (mer['metodoEstimativa'] ?? '').toString(),
      beneficiosEsperados:
      (mer['beneficiosEsperados'] ?? '').toString(),

      // 5) Cronograma / Indicadores / Aceite
      prazoExecucaoDias:
      (c['prazoExecucaoDias'] ?? '').toString(),
      tempoVigenciaMeses:
      (c['tempoVigenciaMeses'] ?? '').toString(),
      criteriosAceite:
      (c['criteriosAceite'] ?? '').toString(),
      indicadoresDesempenho:
      (c['indicadoresDesempenho'] ?? '').toString(),

      // 6) Premissas / Restrições / Licenciamento
      premissas: (p['premissas'] ?? '').toString(),
      restricoes: (p['restricoes'] ?? '').toString(),
      licenciamentoAmbiental:
      (p['licenciamentoAmbiental'] ?? '').toString(),
      observacoesAmbientais:
      (p['observacoesAmbientais'] ?? '').toString(),

      // 7) Documentos / Equipe
      levantamentosCampo:
      (d['levantamentosCampo'] ?? '').toString(),
      projetoExistente:
      (d['projetoExistente'] ?? '').toString(),
      linksEvidencias:
      (d['linksEvidencias'] ?? '').toString(),
      equipeEnvolvida:
      (d['equipeEnvolvida'] ?? '').toString(),

      // 8) Conclusão
      conclusao: (con['conclusao'] ?? '').toString(),
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

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (mesma usada no Firestore)
// -----------------------------------------------------------------------------
extension EtpDataSections on EtpData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      EtpSections.identificacao: {
        'numero': numero,
        'dataElaboracao': dataElaboracao,
        'responsavelElaboracaoUserId':
        responsavelElaboracaoUserId,
        'responsavelElaboracaoNome':
        responsavelElaboracaoNome,
        'artNumero': artNumero,
      },
      EtpSections.motivacao: {
        'motivacao': motivacao,
        'objetivos': objetivos,
        'requisitosMinimos': requisitosMinimos,
      },
      EtpSections.alternativas: {
        'alternativasAvaliadas': alternativasAvaliadas,
        'solucaoRecomendada': solucaoRecomendada,
        'complexidade': complexidade,
        'nivelRisco': nivelRisco,
        'justificativaSolucao': justificativaSolucao,
      },
      EtpSections.mercado: {
        'analiseMercado': analiseMercado,
        'estimativaValor': estimativaValor,
        'metodoEstimativa': metodoEstimativa,
        'beneficiosEsperados': beneficiosEsperados,
      },
      EtpSections.cronograma: {
        'prazoExecucaoDias': prazoExecucaoDias,
        'tempoVigenciaMeses': tempoVigenciaMeses,
        'criteriosAceite': criteriosAceite,
        'indicadoresDesempenho': indicadoresDesempenho,
      },
      EtpSections.premissas: {
        'premissas': premissas,
        'restricoes': restricoes,
        'licenciamentoAmbiental': licenciamentoAmbiental,
        'observacoesAmbientais': observacoesAmbientais,
      },
      EtpSections.documentos: {
        'levantamentosCampo': levantamentosCampo,
        'projetoExistente': projetoExistente,
        'linksEvidencias': linksEvidencias,
        'equipeEnvolvida': equipeEnvolvida,
      },
      EtpSections.conclusao: {
        'conclusao': conclusao,
      },
    };
  }
}
