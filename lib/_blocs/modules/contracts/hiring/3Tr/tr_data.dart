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
  final String? vigenciaDias;
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
    this.vigenciaDias,
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
        vigenciaDias = '',
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

  /// Compatibilidade temporária com telas/códigos antigos.
  ///
  /// Antes o campo era tratado como meses.
  /// Agora o valor correto deve ser sempre em dias.
  String? get vigenciaMeses => vigenciaDias;

  static String _text(dynamic value) {
    return (value ?? '').toString();
  }

  static String _firstText(
      Map<String, dynamic> map,
      List<String> keys,
      ) {
    for (final key in keys) {
      final value = map[key];

      if (value == null) continue;

      final text = value.toString();

      if (text.trim().isNotEmpty) {
        return text;
      }
    }

    return '';
  }

  // ---------------------------------------------------------------------------
  // Map "flat" — compat direto com Firestore se quiser salvar assim
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
    'vigenciaDias': vigenciaDias,
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
      objeto: _text(map['objeto']),
      justificativa: _text(map['justificativa']),
      tipoContratacao: _text(map['tipoContratacao']),
      regimeExecucao: _text(map['regimeExecucao']),

      // 2) Escopo / Requisitos
      escopoDetalhado: _text(map['escopoDetalhado']),
      requisitosTecnicos: _text(map['requisitosTecnicos']),
      especificacoesNormas: _text(map['especificacoesNormas']),

      // 3) Local / Prazos / Cronograma
      localExecucao: _text(map['localExecucao']),
      prazoExecucaoDias: _text(map['prazoExecucaoDias']),
      vigenciaDias: _firstText(
        map,
        const <String>[
          'vigenciaDias',
          'vigenciaContratualDias',
          'vigenciaExecucaoDias',

          // leitura retrocompatível de registros antigos
          'vigenciaMeses',
        ],
      ),
      cronogramaFisico: _text(map['cronogramaFisico']),

      // 4) Medição / Aceite / Indicadores
      criteriosMedicao: _text(map['criteriosMedicao']),
      criteriosAceite: _text(map['criteriosAceite']),
      indicadoresDesempenho: _text(map['indicadoresDesempenho']),

      // 5) Obrigações / Equipe / Gestão
      obrigacoesContratada: _text(map['obrigacoesContratada']),
      obrigacoesContratante: _text(map['obrigacoesContratante']),
      equipeMinima: _text(map['equipeMinima']),
      fiscalNome: _text(map['fiscalNome']),
      fiscalUserId: map['fiscalUserId']?.toString(),
      gestorNome: _text(map['gestorNome']),
      gestorUserId: map['gestorUserId']?.toString(),

      // 6) Licenciamento / Segurança / Sustentabilidade
      licenciamentoAmbiental: _text(map['licenciamentoAmbiental']),
      segurancaTrabalho: _text(map['segurancaTrabalho']),
      sustentabilidade: _text(map['sustentabilidade']),

      // 7) Preços / Pagamento / Reajuste / Garantia
      estimativaValor: _text(map['estimativaValor']),
      reajusteIndice: _text(map['reajusteIndice']),
      condicoesPagamento: _text(map['condicoesPagamento']),
      garantia: _text(map['garantia']),

      // 8) Riscos / Penalidades / Demais
      matrizRiscos: _text(map['matrizRiscos']),
      penalidades: _text(map['penalidades']),
      demaisCondicoes: _text(map['demaisCondicoes']),

      // 9) Documentos / Referências
      linksDocumentos: _text(map['linksDocumentos']),
    );
  }

  factory TrData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final obj = sections[TrSections.objetoFundamentacao] ??
        const <String, dynamic>{};

    final esc = sections[TrSections.escopoRequisitos] ??
        const <String, dynamic>{};

    final loc = sections[TrSections.localPrazosCronograma] ??
        const <String, dynamic>{};

    final med = sections[TrSections.medicaoAceiteIndicadores] ??
        const <String, dynamic>{};

    final obr = sections[TrSections.obrigacoesEquipeGestao] ??
        const <String, dynamic>{};

    final lic = sections[TrSections.licenciamentoSegurancaSustentabilidade] ??
        const <String, dynamic>{};

    final pre = sections[TrSections.precosPagamentoReajuste] ??
        const <String, dynamic>{};

    final ris = sections[TrSections.riscosPenalidadesCondicoes] ??
        const <String, dynamic>{};

    final doc = sections[TrSections.documentosReferencias] ??
        const <String, dynamic>{};

    return TrData(
      // 1) Objeto e Fundamentação
      objeto: _text(obj['objeto']),
      justificativa: _text(obj['justificativa']),
      tipoContratacao: _text(obj['tipoContratacao']),
      regimeExecucao: _text(obj['regimeExecucao']),

      // 2) Escopo / Requisitos
      escopoDetalhado: _text(esc['escopoDetalhado']),
      requisitosTecnicos: _text(esc['requisitosTecnicos']),
      especificacoesNormas: _text(esc['especificacoesNormas']),

      // 3) Local / Prazos / Cronograma
      localExecucao: _text(loc['localExecucao']),
      prazoExecucaoDias: _text(loc['prazoExecucaoDias']),
      vigenciaDias: _firstText(
        loc,
        const <String>[
          'vigenciaDias',
          'vigenciaContratualDias',
          'vigenciaExecucaoDias',

          // leitura retrocompatível de registros antigos
          'vigenciaMeses',
        ],
      ),
      cronogramaFisico: _text(loc['cronogramaFisico']),

      // 4) Medição / Aceite / Indicadores
      criteriosMedicao: _text(med['criteriosMedicao']),
      criteriosAceite: _text(med['criteriosAceite']),
      indicadoresDesempenho: _text(med['indicadoresDesempenho']),

      // 5) Obrigações / Equipe / Gestão
      obrigacoesContratada: _text(obr['obrigacoesContratada']),
      obrigacoesContratante: _text(obr['obrigacoesContratante']),
      equipeMinima: _text(obr['equipeMinima']),
      fiscalNome: _text(obr['fiscalNome']),
      fiscalUserId: obr['fiscalUserId']?.toString(),
      gestorNome: _text(obr['gestorNome']),
      gestorUserId: obr['gestorUserId']?.toString(),

      // 6) Licenciamento / Segurança / Sustentabilidade
      licenciamentoAmbiental: _text(lic['licenciamentoAmbiental']),
      segurancaTrabalho: _text(lic['segurancaTrabalho']),
      sustentabilidade: _text(lic['sustentabilidade']),

      // 7) Preços / Pagamento / Reajuste / Garantia
      estimativaValor: _text(pre['estimativaValor']),
      reajusteIndice: _text(pre['reajusteIndice']),
      condicoesPagamento: _text(pre['condicoesPagamento']),
      garantia: _text(pre['garantia']),

      // 8) Riscos / Penalidades / Demais
      matrizRiscos: _text(ris['matrizRiscos']),
      penalidades: _text(ris['penalidades']),
      demaisCondicoes: _text(ris['demaisCondicoes']),

      // 9) Documentos / Referências
      linksDocumentos: _text(doc['linksDocumentos']),
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
    String? vigenciaDias,

    /// Compatibilidade temporária com chamadas antigas.
    /// O valor será tratado como dias.
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
      requisitosTecnicos: requisitosTecnicos ?? this.requisitosTecnicos,
      especificacoesNormas: especificacoesNormas ?? this.especificacoesNormas,
      localExecucao: localExecucao ?? this.localExecucao,
      prazoExecucaoDias: prazoExecucaoDias ?? this.prazoExecucaoDias,
      vigenciaDias: vigenciaDias ?? vigenciaMeses ?? this.vigenciaDias,
      cronogramaFisico: cronogramaFisico ?? this.cronogramaFisico,
      criteriosMedicao: criteriosMedicao ?? this.criteriosMedicao,
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
      segurancaTrabalho: segurancaTrabalho ?? this.segurancaTrabalho,
      sustentabilidade: sustentabilidade ?? this.sustentabilidade,
      estimativaValor: estimativaValor ?? this.estimativaValor,
      reajusteIndice: reajusteIndice ?? this.reajusteIndice,
      condicoesPagamento: condicoesPagamento ?? this.condicoesPagamento,
      garantia: garantia ?? this.garantia,
      matrizRiscos: matrizRiscos ?? this.matrizRiscos,
      penalidades: penalidades ?? this.penalidades,
      demaisCondicoes: demaisCondicoes ?? this.demaisCondicoes,
      linksDocumentos: linksDocumentos ?? this.linksDocumentos,
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
    vigenciaDias,
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
// Mapeamento p/ estrutura em seções usada no Firestore
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
        'vigenciaDias': vigenciaDias,
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