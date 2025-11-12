import 'package:flutter/material.dart';

class EtpController extends ChangeNotifier {
  // Estado
  bool isEditable;
  EtpController({this.isEditable = true});

  // =============== 1) Identificação / Metadados ===============
  final etpNumeroCtrl = TextEditingController();                // Nº ETP / ref interna
  final etpDataElaboracaoCtrl = TextEditingController();        // dd/mm/aaaa
  final etpResponsavelElaboracaoCtrl = TextEditingController(); // nome p/ UI
  String? etpResponsavelElaboracaoUserId;                       // id de usuário
  final etpArtNumeroCtrl = TextEditingController();             // Nº ART (opcional)

  // =============== 2) Motivação, objetivos e requisitos ===============
  final etpMotivacaoCtrl = TextEditingController();             // problema
  final etpObjetivosCtrl = TextEditingController();             // objetivos
  final etpRequisitosMinimosCtrl = TextEditingController();     // requisitos mínimos / escopo preliminar

  // =============== 3) Alternativas e solução recomendada ===============
  final etpSolucaoRecomendadaCtrl = TextEditingController();    // dropdown (salvamos label)
  final etpComplexidadeCtrl = TextEditingController();          // dropdown
  final etpNivelRiscoCtrl = TextEditingController();            // dropdown
  final etpJustificativaSolucaoCtrl = TextEditingController();  // justificativa

  // =============== 4) Mercado e estimativa ===============
  final etpAnaliseMercadoCtrl = TextEditingController();        // análise/fornecedores
  final etpEstimativaValorCtrl = TextEditingController();       // R$
  final etpMetodoEstimativaCtrl = TextEditingController();      // dropdown (SINAPI, etc.)
  final etpBeneficiosEsperadosCtrl = TextEditingController();   // benefícios

  // =============== 5) Cronograma, indicadores, aceite ===============
  final etpPrazoExecucaoDiasCtrl = TextEditingController();     // dias
  final etpTempoVigenciaMesesCtrl = TextEditingController();    // meses
  final etpCriteriosAceiteCtrl = TextEditingController();       // critérios de medição/aceite
  final etpIndicadoresDesempenhoCtrl = TextEditingController(); // indicadores

  // =============== 6) Premissas, restrições e licenciamento ===============
  final etpPremissasCtrl = TextEditingController();             // premissas
  final etpRestricoesCtrl = TextEditingController();            // restrições
  final etpLicenciamentoAmbientalCtrl = TextEditingController();// dropdown (Sim/Não/…)
  final etpObservacoesAmbientaisCtrl = TextEditingController(); // observações ambientais

  // =============== 7) Documentos, evidências e equipe ===============
  final etpLevantamentosCampoCtrl = TextEditingController();    // dropdown (Sim/Não/…)
  final etpProjetoExistenteCtrl = TextEditingController();      // dropdown (Sim/Não/…)
  final etpLinksEvidenciasCtrl = TextEditingController();       // links/evidências
  final etpEquipeEnvolvidaCtrl = TextEditingController();       // nomes/cargos

  // =============== 8) Conclusão ===============
  final etpConclusaoCtrl = TextEditingController();

  // ───────────────────────── helpers ─────────────────────────
  bool _looksUid(String? v) =>
      v != null && v.trim().length >= 20 && !v.contains(' ');

  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  // ────────────────────── (de)serialização ──────────────────────
  /// Mapa por seção -> subcoleções `etp/{id}/{secao}/{docId}`
  Map<String, Map<String, dynamic>> toSectionMaps() => {
    'identificacao': {
      'numero': etpNumeroCtrl.text,
      'dataElaboracao': etpDataElaboracaoCtrl.text,
      'responsavelNome': etpResponsavelElaboracaoCtrl.text,
      'responsavelUserId': etpResponsavelElaboracaoUserId,
      'artNumero': etpArtNumeroCtrl.text,
    },
    'motivacao': {
      'motivacao': etpMotivacaoCtrl.text,
      'objetivos': etpObjetivosCtrl.text,
      'requisitosMinimos': etpRequisitosMinimosCtrl.text,
    },
    'alternativas': {
      'solucaoRecomendada': etpSolucaoRecomendadaCtrl.text,
      'complexidade': etpComplexidadeCtrl.text,
      'nivelRisco': etpNivelRiscoCtrl.text,
      'justificativaSolucao': etpJustificativaSolucaoCtrl.text,
    },
    'mercado': {
      'analiseMercado': etpAnaliseMercadoCtrl.text,
      'estimativaValor': etpEstimativaValorCtrl.text,
      'metodoEstimativa': etpMetodoEstimativaCtrl.text,
      'beneficiosEsperados': etpBeneficiosEsperadosCtrl.text,
    },
    'cronograma': {
      'prazoExecucaoDias': etpPrazoExecucaoDiasCtrl.text,
      'tempoVigenciaMeses': etpTempoVigenciaMesesCtrl.text,
      'criteriosAceite': etpCriteriosAceiteCtrl.text,
      'indicadoresDesempenho': etpIndicadoresDesempenhoCtrl.text,
    },
    'premissas': {
      'premissas': etpPremissasCtrl.text,
      'restricoes': etpRestricoesCtrl.text,
      'licenciamentoAmbiental': etpLicenciamentoAmbientalCtrl.text,
      'observacoesAmbientais': etpObservacoesAmbientaisCtrl.text,
    },
    'documentos': {
      'levantamentosCampo': etpLevantamentosCampoCtrl.text,
      'projetoExistente': etpProjetoExistenteCtrl.text,
      'linksEvidencias': etpLinksEvidenciasCtrl.text,
      'equipeEnvolvida': etpEquipeEnvolvidaCtrl.text,
    },
    'conclusao': {
      'conclusao': etpConclusaoCtrl.text,
    },
  };

  /// Preenche a partir de {secao: map}. Ausentes limpam os campos.
  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    // 1) Identificação
    final id = sections['identificacao'] ?? const {};
    etpNumeroCtrl.text = id['numero'] ?? '';
    etpDataElaboracaoCtrl.text = id['dataElaboracao'] ?? '';
    etpResponsavelElaboracaoUserId =
        id['responsavelUserId'] ?? (_looksUid(id['responsavelNome']) ? id['responsavelNome'] : null);
    etpResponsavelElaboracaoCtrl.text =
    _looksUid(id['responsavelNome']) ? '' : (id['responsavelNome'] ?? '');
    etpArtNumeroCtrl.text = id['artNumero'] ?? '';

    // 2) Motivação/objetivos/requisitos
    final mot = sections['motivacao'] ?? const {};
    etpMotivacaoCtrl.text = mot['motivacao'] ?? '';
    etpObjetivosCtrl.text = mot['objetivos'] ?? '';
    etpRequisitosMinimosCtrl.text = mot['requisitosMinimos'] ?? '';

    // 3) Alternativas
    final alt = sections['alternativas'] ?? const {};
    etpSolucaoRecomendadaCtrl.text = alt['solucaoRecomendada'] ?? '';
    etpComplexidadeCtrl.text = alt['complexidade'] ?? '';
    etpNivelRiscoCtrl.text = alt['nivelRisco'] ?? '';
    etpJustificativaSolucaoCtrl.text = alt['justificativaSolucao'] ?? '';

    // 4) Mercado
    final mer = sections['mercado'] ?? const {};
    etpAnaliseMercadoCtrl.text = mer['analiseMercado'] ?? '';
    etpEstimativaValorCtrl.text = mer['estimativaValor'] ?? '';
    etpMetodoEstimativaCtrl.text = mer['metodoEstimativa'] ?? '';
    etpBeneficiosEsperadosCtrl.text = mer['beneficiosEsperados'] ?? '';

    // 5) Cronograma
    final cro = sections['cronograma'] ?? const {};
    etpPrazoExecucaoDiasCtrl.text = cro['prazoExecucaoDias'] ?? '';
    etpTempoVigenciaMesesCtrl.text = cro['tempoVigenciaMeses'] ?? '';
    etpCriteriosAceiteCtrl.text = cro['criteriosAceite'] ?? '';
    etpIndicadoresDesempenhoCtrl.text = cro['indicadoresDesempenho'] ?? '';

    // 6) Premissas
    final pre = sections['premissas'] ?? const {};
    etpPremissasCtrl.text = pre['premissas'] ?? '';
    etpRestricoesCtrl.text = pre['restricoes'] ?? '';
    etpLicenciamentoAmbientalCtrl.text = pre['licenciamentoAmbiental'] ?? '';
    etpObservacoesAmbientaisCtrl.text = pre['observacoesAmbientais'] ?? '';

    // 7) Documentos
    final doc = sections['documentos'] ?? const {};
    etpLevantamentosCampoCtrl.text = doc['levantamentosCampo'] ?? '';
    etpProjetoExistenteCtrl.text = doc['projetoExistente'] ?? '';
    etpLinksEvidenciasCtrl.text = doc['linksEvidencias'] ?? '';
    etpEquipeEnvolvidaCtrl.text = doc['equipeEnvolvida'] ?? '';

    // 8) Conclusão
    final con = sections['conclusao'] ?? const {};
    etpConclusaoCtrl.text = con['conclusao'] ?? '';

    notifyListeners();
  }

  // ───────────────────────── validação ─────────────────────────
  String? quickValidate() {
    if (etpNumeroCtrl.text.trim().isEmpty) {
      return 'Informe o Nº do ETP / referência interna.';
    }
    if (etpDataElaboracaoCtrl.text.trim().isEmpty) {
      return 'Informe a data de elaboração.';
    }
    if ((etpResponsavelElaboracaoUserId == null ||
        etpResponsavelElaboracaoUserId!.isEmpty) &&
        etpResponsavelElaboracaoCtrl.text.trim().isEmpty) {
      return 'Selecione o responsável técnico.';
    }
    if (etpMotivacaoCtrl.text.trim().isEmpty) {
      return 'Informe a motivação.';
    }
    if (etpObjetivosCtrl.text.trim().isEmpty) {
      return 'Informe os objetivos.';
    }
    if (etpSolucaoRecomendadaCtrl.text.trim().isEmpty) {
      return 'Selecione a solução recomendada.';
    }
    if (etpComplexidadeCtrl.text.trim().isEmpty) {
      return 'Selecione a complexidade.';
    }
    if (etpNivelRiscoCtrl.text.trim().isEmpty) {
      return 'Selecione o risco preliminar.';
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      etpNumeroCtrl,
      etpDataElaboracaoCtrl,
      etpResponsavelElaboracaoCtrl,
      etpArtNumeroCtrl,
      etpMotivacaoCtrl,
      etpObjetivosCtrl,
      etpRequisitosMinimosCtrl,
      etpSolucaoRecomendadaCtrl,
      etpComplexidadeCtrl,
      etpNivelRiscoCtrl,
      etpJustificativaSolucaoCtrl,
      etpAnaliseMercadoCtrl,
      etpEstimativaValorCtrl,
      etpMetodoEstimativaCtrl,
      etpBeneficiosEsperadosCtrl,
      etpPrazoExecucaoDiasCtrl,
      etpTempoVigenciaMesesCtrl,
      etpCriteriosAceiteCtrl,
      etpIndicadoresDesempenhoCtrl,
      etpPremissasCtrl,
      etpRestricoesCtrl,
      etpLicenciamentoAmbientalCtrl,
      etpObservacoesAmbientaisCtrl,
      etpLevantamentosCampoCtrl,
      etpProjetoExistenteCtrl,
      etpLinksEvidenciasCtrl,
      etpEquipeEnvolvidaCtrl,
      etpConclusaoCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }
}
