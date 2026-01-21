import 'package:equatable/equatable.dart';

import 'tr_sections.dart';

class TrData extends Equatable {
  // 1) Objeto e Fundamentação
  final String? objeto;
  final String? justificativa;
  final String? tipoContratacao;
  final String? regimeExecucao;

  // 2) Escopo / Requisitos
  final String? escopoDetalhado;
  final String? requisitosTecnicos;
  final String? especificacoesNormas;

  // 3) Local / Prazos / Cronograma
  final String? localExecucao;
  final String? prazoExecucaoDias;
  final String? vigenciaMeses;
  final String? cronogramaFisico;

  // 4) Medição / Aceite / Indicadores
  final String? criteriosMedicao;
  final String? criteriosAceite;
  final String? indicadoresDesempenho;

  // 5) Obrigações / Equipe / Gestão
  final String? obrigacoesContratada;
  final String? obrigacoesContratante;
  final String? equipeMinima;
  final String? fiscalNome;
  final String? fiscalUserId;
  final String? gestorNome;
  final String? gestorUserId;

  // 6) Licenciamento / Segurança / Sustentabilidade
  final String? licenciamentoAmbiental;
  final String? segurancaTrabalho;
  final String? sustentabilidade;

  // 7) Preços / Pagamento / Reajuste / Garantia
  final String? estimativaValor;
  final String? reajusteIndice;
  final String? condicoesPagamento;
  final String? garantia;

  // 8) Riscos / Penalidades / Demais
  final String? matrizRiscos;
  final String? penalidades;
  final String? demaisCondicoes;

  // 9) Documentos / Referências
  final String? linksDocumentos;

  const TrData({
    // 1) Objeto e Fundamentação
    this.objeto,
    this.justificativa,
    this.tipoContratacao,
    this.regimeExecucao,

    // 2) Escopo / Requisitos
    this.escopoDetalhado,
    this.requisitosTecnicos,
    this.especificacoesNormas,

    // 3) Local / Prazos / Cronograma
    this.localExecucao,
    this.prazoExecucaoDias,
    this.vigenciaMeses,
    this.cronogramaFisico,

    // 4) Medição / Aceite / Indicadores
    this.criteriosMedicao,
    this.criteriosAceite,
    this.indicadoresDesempenho,

    // 5) Obrigações / Equipe / Gestão
    this.obrigacoesContratada,
    this.obrigacoesContratante,
    this.equipeMinima,
    this.fiscalNome,
    this.fiscalUserId,
    this.gestorNome,
    this.gestorUserId,

    // 6) Licenciamento / Segurança / Sustentabilidade
    this.licenciamentoAmbiental,
    this.segurancaTrabalho,
    this.sustentabilidade,

    // 7) Preços / Pagamento / Reajuste / Garantia
    this.estimativaValor,
    this.reajusteIndice,
    this.condicoesPagamento,
    this.garantia,

    // 8) Riscos / Penalidades / Demais
    this.matrizRiscos,
    this.penalidades,
    this.demaisCondicoes,

    // 9) Documentos / Referências
    this.linksDocumentos,
  });

  /// Construtor "vazio" no padrão DfdData.empty / EtpData.empty
  const TrData.empty()
      : objeto = '',
        justificativa = '',
        tipoContratacao = '',
        regimeExecucao = '',
        escopoDetalhado = '',
        requisitosTecnicos = '',
        especificacoesNormas = '',
        localExecucao = '',
        prazoExecucaoDias = '',
        vigenciaMeses = '',
        cronogramaFisico = '',
        criteriosMedicao = '',
        criteriosAceite = '',
        indicadoresDesempenho = '',
        obrigacoesContratada = '',
        obrigacoesContratante = '',
        equipeMinima = '',
        fiscalNome = '',
        fiscalUserId = null,
        gestorNome = '',
        gestorUserId = null,
        licenciamentoAmbiental = '',
        segurancaTrabalho = '',
        sustentabilidade = '',
        estimativaValor = '',
        reajusteIndice = '',
        condicoesPagamento = '',
        garantia = '',
        matrizRiscos = '',
        penalidades = '',
        demaisCondicoes = '',
        linksDocumentos = '';

  // ---------------------------------------------------------------------------
  // Map "flat" (sem seções) — compat direto com Firestore se quiser salvar assim
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    // 1) Objeto e Fundamentação
    'objeto': objeto,
    'justificativa': justificativa,
    'tipoContratacao': tipoContratacao,
    'regimeExecucao': regimeExecucao,

    // 2) Escopo / Requisitos
    'escopoDetalhado': escopoDetalhado,
    'requisitosTecnicos': requisitosTecnicos,
    'especificacoesNormas': especificacoesNormas,

    // 3) Local / Prazos / Cronograma
    'localExecucao': localExecucao,
    'prazoExecucaoDias': prazoExecucaoDias,
    'vigenciaMeses': vigenciaMeses,
    'cronogramaFisico': cronogramaFisico,

    // 4) Medição / Aceite / Indicadores
    'criteriosMedicao': criteriosMedicao,
    'criteriosAceite': criteriosAceite,
    'indicadoresDesempenho': indicadoresDesempenho,

    // 5) Obrigações / Equipe / Gestão
    'obrigacoesContratada': obrigacoesContratada,
    'obrigacoesContratante': obrigacoesContratante,
    'equipeMinima': equipeMinima,
    'fiscalNome': fiscalNome,
    'fiscalUserId': fiscalUserId,
    'gestorNome': gestorNome,
    'gestorUserId': gestorUserId,

    // 6) Licenciamento / Segurança / Sustentabilidade
    'licenciamentoAmbiental': licenciamentoAmbiental,
    'segurancaTrabalho': segurancaTrabalho,
    'sustentabilidade': sustentabilidade,

    // 7) Preços / Pagamento / Reajuste / Garantia
    'estimativaValor': estimativaValor,
    'reajusteIndice': reajusteIndice,
    'condicoesPagamento': condicoesPagamento,
    'garantia': garantia,

    // 8) Riscos / Penalidades / Demais
    'matrizRiscos': matrizRiscos,
    'penalidades': penalidades,
    'demaisCondicoes': demaisCondicoes,

    // 9) Documentos / Referências
    'linksDocumentos': linksDocumentos,
  };

  factory TrData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TrData.empty();

    return TrData(
      // 1) Objeto e Fundamentação
      objeto: (map['objeto'] ?? '').toString(),
      justificativa: (map['justificativa'] ?? '').toString(),
      tipoContratacao: (map['tipoContratacao'] ?? '').toString(),
      regimeExecucao: (map['regimeExecucao'] ?? '').toString(),

      // 2) Escopo / Requisitos
      escopoDetalhado: (map['escopoDetalhado'] ?? '').toString(),
      requisitosTecnicos:
      (map['requisitosTecnicos'] ?? '').toString(),
      especificacoesNormas:
      (map['especificacoesNormas'] ?? '').toString(),

      // 3) Local / Prazos / Cronograma
      localExecucao: (map['localExecucao'] ?? '').toString(),
      prazoExecucaoDias:
      (map['prazoExecucaoDias'] ?? '').toString(),
      vigenciaMeses: (map['vigenciaMeses'] ?? '').toString(),
      cronogramaFisico:
      (map['cronogramaFisico'] ?? '').toString(),

      // 4) Medição / Aceite / Indicadores
      criteriosMedicao:
      (map['criteriosMedicao'] ?? '').toString(),
      criteriosAceite:
      (map['criteriosAceite'] ?? '').toString(),
      indicadoresDesempenho:
      (map['indicadoresDesempenho'] ?? '').toString(),

      // 5) Obrigações / Equipe / Gestão
      obrigacoesContratada:
      (map['obrigacoesContratada'] ?? '').toString(),
      obrigacoesContratante:
      (map['obrigacoesContratante'] ?? '').toString(),
      equipeMinima: (map['equipeMinima'] ?? '').toString(),
      fiscalNome: (map['fiscalNome'] ?? '').toString(),
      fiscalUserId: map['fiscalUserId']?.toString(),
      gestorNome: (map['gestorNome'] ?? '').toString(),
      gestorUserId: map['gestorUserId']?.toString(),

      // 6) Licenciamento / Segurança / Sustentabilidade
      licenciamentoAmbiental:
      (map['licenciamentoAmbiental'] ?? '').toString(),
      segurancaTrabalho:
      (map['segurancaTrabalho'] ?? '').toString(),
      sustentabilidade:
      (map['sustentabilidade'] ?? '').toString(),

      // 7) Preços / Pagamento / Reajuste / Garantia
      estimativaValor:
      (map['estimativaValor'] ?? '').toString(),
      reajusteIndice:
      (map['reajusteIndice'] ?? '').toString(),
      condicoesPagamento:
      (map['condicoesPagamento'] ?? '').toString(),
      garantia: (map['garantia'] ?? '').toString(),

      // 8) Riscos / Penalidades / Demais
      matrizRiscos: (map['matrizRiscos'] ?? '').toString(),
      penalidades: (map['penalidades'] ?? '').toString(),
      demaisCondicoes:
      (map['demaisCondicoes'] ?? '').toString(),

      // 9) Documentos / Referências
      linksDocumentos:
      (map['linksDocumentos'] ?? '').toString(),
    );
  }

  /// Mesmo padrão do DfdData.fromSectionsMap / EtpData.fromSectionsMap
  factory TrData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final obj = sections[TrSections.objetoFundamentacao] ??
        const <String, dynamic>{};
    final esc = sections[TrSections.escopoRequisitos] ??
        const <String, dynamic>{};
    final loc =
        sections[TrSections.localPrazosCronograma] ??
            const <String, dynamic>{};
    final med =
        sections[TrSections.medicaoAceiteIndicadores] ??
            const <String, dynamic>{};
    final obr =
        sections[TrSections.obrigacoesEquipeGestao] ??
            const <String, dynamic>{};
    final lic = sections[
    TrSections.licenciamentoSegurancaSustentabilidade] ??
        const <String, dynamic>{};
    final pre =
        sections[TrSections.precosPagamentoReajuste] ??
            const <String, dynamic>{};
    final ris =
        sections[TrSections.riscosPenalidadesCondicoes] ??
            const <String, dynamic>{};
    final doc =
        sections[TrSections.documentosReferencias] ??
            const <String, dynamic>{};

    return TrData(
      // 1) Objeto e Fundamentação
      objeto: (obj['objeto'] ?? '').toString(),
      justificativa:
      (obj['justificativa'] ?? '').toString(),
      tipoContratacao:
      (obj['tipoContratacao'] ?? '').toString(),
      regimeExecucao:
      (obj['regimeExecucao'] ?? '').toString(),

      // 2) Escopo / Requisitos
      escopoDetalhado:
      (esc['escopoDetalhado'] ?? '').toString(),
      requisitosTecnicos:
      (esc['requisitosTecnicos'] ?? '').toString(),
      especificacoesNormas:
      (esc['especificacoesNormas'] ?? '').toString(),

      // 3) Local / Prazos / Cronograma
      localExecucao:
      (loc['localExecucao'] ?? '').toString(),
      prazoExecucaoDias:
      (loc['prazoExecucaoDias'] ?? '').toString(),
      vigenciaMeses:
      (loc['vigenciaMeses'] ?? '').toString(),
      cronogramaFisico:
      (loc['cronogramaFisico'] ?? '').toString(),

      // 4) Medição / Aceite / Indicadores
      criteriosMedicao:
      (med['criteriosMedicao'] ?? '').toString(),
      criteriosAceite:
      (med['criteriosAceite'] ?? '').toString(),
      indicadoresDesempenho:
      (med['indicadoresDesempenho'] ?? '').toString(),

      // 5) Obrigações / Equipe / Gestão
      obrigacoesContratada:
      (obr['obrigacoesContratada'] ?? '').toString(),
      obrigacoesContratante:
      (obr['obrigacoesContratante'] ?? '').toString(),
      equipeMinima:
      (obr['equipeMinima'] ?? '').toString(),
      fiscalNome: (obr['fiscalNome'] ?? '').toString(),
      fiscalUserId: obr['fiscalUserId']?.toString(),
      gestorNome: (obr['gestorNome'] ?? '').toString(),
      gestorUserId: obr['gestorUserId']?.toString(),

      // 6) Licenciamento / Segurança / Sustentabilidade
      licenciamentoAmbiental:
      (lic['licenciamentoAmbiental'] ?? '').toString(),
      segurancaTrabalho:
      (lic['segurancaTrabalho'] ?? '').toString(),
      sustentabilidade:
      (lic['sustentabilidade'] ?? '').toString(),

      // 7) Preços / Pagamento / Reajuste / Garantia
      estimativaValor:
      (pre['estimativaValor'] ?? '').toString(),
      reajusteIndice:
      (pre['reajusteIndice'] ?? '').toString(),
      condicoesPagamento:
      (pre['condicoesPagamento'] ?? '').toString(),
      garantia: (pre['garantia'] ?? '').toString(),

      // 8) Riscos / Penalidades / Demais
      matrizRiscos:
      (ris['matrizRiscos'] ?? '').toString(),
      penalidades: (ris['penalidades'] ?? '').toString(),
      demaisCondicoes:
      (ris['demaisCondicoes'] ?? '').toString(),

      // 9) Documentos / Referências
      linksDocumentos:
      (doc['linksDocumentos'] ?? '').toString(),
    );
  }

  TrData copyWith({
    String? objeto,
    String? justificativa,
    String? tipoContratacao,
    String? regimeExecucao,
    String? escopoDetalhado,
    String? requisitosTecnicos,
    String? especificacoesNormas,
    String? localExecucao,
    String? prazoExecucaoDias,
    String? vigenciaMeses,
    String? cronogramaFisico,
    String? criteriosMedicao,
    String? criteriosAceite,
    String? indicadoresDesempenho,
    String? obrigacoesContratada,
    String? obrigacoesContratante,
    String? equipeMinima,
    String? fiscalNome,
    String? fiscalUserId,
    String? gestorNome,
    String? gestorUserId,
    String? licenciamentoAmbiental,
    String? segurancaTrabalho,
    String? sustentabilidade,
    String? estimativaValor,
    String? reajusteIndice,
    String? condicoesPagamento,
    String? garantia,
    String? matrizRiscos,
    String? penalidades,
    String? demaisCondicoes,
    String? linksDocumentos,
  }) {
    return TrData(
      objeto: objeto ?? this.objeto,
      justificativa: justificativa ?? this.justificativa,
      tipoContratacao: tipoContratacao ?? this.tipoContratacao,
      regimeExecucao: regimeExecucao ?? this.regimeExecucao,
      escopoDetalhado: escopoDetalhado ?? this.escopoDetalhado,
      requisitosTecnicos:
      requisitosTecnicos ?? this.requisitosTecnicos,
      especificacoesNormas:
      especificacoesNormas ?? this.especificacoesNormas,
      localExecucao: localExecucao ?? this.localExecucao,
      prazoExecucaoDias:
      prazoExecucaoDias ?? this.prazoExecucaoDias,
      vigenciaMeses: vigenciaMeses ?? this.vigenciaMeses,
      cronogramaFisico:
      cronogramaFisico ?? this.cronogramaFisico,
      criteriosMedicao:
      criteriosMedicao ?? this.criteriosMedicao,
      criteriosAceite: criteriosAceite ?? this.criteriosAceite,
      indicadoresDesempenho:
      indicadoresDesempenho ?? this.indicadoresDesempenho,
      obrigacoesContratada:
      obrigacoesContratada ?? this.obrigacoesContratada,
      obrigacoesContratante:
      obrigacoesContratante ?? this.obrigacoesContratante,
      equipeMinima: equipeMinima ?? this.equipeMinima,
      fiscalNome: fiscalNome ?? this.fiscalNome,
      fiscalUserId: fiscalUserId ?? this.fiscalUserId,
      gestorNome: gestorNome ?? this.gestorNome,
      gestorUserId: gestorUserId ?? this.gestorUserId,
      licenciamentoAmbiental:
      licenciamentoAmbiental ?? this.licenciamentoAmbiental,
      segurancaTrabalho:
      segurancaTrabalho ?? this.segurancaTrabalho,
      sustentabilidade:
      sustentabilidade ?? this.sustentabilidade,
      estimativaValor: estimativaValor ?? this.estimativaValor,
      reajusteIndice: reajusteIndice ?? this.reajusteIndice,
      condicoesPagamento:
      condicoesPagamento ?? this.condicoesPagamento,
      garantia: garantia ?? this.garantia,
      matrizRiscos: matrizRiscos ?? this.matrizRiscos,
      penalidades: penalidades ?? this.penalidades,
      demaisCondicoes:
      demaisCondicoes ?? this.demaisCondicoes,
      linksDocumentos:
      linksDocumentos ?? this.linksDocumentos,
    );
  }

  @override
  List<Object?> get props => [
    objeto,
    justificativa,
    tipoContratacao,
    regimeExecucao,
    escopoDetalhado,
    requisitosTecnicos,
    especificacoesNormas,
    localExecucao,
    prazoExecucaoDias,
    vigenciaMeses,
    cronogramaFisico,
    criteriosMedicao,
    criteriosAceite,
    indicadoresDesempenho,
    obrigacoesContratada,
    obrigacoesContratante,
    equipeMinima,
    fiscalNome,
    fiscalUserId,
    gestorNome,
    gestorUserId,
    licenciamentoAmbiental,
    segurancaTrabalho,
    sustentabilidade,
    estimativaValor,
    reajusteIndice,
    condicoesPagamento,
    garantia,
    matrizRiscos,
    penalidades,
    demaisCondicoes,
    linksDocumentos,
  ];
}

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (mesma usada no Firestore)
// -----------------------------------------------------------------------------
extension TrDataSections on TrData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      TrSections.objetoFundamentacao: {
        'objeto': objeto,
        'justificativa': justificativa,
        'tipoContratacao': tipoContratacao,
        'regimeExecucao': regimeExecucao,
      },
      TrSections.escopoRequisitos: {
        'escopoDetalhado': escopoDetalhado,
        'requisitosTecnicos': requisitosTecnicos,
        'especificacoesNormas': especificacoesNormas,
      },
      TrSections.localPrazosCronograma: {
        'localExecucao': localExecucao,
        'prazoExecucaoDias': prazoExecucaoDias,
        'vigenciaMeses': vigenciaMeses,
        'cronogramaFisico': cronogramaFisico,
      },
      TrSections.medicaoAceiteIndicadores: {
        'criteriosMedicao': criteriosMedicao,
        'criteriosAceite': criteriosAceite,
        'indicadoresDesempenho': indicadoresDesempenho,
      },
      TrSections.obrigacoesEquipeGestao: {
        'obrigacoesContratada': obrigacoesContratada,
        'obrigacoesContratante': obrigacoesContratante,
        'equipeMinima': equipeMinima,
        'fiscalNome': fiscalNome,
        'fiscalUserId': fiscalUserId,
        'gestorNome': gestorNome,
        'gestorUserId': gestorUserId,
      },
      TrSections.licenciamentoSegurancaSustentabilidade: {
        'licenciamentoAmbiental': licenciamentoAmbiental,
        'segurancaTrabalho': segurancaTrabalho,
        'sustentabilidade': sustentabilidade,
      },
      TrSections.precosPagamentoReajuste: {
        'estimativaValor': estimativaValor,
        'reajusteIndice': reajusteIndice,
        'condicoesPagamento': condicoesPagamento,
        'garantia': garantia,
      },
      TrSections.riscosPenalidadesCondicoes: {
        'matrizRiscos': matrizRiscos,
        'penalidades': penalidades,
        'demaisCondicoes': demaisCondicoes,
      },
      TrSections.documentosReferencias: {
        'linksDocumentos': linksDocumentos,
      },
    };
  }
}
