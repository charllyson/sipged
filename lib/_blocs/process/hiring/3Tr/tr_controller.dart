import 'package:flutter/material.dart';
import 'tr_sections.dart';

class TrController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Objeto e Fundamentação
  final trObjetoCtrl = TextEditingController();
  final trJustificativaCtrl = TextEditingController();
  final trTipoContratacaoCtrl = TextEditingController();
  final trRegimeExecucaoCtrl = TextEditingController();

  // 2) Escopo / Requisitos
  final trEscopoDetalhadoCtrl = TextEditingController();
  final trRequisitosTecnicosCtrl = TextEditingController();
  final trEspecificacoesNormasCtrl = TextEditingController();

  // 3) Local / Prazos / Cronograma
  final trLocalExecucaoCtrl = TextEditingController();
  final trPrazoExecucaoDiasCtrl = TextEditingController();
  final trVigenciaMesesCtrl = TextEditingController();
  final trCronogramaFisicoCtrl = TextEditingController();

  // 4) Medição / Aceite / Indicadores
  final trCriteriosMedicaoCtrl = TextEditingController();
  final trCriteriosAceiteCtrl = TextEditingController();
  final trIndicadoresDesempenhoCtrl = TextEditingController();

  // 5) Obrigações / Equipe / Gestão
  final trObrigacoesContratadaCtrl = TextEditingController();
  final trObrigacoesContratanteCtrl = TextEditingController();
  final trEquipeMinimaCtrl = TextEditingController();
  final trFiscalCtrl = TextEditingController();
  String? trFiscalUserId;
  final trGestorCtrl = TextEditingController();
  String? trGestorUserId;

  // 6) Licenciamento / Segurança / Sustentabilidade
  final trLicenciamentoAmbientalCtrl = TextEditingController();
  final trSegurancaTrabalhoCtrl = TextEditingController();
  final trSustentabilidadeCtrl = TextEditingController();

  // 7) Preços / Pagamento / Reajuste / Garantia
  final trEstimativaValorCtrl = TextEditingController();
  final trReajusteIndiceCtrl = TextEditingController();
  final trCondicoesPagamentoCtrl = TextEditingController();
  final trGarantiaCtrl = TextEditingController();

  // 8) Riscos / Penalidades / Demais
  final trMatrizRiscosCtrl = TextEditingController();
  final trPenalidadesCtrl = TextEditingController();
  final trDemaisCondicoesCtrl = TextEditingController();

  // 9) Documentos / Referências
  final trLinksDocumentosCtrl = TextEditingController();

  // ───────────── helpers ─────────────
  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  String? quickValidate() {
    if (trObjetoCtrl.text.trim().isEmpty) return 'Informe o objeto.';
    if (trJustificativaCtrl.text.trim().isEmpty) return 'Informe a justificativa técnica.';
    if (trTipoContratacaoCtrl.text.trim().isEmpty) return 'Selecione o tipo de contratação.';
    if (trRegimeExecucaoCtrl.text.trim().isEmpty) return 'Selecione o regime de execução.';
    return null;
  }

  // ───────── (de)serialização POR SEÇÃO ─────────
  Map<String, Map<String, dynamic>> toSectionMaps() => {
    TrSections.objetoFundamentacao: {
      'objeto': trObjetoCtrl.text,
      'justificativa': trJustificativaCtrl.text,
      'tipoContratacao': trTipoContratacaoCtrl.text,
      'regimeExecucao': trRegimeExecucaoCtrl.text,
    },
    TrSections.escopoRequisitos: {
      'escopoDetalhado': trEscopoDetalhadoCtrl.text,
      'requisitosTecnicos': trRequisitosTecnicosCtrl.text,
      'especificacoesNormas': trEspecificacoesNormasCtrl.text,
    },
    TrSections.localPrazosCronograma: {
      'localExecucao': trLocalExecucaoCtrl.text,
      'prazoExecucaoDias': trPrazoExecucaoDiasCtrl.text,
      'vigenciaMeses': trVigenciaMesesCtrl.text,
      'cronogramaFisico': trCronogramaFisicoCtrl.text,
    },
    TrSections.medicaoAceiteIndicadores: {
      'criteriosMedicao': trCriteriosMedicaoCtrl.text,
      'criteriosAceite': trCriteriosAceiteCtrl.text,
      'indicadoresDesempenho': trIndicadoresDesempenhoCtrl.text,
    },
    TrSections.obrigacoesEquipeGestao: {
      'obrigacoesContratada': trObrigacoesContratadaCtrl.text,
      'obrigacoesContratante': trObrigacoesContratanteCtrl.text,
      'equipeMinima': trEquipeMinimaCtrl.text,
      'fiscalNome': trFiscalCtrl.text,
      'fiscalUserId': trFiscalUserId,
      'gestorNome': trGestorCtrl.text,
      'gestorUserId': trGestorUserId,
    },
    TrSections.licenciamentoSegurancaSustentabilidade: {
      'licenciamentoAmbiental': trLicenciamentoAmbientalCtrl.text,
      'segurancaTrabalho': trSegurancaTrabalhoCtrl.text,
      'sustentabilidade': trSustentabilidadeCtrl.text,
    },
    TrSections.precosPagamentoReajuste: {
      'estimativaValor': trEstimativaValorCtrl.text,
      'reajusteIndice': trReajusteIndiceCtrl.text,
      'condicoesPagamento': trCondicoesPagamentoCtrl.text,
      'garantia': trGarantiaCtrl.text,
    },
    TrSections.riscosPenalidadesCondicoes: {
      'matrizRiscos': trMatrizRiscosCtrl.text,
      'penalidades': trPenalidadesCtrl.text,
      'demaisCondicoes': trDemaisCondicoesCtrl.text,
    },
    TrSections.documentosReferencias: {
      'linksDocumentos': trLinksDocumentosCtrl.text,
    },
  };

  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    String get(String sec, String key) => sections[sec]?[key]?.toString() ?? '';

    // 1) Objeto e Fundamentação
    trObjetoCtrl.text = get(TrSections.objetoFundamentacao, 'objeto');
    trJustificativaCtrl.text = get(TrSections.objetoFundamentacao, 'justificativa');
    trTipoContratacaoCtrl.text = get(TrSections.objetoFundamentacao, 'tipoContratacao');
    trRegimeExecucaoCtrl.text = get(TrSections.objetoFundamentacao, 'regimeExecucao');

    // 2) Escopo / Requisitos
    trEscopoDetalhadoCtrl.text = get(TrSections.escopoRequisitos, 'escopoDetalhado');
    trRequisitosTecnicosCtrl.text = get(TrSections.escopoRequisitos, 'requisitosTecnicos');
    trEspecificacoesNormasCtrl.text = get(TrSections.escopoRequisitos, 'especificacoesNormas');

    // 3) Local / Prazos / Cronograma
    trLocalExecucaoCtrl.text = get(TrSections.localPrazosCronograma, 'localExecucao');
    trPrazoExecucaoDiasCtrl.text = get(TrSections.localPrazosCronograma, 'prazoExecucaoDias');
    trVigenciaMesesCtrl.text = get(TrSections.localPrazosCronograma, 'vigenciaMeses');
    trCronogramaFisicoCtrl.text = get(TrSections.localPrazosCronograma, 'cronogramaFisico');

    // 4) Medição / Aceite / Indicadores
    trCriteriosMedicaoCtrl.text = get(TrSections.medicaoAceiteIndicadores, 'criteriosMedicao');
    trCriteriosAceiteCtrl.text = get(TrSections.medicaoAceiteIndicadores, 'criteriosAceite');
    trIndicadoresDesempenhoCtrl.text = get(TrSections.medicaoAceiteIndicadores, 'indicadoresDesempenho');

    // 5) Obrigações / Equipe / Gestão
    trObrigacoesContratadaCtrl.text = get(TrSections.obrigacoesEquipeGestao, 'obrigacoesContratada');
    trObrigacoesContratanteCtrl.text = get(TrSections.obrigacoesEquipeGestao, 'obrigacoesContratante');
    trEquipeMinimaCtrl.text = get(TrSections.obrigacoesEquipeGestao, 'equipeMinima');
    trFiscalCtrl.text = get(TrSections.obrigacoesEquipeGestao, 'fiscalNome');
    trFiscalUserId = sections[TrSections.obrigacoesEquipeGestao]?['fiscalUserId'];
    trGestorCtrl.text = get(TrSections.obrigacoesEquipeGestao, 'gestorNome');
    trGestorUserId = sections[TrSections.obrigacoesEquipeGestao]?['gestorUserId'];

    // 6) Licenciamento / Segurança / Sustentabilidade
    trLicenciamentoAmbientalCtrl.text = get(TrSections.licenciamentoSegurancaSustentabilidade, 'licenciamentoAmbiental');
    trSegurancaTrabalhoCtrl.text = get(TrSections.licenciamentoSegurancaSustentabilidade, 'segurancaTrabalho');
    trSustentabilidadeCtrl.text = get(TrSections.licenciamentoSegurancaSustentabilidade, 'sustentabilidade');

    // 7) Preços / Pagamento / Reajuste / Garantia
    trEstimativaValorCtrl.text = get(TrSections.precosPagamentoReajuste, 'estimativaValor');
    trReajusteIndiceCtrl.text = get(TrSections.precosPagamentoReajuste, 'reajusteIndice');
    trCondicoesPagamentoCtrl.text = get(TrSections.precosPagamentoReajuste, 'condicoesPagamento');
    trGarantiaCtrl.text = get(TrSections.precosPagamentoReajuste, 'garantia');

    // 8) Riscos / Penalidades / Demais
    trMatrizRiscosCtrl.text = get(TrSections.riscosPenalidadesCondicoes, 'matrizRiscos');
    trPenalidadesCtrl.text = get(TrSections.riscosPenalidadesCondicoes, 'penalidades');
    trDemaisCondicoesCtrl.text = get(TrSections.riscosPenalidadesCondicoes, 'demaisCondicoes');

    // 9) Documentos / Referências
    trLinksDocumentosCtrl.text = get(TrSections.documentosReferencias, 'linksDocumentos');

    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      trObjetoCtrl, trJustificativaCtrl, trTipoContratacaoCtrl, trRegimeExecucaoCtrl,
      trEscopoDetalhadoCtrl, trRequisitosTecnicosCtrl, trEspecificacoesNormasCtrl,
      trLocalExecucaoCtrl, trPrazoExecucaoDiasCtrl, trVigenciaMesesCtrl, trCronogramaFisicoCtrl,
      trCriteriosMedicaoCtrl, trCriteriosAceiteCtrl, trIndicadoresDesempenhoCtrl,
      trObrigacoesContratadaCtrl, trObrigacoesContratanteCtrl, trEquipeMinimaCtrl,
      trFiscalCtrl, trGestorCtrl,
      trLicenciamentoAmbientalCtrl, trSegurancaTrabalhoCtrl, trSustentabilidadeCtrl,
      trEstimativaValorCtrl, trReajusteIndiceCtrl, trCondicoesPagamentoCtrl, trGarantiaCtrl,
      trMatrizRiscosCtrl, trPenalidadesCtrl, trDemaisCondicoesCtrl,
      trLinksDocumentosCtrl,
    ]) {
      ctrl.clear();
    }
    trFiscalUserId = null;
    trGestorUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      trObjetoCtrl, trJustificativaCtrl, trTipoContratacaoCtrl, trRegimeExecucaoCtrl,
      trEscopoDetalhadoCtrl, trRequisitosTecnicosCtrl, trEspecificacoesNormasCtrl,
      trLocalExecucaoCtrl, trPrazoExecucaoDiasCtrl, trVigenciaMesesCtrl, trCronogramaFisicoCtrl,
      trCriteriosMedicaoCtrl, trCriteriosAceiteCtrl, trIndicadoresDesempenhoCtrl,
      trObrigacoesContratadaCtrl, trObrigacoesContratanteCtrl, trEquipeMinimaCtrl,
      trFiscalCtrl, trGestorCtrl,
      trLicenciamentoAmbientalCtrl, trSegurancaTrabalhoCtrl, trSustentabilidadeCtrl,
      trEstimativaValorCtrl, trReajusteIndiceCtrl, trCondicoesPagamentoCtrl, trGarantiaCtrl,
      trMatrizRiscosCtrl, trPenalidadesCtrl, trDemaisCondicoesCtrl,
      trLinksDocumentosCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }
}
