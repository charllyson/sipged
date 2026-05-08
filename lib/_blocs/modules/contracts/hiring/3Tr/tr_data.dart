// lib/_blocs/modules/contracts/hiring/3Tr/tr_data.dart

import 'package:equatable/equatable.dart';

class TrData extends Equatable {
  /// Chaves estáveis das seções do TR.
  /// Substitui o antigo arquivo tr_sections.dart.
  static const sectionObjetoFundamentacao = 'objetoFundamentacao';
  static const sectionEscopoRequisitos = 'escopoRequisitos';
  static const sectionLocalPrazosCronograma = 'localPrazosCronograma';
  static const sectionMedicaoAceiteIndicadores = 'medicaoAceiteIndicadores';
  static const sectionObrigacoesEquipeGestao = 'obrigacoesEquipeGestao';
  static const sectionLicenciamentoSegurancaSustentabilidade =
      'licenciamentoSegurancaSustentabilidade';
  static const sectionPrecosPagamentoReajuste = 'precosPagamentoReajuste';
  static const sectionRiscosPenalidadesCondicoes =
      'riscosPenalidadesCondicoes';
  static const sectionDocumentosReferencias = 'documentosReferencias';

  static const sectionKeys = <String>[
    sectionObjetoFundamentacao,
    sectionEscopoRequisitos,
    sectionLocalPrazosCronograma,
    sectionMedicaoAceiteIndicadores,
    sectionObrigacoesEquipeGestao,
    sectionLicenciamentoSegurancaSustentabilidade,
    sectionPrecosPagamentoReajuste,
    sectionRiscosPenalidadesCondicoes,
    sectionDocumentosReferencias,
  ];

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
    this.objeto,
    this.justificativa,
    this.tipoContratacao,
    this.regimeExecucao,
    this.escopoDetalhado,
    this.requisitosTecnicos,
    this.especificacoesNormas,
    this.localExecucao,
    this.prazoExecucaoDias,
    this.vigenciaDias,
    this.cronogramaFisico,
    this.criteriosMedicao,
    this.criteriosAceite,
    this.indicadoresDesempenho,
    this.obrigacoesContratada,
    this.obrigacoesContratante,
    this.equipeMinima,
    this.fiscalNome,
    this.fiscalUserId,
    this.gestorNome,
    this.gestorUserId,
    this.licenciamentoAmbiental,
    this.segurancaTrabalho,
    this.sustentabilidade,
    this.estimativaValor,
    this.reajusteIndice,
    this.condicoesPagamento,
    this.garantia,
    this.matrizRiscos,
    this.penalidades,
    this.demaisCondicoes,
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

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'objeto': objeto,
      'justificativa': justificativa,
      'tipoContratacao': tipoContratacao,
      'regimeExecucao': regimeExecucao,
      'escopoDetalhado': escopoDetalhado,
      'requisitosTecnicos': requisitosTecnicos,
      'especificacoesNormas': especificacoesNormas,
      'localExecucao': localExecucao,
      'prazoExecucaoDias': prazoExecucaoDias,
      'vigenciaDias': vigenciaDias,
      'cronogramaFisico': cronogramaFisico,
      'criteriosMedicao': criteriosMedicao,
      'criteriosAceite': criteriosAceite,
      'indicadoresDesempenho': indicadoresDesempenho,
      'obrigacoesContratada': obrigacoesContratada,
      'obrigacoesContratante': obrigacoesContratante,
      'equipeMinima': equipeMinima,
      'fiscalNome': fiscalNome,
      'fiscalUserId': fiscalUserId,
      'gestorNome': gestorNome,
      'gestorUserId': gestorUserId,
      'licenciamentoAmbiental': licenciamentoAmbiental,
      'segurancaTrabalho': segurancaTrabalho,
      'sustentabilidade': sustentabilidade,
      'estimativaValor': estimativaValor,
      'reajusteIndice': reajusteIndice,
      'condicoesPagamento': condicoesPagamento,
      'garantia': garantia,
      'matrizRiscos': matrizRiscos,
      'penalidades': penalidades,
      'demaisCondicoes': demaisCondicoes,
      'linksDocumentos': linksDocumentos,
    };
  }

  factory TrData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const TrData.empty();

    return TrData(
      objeto: _text(map['objeto']),
      justificativa: _text(map['justificativa']),
      tipoContratacao: _text(map['tipoContratacao']),
      regimeExecucao: _text(map['regimeExecucao']),
      escopoDetalhado: _text(map['escopoDetalhado']),
      requisitosTecnicos: _text(map['requisitosTecnicos']),
      especificacoesNormas: _text(map['especificacoesNormas']),
      localExecucao: _text(map['localExecucao']),
      prazoExecucaoDias: _text(map['prazoExecucaoDias']),
      vigenciaDias: _firstText(
        map,
        const <String>[
          'vigenciaDias',
          'vigenciaContratualDias',
          'vigenciaExecucaoDias',
          'vigenciaMeses',
        ],
      ),
      cronogramaFisico: _text(map['cronogramaFisico']),
      criteriosMedicao: _text(map['criteriosMedicao']),
      criteriosAceite: _text(map['criteriosAceite']),
      indicadoresDesempenho: _text(map['indicadoresDesempenho']),
      obrigacoesContratada: _text(map['obrigacoesContratada']),
      obrigacoesContratante: _text(map['obrigacoesContratante']),
      equipeMinima: _text(map['equipeMinima']),
      fiscalNome: _text(map['fiscalNome']),
      fiscalUserId: map['fiscalUserId']?.toString(),
      gestorNome: _text(map['gestorNome']),
      gestorUserId: map['gestorUserId']?.toString(),
      licenciamentoAmbiental: _text(map['licenciamentoAmbiental']),
      segurancaTrabalho: _text(map['segurancaTrabalho']),
      sustentabilidade: _text(map['sustentabilidade']),
      estimativaValor: _text(map['estimativaValor']),
      reajusteIndice: _text(map['reajusteIndice']),
      condicoesPagamento: _text(map['condicoesPagamento']),
      garantia: _text(map['garantia']),
      matrizRiscos: _text(map['matrizRiscos']),
      penalidades: _text(map['penalidades']),
      demaisCondicoes: _text(map['demaisCondicoes']),
      linksDocumentos: _text(map['linksDocumentos']),
    );
  }

  factory TrData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final obj =
        sections[sectionObjetoFundamentacao] ?? const <String, dynamic>{};

    final esc =
        sections[sectionEscopoRequisitos] ?? const <String, dynamic>{};

    final loc =
        sections[sectionLocalPrazosCronograma] ?? const <String, dynamic>{};

    final med =
        sections[sectionMedicaoAceiteIndicadores] ??
            const <String, dynamic>{};

    final obr =
        sections[sectionObrigacoesEquipeGestao] ??
            const <String, dynamic>{};

    final lic =
        sections[sectionLicenciamentoSegurancaSustentabilidade] ??
            const <String, dynamic>{};

    final pre =
        sections[sectionPrecosPagamentoReajuste] ??
            const <String, dynamic>{};

    final ris =
        sections[sectionRiscosPenalidadesCondicoes] ??
            const <String, dynamic>{};

    final doc =
        sections[sectionDocumentosReferencias] ??
            const <String, dynamic>{};

    return TrData(
      objeto: _text(obj['objeto']),
      justificativa: _text(obj['justificativa']),
      tipoContratacao: _text(obj['tipoContratacao']),
      regimeExecucao: _text(obj['regimeExecucao']),
      escopoDetalhado: _text(esc['escopoDetalhado']),
      requisitosTecnicos: _text(esc['requisitosTecnicos']),
      especificacoesNormas: _text(esc['especificacoesNormas']),
      localExecucao: _text(loc['localExecucao']),
      prazoExecucaoDias: _text(loc['prazoExecucaoDias']),
      vigenciaDias: _firstText(
        loc,
        const <String>[
          'vigenciaDias',
          'vigenciaContratualDias',
          'vigenciaExecucaoDias',
          'vigenciaMeses',
        ],
      ),
      cronogramaFisico: _text(loc['cronogramaFisico']),
      criteriosMedicao: _text(med['criteriosMedicao']),
      criteriosAceite: _text(med['criteriosAceite']),
      indicadoresDesempenho: _text(med['indicadoresDesempenho']),
      obrigacoesContratada: _text(obr['obrigacoesContratada']),
      obrigacoesContratante: _text(obr['obrigacoesContratante']),
      equipeMinima: _text(obr['equipeMinima']),
      fiscalNome: _text(obr['fiscalNome']),
      fiscalUserId: obr['fiscalUserId']?.toString(),
      gestorNome: _text(obr['gestorNome']),
      gestorUserId: obr['gestorUserId']?.toString(),
      licenciamentoAmbiental: _text(lic['licenciamentoAmbiental']),
      segurancaTrabalho: _text(lic['segurancaTrabalho']),
      sustentabilidade: _text(lic['sustentabilidade']),
      estimativaValor: _text(pre['estimativaValor']),
      reajusteIndice: _text(pre['reajusteIndice']),
      condicoesPagamento: _text(pre['condicoesPagamento']),
      garantia: _text(pre['garantia']),
      matrizRiscos: _text(ris['matrizRiscos']),
      penalidades: _text(ris['penalidades']),
      demaisCondicoes: _text(ris['demaisCondicoes']),
      linksDocumentos: _text(doc['linksDocumentos']),
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionObjetoFundamentacao: <String, dynamic>{
        'objeto': objeto,
        'justificativa': justificativa,
        'tipoContratacao': tipoContratacao,
        'regimeExecucao': regimeExecucao,
      },
      sectionEscopoRequisitos: <String, dynamic>{
        'escopoDetalhado': escopoDetalhado,
        'requisitosTecnicos': requisitosTecnicos,
        'especificacoesNormas': especificacoesNormas,
      },
      sectionLocalPrazosCronograma: <String, dynamic>{
        'localExecucao': localExecucao,
        'prazoExecucaoDias': prazoExecucaoDias,
        'vigenciaDias': vigenciaDias,
        'cronogramaFisico': cronogramaFisico,
      },
      sectionMedicaoAceiteIndicadores: <String, dynamic>{
        'criteriosMedicao': criteriosMedicao,
        'criteriosAceite': criteriosAceite,
        'indicadoresDesempenho': indicadoresDesempenho,
      },
      sectionObrigacoesEquipeGestao: <String, dynamic>{
        'obrigacoesContratada': obrigacoesContratada,
        'obrigacoesContratante': obrigacoesContratante,
        'equipeMinima': equipeMinima,
        'fiscalNome': fiscalNome,
        'fiscalUserId': fiscalUserId,
        'gestorNome': gestorNome,
        'gestorUserId': gestorUserId,
      },
      sectionLicenciamentoSegurancaSustentabilidade: <String, dynamic>{
        'licenciamentoAmbiental': licenciamentoAmbiental,
        'segurancaTrabalho': segurancaTrabalho,
        'sustentabilidade': sustentabilidade,
      },
      sectionPrecosPagamentoReajuste: <String, dynamic>{
        'estimativaValor': estimativaValor,
        'reajusteIndice': reajusteIndice,
        'condicoesPagamento': condicoesPagamento,
        'garantia': garantia,
      },
      sectionRiscosPenalidadesCondicoes: <String, dynamic>{
        'matrizRiscos': matrizRiscos,
        'penalidades': penalidades,
        'demaisCondicoes': demaisCondicoes,
      },
      sectionDocumentosReferencias: <String, dynamic>{
        'linksDocumentos': linksDocumentos,
      },
    };
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
      especificacoesNormas:
      especificacoesNormas ?? this.especificacoesNormas,
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
  List<Object?> get props => <Object?>[
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