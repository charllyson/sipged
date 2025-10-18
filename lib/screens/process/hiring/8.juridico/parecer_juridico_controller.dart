import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para Parecer Jurídico.
/// Dropdowns também usam TextEditingController (compatível com DropDownButtonChange).
class ParecerJuridicoController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Metadados
  final pjNumeroCtrl = TextEditingController();
  final pjDataCtrl = TextEditingController();
  final pjOrgaoJuridicoCtrl = TextEditingController();
  final pjPareceristaCtrl = TextEditingController(); // Autocomplete fake
  String? pjPareceristaUserId;

  // 2) Documentos analisados
  final pjRefProcessoCtrl = TextEditingController();
  final pjDocumentosExaminadosCtrl = TextEditingController();
  final pjLinksAnexosCtrl = TextEditingController();

  // 3) Análise de conformidade (checklist)
  final chkCompetenciaMotivacaoCtrl = TextEditingController(); // DropDown
  final obsCompetenciaMotivacaoCtrl = TextEditingController();

  final chkEstimativaDotacaoCtrl = TextEditingController(); // DropDown
  final obsEstimativaDotacaoCtrl = TextEditingController();

  final chkModalidadeRegimeCtrl = TextEditingController(); // DropDown
  final obsModalidadeRegimeCtrl = TextEditingController();

  final chkHabilitacaoCtrl = TextEditingController(); // DropDown
  final obsHabilitacaoCtrl = TextEditingController();

  final chkClausulasEssenciaisCtrl = TextEditingController(); // DropDown
  final obsClausulasEssenciaisCtrl = TextEditingController();

  final chkMatrizRiscosCtrl = TextEditingController(); // DropDown
  final obsMatrizRiscosCtrl = TextEditingController();

  // 4) Conclusão
  final pjConclusaoCtrl = TextEditingController(); // DropDown
  final pjDataAssinaturaCtrl = TextEditingController();
  final pjRecomendacoesCtrl = TextEditingController();
  final pjAjustesObrigatoriosCtrl = TextEditingController();

  // 5) Pendências
  final pendenciaDescricaoCtrl = TextEditingController();
  final pendenciaPrazoCtrl = TextEditingController();
  final pendenciaResponsavelCtrl = TextEditingController();

  // 6) Assinaturas
  final pjAutoridadeCtrl = TextEditingController(); // Autocomplete fake
  String? pjAutoridadeUserId;
  final pjLocalCtrl = TextEditingController();
  final pjObservacoesFinaisCtrl = TextEditingController();

  void initWithMock() {
    pjNumeroCtrl.text = 'PJ-2025-042';
    pjDataCtrl.text = '24/09/2025';
    pjOrgaoJuridicoCtrl.text = 'AJUR/DER-AL';
    pjPareceristaCtrl.text = 'Dra. Helena Lins (uid:j1)';
    pjPareceristaUserId = 'j1';

    pjRefProcessoCtrl.text = 'SEI 64000.000000/2025-11';
    pjDocumentosExaminadosCtrl.text = 'TR, ETP, Minuta de Contrato v1, Dotação/NE, Documentos do Gestor.';
    pjLinksAnexosCtrl.text = 'SEI://parecer/anexos; Drive://pasta-juridico';

    chkCompetenciaMotivacaoCtrl.text = 'Conforme';
    obsCompetenciaMotivacaoCtrl.text = 'Competência do DER e motivação adequadas.';
    chkEstimativaDotacaoCtrl.text = 'Conforme';
    obsEstimativaDotacaoCtrl.text = 'Pesquisa de preços e NE compatíveis.';
    chkModalidadeRegimeCtrl.text = 'Conforme';
    obsModalidadeRegimeCtrl.text = 'Regime preço global coerente com o escopo.';
    chkHabilitacaoCtrl.text = 'Parcial';
    obsHabilitacaoCtrl.text = 'Solicitar atualização de CNDT (vence em 10 dias).';
    chkClausulasEssenciaisCtrl.text = 'Conforme';
    obsClausulasEssenciaisCtrl.text = 'Reajuste IPCA, garantias e penalidades ok.';
    chkMatrizRiscosCtrl.text = 'Conforme';
    obsMatrizRiscosCtrl.text = 'Riscos bem alocados (chuvas/terceiros).';

    pjConclusaoCtrl.text = 'Favorável condicionado (ajustes obrigatórios)';
    pjDataAssinaturaCtrl.text = '24/09/2025';
    pjRecomendacoesCtrl.text = 'Incluir obrigação de plano de desvio aprovado pelo DER.';
    pjAjustesObrigatoriosCtrl.text = 'Atualizar CNDT; corrigir referência do edital no preâmbulo.';

    pendenciaDescricaoCtrl.text = 'CNDT; referência do edital.';
    pendenciaPrazoCtrl.text = '10/10/2025';
    pendenciaResponsavelCtrl.text = 'Gestor do contrato / Comissão de licitação';

    pjAutoridadeCtrl.text = 'Procurador-Chefe (uid:j2)'; pjAutoridadeUserId = 'j2';
    pjLocalCtrl.text = 'Maceió/AL';
    pjObservacoesFinaisCtrl.text = 'Após ajustes, encaminhar para assinatura do contrato.';
    notifyListeners();
  }

  String? quickValidate() {
    if (pjNumeroCtrl.text.trim().isEmpty) return 'Informe o nº do parecer.';
    if (pjDataCtrl.text.trim().isEmpty) return 'Informe a data do parecer.';
    if (pjRefProcessoCtrl.text.trim().isEmpty) return 'Informe a referência do processo.';
    if (pjConclusaoCtrl.text.trim().isEmpty) return 'Selecione a conclusão.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    'numero': pjNumeroCtrl.text,
    'data': pjDataCtrl.text,
    'orgaoJuridico': pjOrgaoJuridicoCtrl.text,
    'pareceristaNome': pjPareceristaCtrl.text,
    'pareceristaUserId': pjPareceristaUserId,

    'refProcesso': pjRefProcessoCtrl.text,
    'documentosExaminados': pjDocumentosExaminadosCtrl.text,
    'linksAnexos': pjLinksAnexosCtrl.text,

    'analise': {
      'competenciaMotivacao': {'status': chkCompetenciaMotivacaoCtrl.text, 'obs': obsCompetenciaMotivacaoCtrl.text},
      'estimativaDotacao': {'status': chkEstimativaDotacaoCtrl.text, 'obs': obsEstimativaDotacaoCtrl.text},
      'modalidadeRegime': {'status': chkModalidadeRegimeCtrl.text, 'obs': obsModalidadeRegimeCtrl.text},
      'habilitacao': {'status': chkHabilitacaoCtrl.text, 'obs': obsHabilitacaoCtrl.text},
      'clausulasEssenciais': {'status': chkClausulasEssenciaisCtrl.text, 'obs': obsClausulasEssenciaisCtrl.text},
      'matrizRiscos': {'status': chkMatrizRiscosCtrl.text, 'obs': obsMatrizRiscosCtrl.text},
    },

    'conclusao': pjConclusaoCtrl.text,
    'dataAssinatura': pjDataAssinaturaCtrl.text,
    'recomendacoes': pjRecomendacoesCtrl.text,
    'ajustesObrigatorios': pjAjustesObrigatoriosCtrl.text,

    'pendencias': {
      'descricao': pendenciaDescricaoCtrl.text,
      'prazo': pendenciaPrazoCtrl.text,
      'responsavel': pendenciaResponsavelCtrl.text,
    },

    'autoridadeNome': pjAutoridadeCtrl.text,
    'autoridadeUserId': pjAutoridadeUserId,
    'local': pjLocalCtrl.text,
    'observacoesFinais': pjObservacoesFinaisCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    pjNumeroCtrl.text = m['numero'] ?? '';
    pjDataCtrl.text = m['data'] ?? '';
    pjOrgaoJuridicoCtrl.text = m['orgaoJuridico'] ?? '';
    pjPareceristaCtrl.text = m['pareceristaNome'] ?? '';
    pjPareceristaUserId = m['pareceristaUserId'];

    pjRefProcessoCtrl.text = m['refProcesso'] ?? '';
    pjDocumentosExaminadosCtrl.text = m['documentosExaminados'] ?? '';
    pjLinksAnexosCtrl.text = m['linksAnexos'] ?? '';

    final a = (m['analise'] as Map?) ?? {};
    chkCompetenciaMotivacaoCtrl.text = (a['competenciaMotivacao']?['status']) ?? '';
    obsCompetenciaMotivacaoCtrl.text = (a['competenciaMotivacao']?['obs']) ?? '';
    chkEstimativaDotacaoCtrl.text = (a['estimativaDotacao']?['status']) ?? '';
    obsEstimativaDotacaoCtrl.text = (a['estimativaDotacao']?['obs']) ?? '';
    chkModalidadeRegimeCtrl.text = (a['modalidadeRegime']?['status']) ?? '';
    obsModalidadeRegimeCtrl.text = (a['modalidadeRegime']?['obs']) ?? '';
    chkHabilitacaoCtrl.text = (a['habilitacao']?['status']) ?? '';
    obsHabilitacaoCtrl.text = (a['habilitacao']?['obs']) ?? '';
    chkClausulasEssenciaisCtrl.text = (a['clausulasEssenciais']?['status']) ?? '';
    obsClausulasEssenciaisCtrl.text = (a['clausulasEssenciais']?['obs']) ?? '';
    chkMatrizRiscosCtrl.text = (a['matrizRiscos']?['status']) ?? '';
    obsMatrizRiscosCtrl.text = (a['matrizRiscos']?['obs']) ?? '';

    pjConclusaoCtrl.text = m['conclusao'] ?? '';
    pjDataAssinaturaCtrl.text = m['dataAssinatura'] ?? '';
    pjRecomendacoesCtrl.text = m['recomendacoes'] ?? '';
    pjAjustesObrigatoriosCtrl.text = m['ajustesObrigatorios'] ?? '';

    final p = (m['pendencias'] as Map?) ?? {};
    pendenciaDescricaoCtrl.text = p['descricao'] ?? '';
    pendenciaPrazoCtrl.text = p['prazo'] ?? '';
    pendenciaResponsavelCtrl.text = p['responsavel'] ?? '';

    pjAutoridadeCtrl.text = m['autoridadeNome'] ?? '';
    pjAutoridadeUserId = m['autoridadeUserId'];
    pjLocalCtrl.text = m['local'] ?? '';
    pjObservacoesFinaisCtrl.text = m['observacoesFinais'] ?? '';
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      pjNumeroCtrl, pjDataCtrl, pjOrgaoJuridicoCtrl, pjPareceristaCtrl,
      pjRefProcessoCtrl, pjDocumentosExaminadosCtrl, pjLinksAnexosCtrl,
      chkCompetenciaMotivacaoCtrl, obsCompetenciaMotivacaoCtrl,
      chkEstimativaDotacaoCtrl, obsEstimativaDotacaoCtrl,
      chkModalidadeRegimeCtrl, obsModalidadeRegimeCtrl,
      chkHabilitacaoCtrl, obsHabilitacaoCtrl,
      chkClausulasEssenciaisCtrl, obsClausulasEssenciaisCtrl,
      chkMatrizRiscosCtrl, obsMatrizRiscosCtrl,
      pjConclusaoCtrl, pjDataAssinaturaCtrl, pjRecomendacoesCtrl, pjAjustesObrigatoriosCtrl,
      pendenciaDescricaoCtrl, pendenciaPrazoCtrl, pendenciaResponsavelCtrl,
      pjAutoridadeCtrl, pjLocalCtrl, pjObservacoesFinaisCtrl,
    ]) { ctrl.clear(); }
    pjPareceristaUserId = null;
    pjAutoridadeUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      pjNumeroCtrl, pjDataCtrl, pjOrgaoJuridicoCtrl, pjPareceristaCtrl,
      pjRefProcessoCtrl, pjDocumentosExaminadosCtrl, pjLinksAnexosCtrl,
      chkCompetenciaMotivacaoCtrl, obsCompetenciaMotivacaoCtrl,
      chkEstimativaDotacaoCtrl, obsEstimativaDotacaoCtrl,
      chkModalidadeRegimeCtrl, obsModalidadeRegimeCtrl,
      chkHabilitacaoCtrl, obsHabilitacaoCtrl,
      chkClausulasEssenciaisCtrl, obsClausulasEssenciaisCtrl,
      chkMatrizRiscosCtrl, obsMatrizRiscosCtrl,
      pjConclusaoCtrl, pjDataAssinaturaCtrl, pjRecomendacoesCtrl, pjAjustesObrigatoriosCtrl,
      pendenciaDescricaoCtrl, pendenciaPrazoCtrl, pendenciaResponsavelCtrl,
      pjAutoridadeCtrl, pjLocalCtrl, pjObservacoesFinaisCtrl,
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
