import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class EtpController extends ChangeNotifier {
  bool isEditable;

  // 1) Identificação / Metadados
  final etpNumeroCtrl = TextEditingController();
  final etpDataElaboracaoCtrl = TextEditingController();
  final etpResponsavelElaboracaoCtrl = TextEditingController(); // (Autocomplete fake)
  String? etpResponsavelElaboracaoUserId;
  final etpArtNumeroCtrl = TextEditingController();

  // 2) Motivação, objetivos e requisitos
  final etpMotivacaoCtrl = TextEditingController();
  final etpObjetivosCtrl = TextEditingController();
  final etpRequisitosMinimosCtrl = TextEditingController();

  // 3) Alternativas e solução recomendada (AGORA COM CONTROLLERS)
  final etpAlternativasAvaliadasCtrl = TextEditingController();
  final etpSolucaoRecomendadaCtrl = TextEditingController(); // DropDownButtonChange
  final etpComplexidadeCtrl = TextEditingController();        // DropDownButtonChange
  final etpNivelRiscoCtrl = TextEditingController();          // DropDownButtonChange
  final etpJustificativaSolucaoCtrl = TextEditingController();

  // 4) Mercado e estimativas
  final etpAnaliseMercadoCtrl = TextEditingController();
  final etpEstimativaValorCtrl = TextEditingController();
  final etpMetodoEstimativaCtrl = TextEditingController();    // DropDownButtonChange
  final etpBeneficiosEsperadosCtrl = TextEditingController();

  // 5) Cronograma, indicadores e aceite
  final etpPrazoExecucaoDiasCtrl = TextEditingController();
  final etpTempoVigenciaMesesCtrl = TextEditingController();
  final etpCriteriosAceiteCtrl = TextEditingController();
  final etpIndicadoresDesempenhoCtrl = TextEditingController();

  // 6) Premissas, restrições e licenciamento
  final etpPremissasCtrl = TextEditingController();
  final etpRestricoesCtrl = TextEditingController();
  final etpLicenciamentoAmbientalCtrl = TextEditingController(); // DropDownButtonChange
  final etpObservacoesAmbientaisCtrl = TextEditingController();

  // 7) Documentos, evidências e equipe
  final etpLevantamentosCampoCtrl = TextEditingController(); // DropDownButtonChange
  final etpProjetoExistenteCtrl = TextEditingController();   // DropDownButtonChange
  final etpLinksEvidenciasCtrl = TextEditingController();
  final etpEquipeEnvolvidaCtrl = TextEditingController();

  // 8) Conclusão
  final etpConclusaoCtrl = TextEditingController();

  EtpController({this.isEditable = true});

  void setEditable(bool v) { isEditable = v; notifyListeners(); }

  void initWithMock() {
    etpNumeroCtrl.text = 'ETP-2025-001';
    etpDataElaboracaoCtrl.text = '24/09/2025';
    etpResponsavelElaboracaoCtrl.text = 'Eng. Carla Menezes (uid:u1)';
    etpResponsavelElaboracaoUserId = 'u1';
    etpArtNumeroCtrl.text = 'AL-2025-123456';

    etpMotivacaoCtrl.text = 'Pavimento deteriorado e alta taxa de acidentes.';
    etpObjetivosCtrl.text = 'Restaurar pista, melhorar drenagem e sinalização.';
    etpRequisitosMinimosCtrl.text = 'CAP 50/70, CBUQ 5 cm, tachas, pintura termoplástica.';

    etpAlternativasAvaliadasCtrl.text = 'A1: Remendo + CBUQ; A2: Fresagem + reforço; A3: Reconstrução.';
    etpSolucaoRecomendadaCtrl.text = 'Obra de engenharia';
    etpComplexidadeCtrl.text = 'Média';
    etpNivelRiscoCtrl.text = 'Moderado';
    etpJustificativaSolucaoCtrl.text = 'Melhor custo-benefício considerando tráfego e vida útil.';

    etpAnaliseMercadoCtrl.text = '5 fornecedores regionais com capacidade instalada.';
    etpEstimativaValorCtrl.text = '8.750.000,00';
    etpMetodoEstimativaCtrl.text = 'SINAPI';
    etpBeneficiosEsperadosCtrl.text = 'Redução de 30% de acidentes e menor custo de manutenção.';

    etpPrazoExecucaoDiasCtrl.text = '150';
    etpTempoVigenciaMesesCtrl.text = '12';
    etpCriteriosAceiteCtrl.text = 'Deflectometria, macrotextura, retrorrefletância.';
    etpIndicadoresDesempenhoCtrl.text = 'IRI alvo, % segmentos conformes, prazos.';

    etpPremissasCtrl.text = 'Acesso às frentes, disponibilidade de CAP, clima estável.';
    etpRestricoesCtrl.text = 'Interferência com tráfego sazonal e feriados.';
    etpLicenciamentoAmbientalCtrl.text = 'A confirmar';
    etpObservacoesAmbientaisCtrl.text = 'Avaliar supressão vegetal pontual; condicionantes IMA.';

    etpLevantamentosCampoCtrl.text = 'Parcial';
    etpProjetoExistenteCtrl.text = 'Não';
    etpLinksEvidenciasCtrl.text = 'SEI:docs/123; Storage:etp/refs';
    etpEquipeEnvolvidaCtrl.text = 'Carla (Coord.), Pedro (Proj.), Ana (Orç.).';

    etpConclusaoCtrl.text = 'Prosseguir com TR e licitação em concorrência.';
    notifyListeners();
  }

  String? quickValidate() {
    if (etpNumeroCtrl.text.trim().isEmpty) return 'Informe o Nº do ETP.';
    if (etpDataElaboracaoCtrl.text.trim().isEmpty) return 'Informe a data de elaboração.';
    if (etpMotivacaoCtrl.text.trim().isEmpty) return 'Informe a motivação.';
    if (etpObjetivosCtrl.text.trim().isEmpty) return 'Informe os objetivos.';
    if (etpSolucaoRecomendadaCtrl.text.trim().isEmpty) return 'Selecione a solução recomendada.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    'numero': etpNumeroCtrl.text,
    'dataElaboracao': etpDataElaboracaoCtrl.text,
    'responsavelNome': etpResponsavelElaboracaoCtrl.text,
    'responsavelUserId': etpResponsavelElaboracaoUserId,
    'artNumero': etpArtNumeroCtrl.text,

    'motivacao': etpMotivacaoCtrl.text,
    'objetivos': etpObjetivosCtrl.text,
    'requisitosMinimos': etpRequisitosMinimosCtrl.text,

    'alternativas': etpAlternativasAvaliadasCtrl.text,
    'solucaoRecomendada': etpSolucaoRecomendadaCtrl.text,
    'complexidade': etpComplexidadeCtrl.text,
    'nivelRisco': etpNivelRiscoCtrl.text,
    'justificativaSolucao': etpJustificativaSolucaoCtrl.text,

    'analiseMercado': etpAnaliseMercadoCtrl.text,
    'estimativaValor': etpEstimativaValorCtrl.text,
    'metodoEstimativa': etpMetodoEstimativaCtrl.text,
    'beneficios': etpBeneficiosEsperadosCtrl.text,

    'prazoExecucaoDias': etpPrazoExecucaoDiasCtrl.text,
    'vigenciaMeses': etpTempoVigenciaMesesCtrl.text,
    'criteriosAceite': etpCriteriosAceiteCtrl.text,
    'indicadoresDesempenho': etpIndicadoresDesempenhoCtrl.text,

    'premissas': etpPremissasCtrl.text,
    'restricoes': etpRestricoesCtrl.text,
    'licenciamentoAmbiental': etpLicenciamentoAmbientalCtrl.text,
    'observacoesAmbientais': etpObservacoesAmbientaisCtrl.text,

    'levantamentosCampo': etpLevantamentosCampoCtrl.text,
    'projetoExistente': etpProjetoExistenteCtrl.text,
    'linksEvidencias': etpLinksEvidenciasCtrl.text,
    'equipe': etpEquipeEnvolvidaCtrl.text,

    'conclusao': etpConclusaoCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    etpNumeroCtrl.text = m['numero'] ?? '';
    etpDataElaboracaoCtrl.text = m['dataElaboracao'] ?? '';
    etpResponsavelElaboracaoCtrl.text = m['responsavelNome'] ?? '';
    etpResponsavelElaboracaoUserId = m['responsavelUserId'];
    etpArtNumeroCtrl.text = m['artNumero'] ?? '';

    etpMotivacaoCtrl.text = m['motivacao'] ?? '';
    etpObjetivosCtrl.text = m['objetivos'] ?? '';
    etpRequisitosMinimosCtrl.text = m['requisitosMinimos'] ?? '';

    etpAlternativasAvaliadasCtrl.text = m['alternativas'] ?? '';
    etpSolucaoRecomendadaCtrl.text = m['solucaoRecomendada'] ?? '';
    etpComplexidadeCtrl.text = m['complexidade'] ?? '';
    etpNivelRiscoCtrl.text = m['nivelRisco'] ?? '';
    etpJustificativaSolucaoCtrl.text = m['justificativaSolucao'] ?? '';

    etpAnaliseMercadoCtrl.text = m['analiseMercado'] ?? '';
    etpEstimativaValorCtrl.text = m['estimativaValor'] ?? '';
    etpMetodoEstimativaCtrl.text = m['metodoEstimativa'] ?? '';
    etpBeneficiosEsperadosCtrl.text = m['beneficios'] ?? '';

    etpPrazoExecucaoDiasCtrl.text = m['prazoExecucaoDias'] ?? '';
    etpTempoVigenciaMesesCtrl.text = m['vigenciaMeses'] ?? '';
    etpCriteriosAceiteCtrl.text = m['criteriosAceite'] ?? '';
    etpIndicadoresDesempenhoCtrl.text = m['indicadoresDesempenho'] ?? '';

    etpPremissasCtrl.text = m['premissas'] ?? '';
    etpRestricoesCtrl.text = m['restricoes'] ?? '';
    etpLicenciamentoAmbientalCtrl.text = m['licenciamentoAmbiental'] ?? '';
    etpObservacoesAmbientaisCtrl.text = m['observacoesAmbientais'] ?? '';

    etpLevantamentosCampoCtrl.text = m['levantamentosCampo'] ?? '';
    etpProjetoExistenteCtrl.text = m['projetoExistente'] ?? '';
    etpLinksEvidenciasCtrl.text = m['linksEvidencias'] ?? '';
    etpEquipeEnvolvidaCtrl.text = m['equipe'] ?? '';

    etpConclusaoCtrl.text = m['conclusao'] ?? '';
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      etpNumeroCtrl, etpDataElaboracaoCtrl, etpResponsavelElaboracaoCtrl, etpArtNumeroCtrl,
      etpMotivacaoCtrl, etpObjetivosCtrl, etpRequisitosMinimosCtrl,
      etpAlternativasAvaliadasCtrl, etpSolucaoRecomendadaCtrl, etpComplexidadeCtrl, etpNivelRiscoCtrl, etpJustificativaSolucaoCtrl,
      etpAnaliseMercadoCtrl, etpEstimativaValorCtrl, etpMetodoEstimativaCtrl, etpBeneficiosEsperadosCtrl,
      etpPrazoExecucaoDiasCtrl, etpTempoVigenciaMesesCtrl, etpCriteriosAceiteCtrl, etpIndicadoresDesempenhoCtrl,
      etpPremissasCtrl, etpRestricoesCtrl, etpLicenciamentoAmbientalCtrl, etpObservacoesAmbientaisCtrl,
      etpLevantamentosCampoCtrl, etpProjetoExistenteCtrl, etpLinksEvidenciasCtrl, etpEquipeEnvolvidaCtrl,
      etpConclusaoCtrl,
    ]) { ctrl.clear(); }
    etpResponsavelElaboracaoUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      etpNumeroCtrl, etpDataElaboracaoCtrl, etpResponsavelElaboracaoCtrl, etpArtNumeroCtrl,
      etpMotivacaoCtrl, etpObjetivosCtrl, etpRequisitosMinimosCtrl,
      etpAlternativasAvaliadasCtrl, etpSolucaoRecomendadaCtrl, etpComplexidadeCtrl, etpNivelRiscoCtrl, etpJustificativaSolucaoCtrl,
      etpAnaliseMercadoCtrl, etpEstimativaValorCtrl, etpMetodoEstimativaCtrl, etpBeneficiosEsperadosCtrl,
      etpPrazoExecucaoDiasCtrl, etpTempoVigenciaMesesCtrl, etpCriteriosAceiteCtrl, etpIndicadoresDesempenhoCtrl,
      etpPremissasCtrl, etpRestricoesCtrl, etpLicenciamentoAmbientalCtrl, etpObservacoesAmbientaisCtrl,
      etpLevantamentosCampoCtrl, etpProjetoExistenteCtrl, etpLinksEvidenciasCtrl, etpEquipeEnvolvidaCtrl,
      etpConclusaoCtrl,
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
