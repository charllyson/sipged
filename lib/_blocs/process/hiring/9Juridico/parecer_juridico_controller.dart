// lib/_blocs/process/hiring/9Juridico/parecer_juridico_controller.dart
import 'package:flutter/material.dart';

class ParecerJuridicoController extends ChangeNotifier {
  bool isEditable;
  ParecerJuridicoController({this.isEditable = true});

  // ==== 1) Metadados ====
  final pjNumeroCtrl = TextEditingController();
  final pjDataCtrl = TextEditingController(); // dd/mm/aaaa
  final pjOrgaoJuridicoCtrl = TextEditingController();
  final pjPareceristaCtrl = TextEditingController();
  String? pjPareceristaUserId;

  // ==== 2) Documentos analisados ====
  final pjRefProcessoCtrl = TextEditingController();
  final pjDocumentosExaminadosCtrl = TextEditingController();
  final pjLinksAnexosCtrl = TextEditingController();

  // ==== 3) Checklist (Análise de conformidade) ====
  final chkCompetenciaMotivacaoCtrl = TextEditingController();
  final obsCompetenciaMotivacaoCtrl = TextEditingController();

  final chkEstimativaDotacaoCtrl = TextEditingController();
  final obsEstimativaDotacaoCtrl = TextEditingController();

  final chkModalidadeRegimeCtrl = TextEditingController();
  final obsModalidadeRegimeCtrl = TextEditingController();

  final chkHabilitacaoCtrl = TextEditingController();
  final obsHabilitacaoCtrl = TextEditingController();

  final chkClausulasEssenciaisCtrl = TextEditingController();
  final obsClausulasEssenciaisCtrl = TextEditingController();

  final chkMatrizRiscosCtrl = TextEditingController();
  final obsMatrizRiscosCtrl = TextEditingController();

  // ==== 4) Conclusão ====
  final pjConclusaoCtrl = TextEditingController();
  final pjDataAssinaturaCtrl = TextEditingController(); // dd/mm/aaaa
  final pjRecomendacoesCtrl = TextEditingController();
  final pjAjustesObrigatoriosCtrl = TextEditingController();

  // ==== 5) Pendências ====
  final pendenciaDescricaoCtrl = TextEditingController();
  final pendenciaPrazoCtrl = TextEditingController(); // dd/mm/aaaa
  final pendenciaResponsavelCtrl = TextEditingController();

  // ==== 6) Assinaturas / Referências finais ====
  final pjAutoridadeCtrl = TextEditingController();
  String? pjAutoridadeUserId;
  final pjLocalCtrl = TextEditingController();
  final pjObservacoesFinaisCtrl = TextEditingController();

  // ===== Helpers =====
  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  bool _looksUid(String? v) => v != null && v.trim().length >= 20 && !v.contains(' ');

  /// Zera todos os campos (útil ao criar novo registro)
  void clearAll() {
    for (final c in _allCtrls) c.clear();
    pjPareceristaUserId = null;
    pjAutoridadeUserId = null;
    notifyListeners();
  }

  /// Aplica patch em uma única seção (merge superficial)
  void patchSection(String key, Map<String, dynamic> data) {
    final s = {key: Map<String, dynamic>.from(data)};
    fromSectionMaps(_mergeMaps(toSectionMaps(), s));
  }

  Map<String, Map<String, dynamic>> _mergeMaps(
      Map<String, Map<String, dynamic>> a,
      Map<String, Map<String, dynamic>> b,
      ) {
    final out = <String, Map<String, dynamic>>{};
    final keys = {...a.keys, ...b.keys};
    for (final k in keys) {
      out[k] = {...(a[k] ?? const {}), ...(b[k] ?? const {})};
    }
    return out;
  }

  // ===== (de)serialização =====
  Map<String, Map<String, dynamic>> toSectionMaps() => {
    'metadados': {
      'numero': pjNumeroCtrl.text,
      'data': pjDataCtrl.text,
      'orgao': pjOrgaoJuridicoCtrl.text,
      'pareceristaNome': pjPareceristaCtrl.text,
      'pareceristaUserId': pjPareceristaUserId,
    },
    'documentos': {
      'refProcesso': pjRefProcessoCtrl.text,
      'documentosExaminados': pjDocumentosExaminadosCtrl.text,
      'linksAnexos': pjLinksAnexosCtrl.text,
    },
    'checklist': {
      'competenciaMotivacaoStatus': chkCompetenciaMotivacaoCtrl.text,
      'competenciaMotivacaoObs': obsCompetenciaMotivacaoCtrl.text,
      'estimativaDotacaoStatus': chkEstimativaDotacaoCtrl.text,
      'estimativaDotacaoObs': obsEstimativaDotacaoCtrl.text,
      'modalidadeRegimeStatus': chkModalidadeRegimeCtrl.text,
      'modalidadeRegimeObs': obsModalidadeRegimeCtrl.text,
      'habilitacaoStatus': chkHabilitacaoCtrl.text,
      'habilitacaoObs': obsHabilitacaoCtrl.text,
      'clausulasEssenciaisStatus': chkClausulasEssenciaisCtrl.text,
      'clausulasEssenciaisObs': obsClausulasEssenciaisCtrl.text,
      'matrizRiscosStatus': chkMatrizRiscosCtrl.text,
      'matrizRiscosObs': obsMatrizRiscosCtrl.text,
    },
    'conclusao': {
      'conclusao': pjConclusaoCtrl.text,
      'dataAssinatura': pjDataAssinaturaCtrl.text,
      'recomendacoes': pjRecomendacoesCtrl.text,
      'ajustesObrigatorios': pjAjustesObrigatoriosCtrl.text,
    },
    'pendencias': {
      'descricao': pendenciaDescricaoCtrl.text,
      'prazo': pendenciaPrazoCtrl.text,
      'responsavel': pendenciaResponsavelCtrl.text,
    },
    'assinaturas': {
      'autoridadeNome': pjAutoridadeCtrl.text,
      'autoridadeUserId': pjAutoridadeUserId,
      'local': pjLocalCtrl.text,
      'observacoesFinais': pjObservacoesFinaisCtrl.text,
    },
  };

  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    // metadados
    final m = sections['metadados'] ?? const {};
    pjNumeroCtrl.text = m['numero'] ?? '';
    pjDataCtrl.text = m['data'] ?? '';
    pjOrgaoJuridicoCtrl.text = m['orgao'] ?? '';
    pjPareceristaUserId = m['pareceristaUserId'] ?? (_looksUid(m['pareceristaNome']) ? m['pareceristaNome'] : null);
    pjPareceristaCtrl.text = _looksUid(m['pareceristaNome']) ? '' : (m['pareceristaNome'] ?? '');

    // documentos
    final d = sections['documentos'] ?? const {};
    pjRefProcessoCtrl.text = d['refProcesso'] ?? '';
    pjDocumentosExaminadosCtrl.text = d['documentosExaminados'] ?? '';
    pjLinksAnexosCtrl.text = d['linksAnexos'] ?? '';

    // checklist
    final c = sections['checklist'] ?? const {};
    chkCompetenciaMotivacaoCtrl.text = c['competenciaMotivacaoStatus'] ?? '';
    obsCompetenciaMotivacaoCtrl.text = c['competenciaMotivacaoObs'] ?? '';
    chkEstimativaDotacaoCtrl.text = c['estimativaDotacaoStatus'] ?? '';
    obsEstimativaDotacaoCtrl.text = c['estimativaDotacaoObs'] ?? '';
    chkModalidadeRegimeCtrl.text = c['modalidadeRegimeStatus'] ?? '';
    obsModalidadeRegimeCtrl.text = c['modalidadeRegimeObs'] ?? '';
    chkHabilitacaoCtrl.text = c['habilitacaoStatus'] ?? '';
    obsHabilitacaoCtrl.text = c['habilitacaoObs'] ?? '';
    chkClausulasEssenciaisCtrl.text = c['clausulasEssenciaisStatus'] ?? '';
    obsClausulasEssenciaisCtrl.text = c['clausulasEssenciaisObs'] ?? '';
    chkMatrizRiscosCtrl.text = c['matrizRiscosStatus'] ?? '';
    obsMatrizRiscosCtrl.text = c['matrizRiscosObs'] ?? '';

    // conclusão
    final cc = sections['conclusao'] ?? const {};
    pjConclusaoCtrl.text = cc['conclusao'] ?? '';
    pjDataAssinaturaCtrl.text = cc['dataAssinatura'] ?? '';
    pjRecomendacoesCtrl.text = cc['recomendacoes'] ?? '';
    pjAjustesObrigatoriosCtrl.text = cc['ajustesObrigatorios'] ?? '';

    // pendências
    final p = sections['pendencias'] ?? const {};
    pendenciaDescricaoCtrl.text = p['descricao'] ?? '';
    pendenciaPrazoCtrl.text = p['prazo'] ?? '';
    pendenciaResponsavelCtrl.text = p['responsavel'] ?? '';

    // assinaturas
    final a = sections['assinaturas'] ?? const {};
    pjAutoridadeUserId = a['autoridadeUserId'] ?? (_looksUid(a['autoridadeNome']) ? a['autoridadeNome'] : null);
    pjAutoridadeCtrl.text = _looksUid(a['autoridadeNome']) ? '' : (a['autoridadeNome'] ?? '');
    pjLocalCtrl.text = a['local'] ?? '';
    pjObservacoesFinaisCtrl.text = a['observacoesFinais'] ?? '';

    notifyListeners();
  }

  /// Validações mínimas p/ permitir salvar rapidamente
  String? quickValidate() {
    if (pjNumeroCtrl.text.trim().isEmpty) return 'Informe o Nº do parecer.';
    if (pjDataCtrl.text.trim().isEmpty) return 'Informe a data do parecer.';
    if (pjOrgaoJuridicoCtrl.text.trim().isEmpty) return 'Informe o órgão/unidade jurídica.';
    if ((pjPareceristaUserId == null || pjPareceristaUserId!.isEmpty) &&
        pjPareceristaCtrl.text.trim().isEmpty) {
      return 'Selecione o parecerista.';
    }
    if (pjRefProcessoCtrl.text.trim().isEmpty) return 'Informe a referência do processo.';
    if (pjConclusaoCtrl.text.trim().isEmpty) return 'Selecione a conclusão.';
    return null;
  }

  List<TextEditingController> get _allCtrls => [
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
  ];

  @override
  void dispose() {
    for (final c in _allCtrls) { c.dispose(); }
    super.dispose();
  }
}
