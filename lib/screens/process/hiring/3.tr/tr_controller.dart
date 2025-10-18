import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para o Termo de Referência (TR).
/// - Sem Firebase.
/// - Usa TextEditingController para TUDO (incluindo dropdowns com DropDownButtonChange).
class TrController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Objeto e Fundamentação
  final trObjetoCtrl = TextEditingController();
  final trJustificativaCtrl = TextEditingController();
  final trTipoContratacaoCtrl = TextEditingController(); // DropDown
  final trRegimeExecucaoCtrl = TextEditingController();  // DropDown

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
  final trEquipeMinimaCtrl = TextEditingController(); // DropDown
  final trFiscalCtrl = TextEditingController(); // AutocompleteUserClass (fake)
  String? trFiscalUserId;
  final trGestorCtrl = TextEditingController(); // AutocompleteUserClass (fake)
  String? trGestorUserId;

  // 6) Licenciamento / Segurança / Sustentabilidade
  final trLicenciamentoAmbientalCtrl = TextEditingController(); // DropDown
  final trSegurancaTrabalhoCtrl = TextEditingController();
  final trSustentabilidadeCtrl = TextEditingController();

  // 7) Preços / Pagamento / Reajuste / Garantia
  final trEstimativaValorCtrl = TextEditingController();
  final trReajusteIndiceCtrl = TextEditingController(); // DropDown
  final trCondicoesPagamentoCtrl = TextEditingController();
  final trGarantiaCtrl = TextEditingController(); // DropDown

  // 8) Riscos / Penalidades / Demais
  final trMatrizRiscosCtrl = TextEditingController();
  final trPenalidadesCtrl = TextEditingController();
  final trDemaisCondicoesCtrl = TextEditingController();

  // 9) Documentos / Referências
  final trLinksDocumentosCtrl = TextEditingController();

  void initWithMock() {
    trObjetoCtrl.text = 'Restauração do pavimento e melhoria da sinalização na AL-101.';
    trJustificativaCtrl.text = 'Condições de trafegabilidade e segurança comprometidas.';
    trTipoContratacaoCtrl.text = 'Obra de engenharia';
    trRegimeExecucaoCtrl.text = 'Preço global';

    trEscopoDetalhadoCtrl.text = 'Fresagem, recomposição CBUQ 5 cm, drenagem, tachas, pintura termoplástica.';
    trRequisitosTecnicosCtrl.text = 'CAP 50/70, granulometria DNIT, controle tecnológico.';
    trEspecificacoesNormasCtrl.text = 'ABNT NBR 12895; DNIT 031/2006; Manual de sinalização horizontal IET.';

    trLocalExecucaoCtrl.text = 'AL-101 SUL, km 0 ao km 12,5 — Maceió/AL.';
    trPrazoExecucaoDiasCtrl.text = '180';
    trVigenciaMesesCtrl.text = '12';
    trCronogramaFisicoCtrl.text = 'M1 mobilização; M2 fresagem; M3 CBUQ; M4 sinalização; M5 entrega.';

    trCriteriosMedicaoCtrl.text = 'Por boletim, com base em quantitativos executados.';
    trCriteriosAceiteCtrl.text = 'IRI, macrotextura e retrorrefletância dentro das faixas.';
    trIndicadoresDesempenhoCtrl.text = '≥95% segmentos conformes; prazos de marcos cumpridos.';

    trObrigacoesContratadaCtrl.text = 'Mobilizar equipe, equipamentos, EPI/EPC, limpeza da via.';
    trObrigacoesContratanteCtrl.text = 'Fiscalizar, emitir ordens de serviço, medir e pagar.';
    trEquipeMinimaCtrl.text = 'Eng. civil + encarregado + laboratório';
    trFiscalCtrl.text = 'João da Silva (uid:abc)'; trFiscalUserId = 'abc';
    trGestorCtrl.text = 'Maria Souza (uid:def)'; trGestorUserId = 'def';

    trLicenciamentoAmbientalCtrl.text = 'A confirmar';
    trSegurancaTrabalhoCtrl.text = 'Sinalização conforme Manual DNIT; plano de segurança.';
    trSustentabilidadeCtrl.text = 'Destinação correta de resíduos; acessibilidade em desvios.';

    trEstimativaValorCtrl.text = '12.500.000,00';
    trReajusteIndiceCtrl.text = 'IPCA';
    trCondicoesPagamentoCtrl.text = 'Medições mensais; pagamento em 30 dias.';
    trGarantiaCtrl.text = 'Seguro-garantia';

    trMatrizRiscosCtrl.text = 'Chuvas intensas; interferências de terceiros; preço CAP.';
    trPenalidadesCtrl.text = 'Advertência, multa, suspensão conforme Lei 14.133/2021.';
    trDemaisCondicoesCtrl.text = 'Visita técnica opcional; seguro de obras obrigatório; interface com concessionárias.';

    trLinksDocumentosCtrl.text = 'SEI: 64000.000000/2025-11; Projeto: /storage/projetos/al101';

    notifyListeners();
  }

  String? quickValidate() {
    if (trObjetoCtrl.text.trim().isEmpty) return 'Informe o objeto.';
    if (trJustificativaCtrl.text.trim().isEmpty) return 'Informe a justificativa técnica.';
    if (trTipoContratacaoCtrl.text.trim().isEmpty) return 'Selecione o tipo de contratação.';
    if (trRegimeExecucaoCtrl.text.trim().isEmpty) return 'Selecione o regime de execução.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    'objeto': trObjetoCtrl.text,
    'justificativa': trJustificativaCtrl.text,
    'tipoContratacao': trTipoContratacaoCtrl.text,
    'regimeExecucao': trRegimeExecucaoCtrl.text,

    'escopoDetalhado': trEscopoDetalhadoCtrl.text,
    'requisitosTecnicos': trRequisitosTecnicosCtrl.text,
    'especificacoesNormas': trEspecificacoesNormasCtrl.text,

    'localExecucao': trLocalExecucaoCtrl.text,
    'prazoExecucaoDias': trPrazoExecucaoDiasCtrl.text,
    'vigenciaMeses': trVigenciaMesesCtrl.text,
    'cronogramaFisico': trCronogramaFisicoCtrl.text,

    'criteriosMedicao': trCriteriosMedicaoCtrl.text,
    'criteriosAceite': trCriteriosAceiteCtrl.text,
    'indicadoresDesempenho': trIndicadoresDesempenhoCtrl.text,

    'obrigacoesContratada': trObrigacoesContratadaCtrl.text,
    'obrigacoesContratante': trObrigacoesContratanteCtrl.text,
    'equipeMinima': trEquipeMinimaCtrl.text,
    'fiscalNome': trFiscalCtrl.text,
    'fiscalUserId': trFiscalUserId,
    'gestorNome': trGestorCtrl.text,
    'gestorUserId': trGestorUserId,

    'licenciamentoAmbiental': trLicenciamentoAmbientalCtrl.text,
    'segurancaTrabalho': trSegurancaTrabalhoCtrl.text,
    'sustentabilidade': trSustentabilidadeCtrl.text,

    'estimativaValor': trEstimativaValorCtrl.text,
    'reajusteIndice': trReajusteIndiceCtrl.text,
    'condicoesPagamento': trCondicoesPagamentoCtrl.text,
    'garantia': trGarantiaCtrl.text,

    'matrizRiscos': trMatrizRiscosCtrl.text,
    'penalidades': trPenalidadesCtrl.text,
    'demaisCondicoes': trDemaisCondicoesCtrl.text,

    'linksDocumentos': trLinksDocumentosCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    trObjetoCtrl.text = m['objeto'] ?? '';
    trJustificativaCtrl.text = m['justificativa'] ?? '';
    trTipoContratacaoCtrl.text = m['tipoContratacao'] ?? '';
    trRegimeExecucaoCtrl.text = m['regimeExecucao'] ?? '';

    trEscopoDetalhadoCtrl.text = m['escopoDetalhado'] ?? '';
    trRequisitosTecnicosCtrl.text = m['requisitosTecnicos'] ?? '';
    trEspecificacoesNormasCtrl.text = m['especificacoesNormas'] ?? '';

    trLocalExecucaoCtrl.text = m['localExecucao'] ?? '';
    trPrazoExecucaoDiasCtrl.text = m['prazoExecucaoDias'] ?? '';
    trVigenciaMesesCtrl.text = m['vigenciaMeses'] ?? '';
    trCronogramaFisicoCtrl.text = m['cronogramaFisico'] ?? '';

    trCriteriosMedicaoCtrl.text = m['criteriosMedicao'] ?? '';
    trCriteriosAceiteCtrl.text = m['criteriosAceite'] ?? '';
    trIndicadoresDesempenhoCtrl.text = m['indicadoresDesempenho'] ?? '';

    trObrigacoesContratadaCtrl.text = m['obrigacoesContratada'] ?? '';
    trObrigacoesContratanteCtrl.text = m['obrigacoesContratante'] ?? '';
    trEquipeMinimaCtrl.text = m['equipeMinima'] ?? '';
    trFiscalCtrl.text = m['fiscalNome'] ?? '';
    trFiscalUserId = m['fiscalUserId'];
    trGestorCtrl.text = m['gestorNome'] ?? '';
    trGestorUserId = m['gestorUserId'];

    trLicenciamentoAmbientalCtrl.text = m['licenciamentoAmbiental'] ?? '';
    trSegurancaTrabalhoCtrl.text = m['segurancaTrabalho'] ?? '';
    trSustentabilidadeCtrl.text = m['sustentabilidade'] ?? '';

    trEstimativaValorCtrl.text = m['estimativaValor'] ?? '';
    trReajusteIndiceCtrl.text = m['reajusteIndice'] ?? '';
    trCondicoesPagamentoCtrl.text = m['condicoesPagamento'] ?? '';
    trGarantiaCtrl.text = m['garantia'] ?? '';

    trMatrizRiscosCtrl.text = m['matrizRiscos'] ?? '';
    trPenalidadesCtrl.text = m['penalidades'] ?? '';
    trDemaisCondicoesCtrl.text = m['demaisCondicoes'] ?? '';

    trLinksDocumentosCtrl.text = m['linksDocumentos'] ?? '';
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
    ]) { ctrl.clear(); }
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
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
