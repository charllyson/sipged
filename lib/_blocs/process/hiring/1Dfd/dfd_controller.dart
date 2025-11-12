import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller do DFD (sem dependência direta de Firebase).
class DfdController extends ChangeNotifier {
  // ---- estado geral ----
  bool isEditable;
  String? dfdRodoviaId; // <- usado pelo selectedId do dropdown de Rodovia

  // ==== ESCOPO POR EMPRESA (Contratante) ====
  String? companyId;
  String? companyName;

  // ==== IDs e labels dependentes do Contratante ====
  String? unitId;
  String? regionId;

  // Rodovia (ID + label)
  String? roadId;   // <- persistido em localizacao.roadId
  String? roadName; // <- persistido em localizacao.roadName

  // ==== 4) Estimativa: IDs para pré-seleção em dropdowns ====
  String? fundingSourceId;    // companies/{companyId}/funding_sources
  String? programId;          // companies/{companyId}/programs
  String? expenseNatureId;    // companies/{companyId}/expense_natures

  bool get hasCompany => companyId != null && companyId!.isNotEmpty;

  DfdController({this.isEditable = true});

  // Kicker para reconstruir dependentes (units/regions/roads, listas da empresa)
  int companyNonce = 0;

  // ==== 1) Identificação ====
  final dfdOrgaoDemandanteCtrl = TextEditingController();  // label do contratante
  final dfdUnidadeSolicitanteCtrl = TextEditingController();
  String? dfdRegionalValue;
  final dfdRegionalCtrl = TextEditingController();         // controller estável p/ dropdown regional

  // Solicitante (guardamos ID e mostramos nome)
  final dfdSolicitanteCtrl = TextEditingController(); // exibe nome/email
  String? dfdSolicitanteUserId;                       // armazena o ID

  final dfdCpfSolicitanteCtrl = TextEditingController();
  final dfdCargoSolicitanteCtrl = TextEditingController();
  final dfdEmailSolicitanteCtrl = TextEditingController();
  final dfdTelefoneSolicitanteCtrl = TextEditingController();
  final dfdDataSolicitacaoCtrl = TextEditingController();
  final dfdProtocoloSeiCtrl = TextEditingController();

  // ==== 2) Objeto / Escopo ====
  String? dfdTipoContratacaoValue;
  String? dfdModalidadeEstimativaValue;
  String? dfdRegimeExecucaoValue;
  final dfdDescricaoObjetoCtrl = TextEditingController();
  final dfdJustificativaCtrl = TextEditingController();

  // ==== 3) Localização rodoviária ====
  final dfdUFCtrl = TextEditingController();
  final dfdMunicipioCtrl = TextEditingController();
  // Compat: mantém também um "label" de rodovia como antes
  final dfdRodoviaCtrl = TextEditingController();
  final dfdKmInicialCtrl = TextEditingController();
  final dfdKmFinalCtrl = TextEditingController();
  String? dfdNaturezaIntervencaoValue;
  final dfdPrazoExecucaoDiasCtrl = TextEditingController();
  final dfdVigenciaMesesCtrl = TextEditingController();

  // ==== 4) Estimativa orçamentária ====
  final dfdFonteRecursoCtrl = TextEditingController();
  final dfdProgramaTrabalhoCtrl = TextEditingController();
  final dfdPtresCtrl = TextEditingController();
  final dfdNaturezaDespesaCtrl = TextEditingController();
  final dfdEstimativaValorCtrl = TextEditingController();
  final dfdMetodologiaEstimativaCtrl = TextEditingController();

  // ==== 5) Riscos e Impacto ====
  final dfdRiscosPrincipaisCtrl = TextEditingController();
  final dfdImpactoNaoContratarCtrl = TextEditingController();
  String? dfdPrioridadeValue;
  final dfdDataLimiteUrgenciaCtrl = TextEditingController();
  final dfdMotivacaoLegalCtrl = TextEditingController();
  final dfdAmparoNormativoCtrl = TextEditingController();

  // ==== 6) Documentos / Checklists ====
  String? dfdEtpAnexoValue;
  String? dfdProjetoBasicoValue;
  String? dfdTermoMatrizRiscosValue;
  String? dfdParecerJuridicoValue;
  String? dfdAutorizacaoAberturaValue;
  final dfdLinksDocumentosCtrl = TextEditingController();

  // ==== 7) Aprovação / Alçada ====
  final dfdAutoridadeAprovadoraCtrl = TextEditingController();
  String? dfdAutoridadeAprovadoraUserId;
  final dfdCpfAutoridadeCtrl = TextEditingController();
  final dfdDataAprovacaoCtrl = TextEditingController();
  final dfdParecerResumoCtrl = TextEditingController();

  // ==== 8) Observações ====
  final dfdObservacoesCtrl = TextEditingController();

  // ==== (NOVO) 5 campos migrados do MainManagerSection ====
  String? dfdStatusContratoValue;                 // Dropdown: DfdData.statusTypes
  final dfdNumeroProcessoCtrl = TextEditingController(); // Nº do processo (SEI/Protocolo da contratação)
  final dfdExtensaoKmCtrl = TextEditingController();     // Extensão (km) - 3 casas
  String? dfdTipoObraValue;                       // Dropdown: DfdData.workTypes

  // ───────────────── setters/notifiers ─────────────────

  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  void clearCompany() {
    companyId = null;
    companyName = null;

    // limpa dependentes
    unitId = null;
    dfdUnidadeSolicitanteCtrl.clear();

    regionId = null;
    dfdRegionalValue = null;
    dfdRegionalCtrl.clear();

    // rodovia (zera TUDO)
    dfdRodoviaId = null;
    roadId = null;
    roadName = null;
    dfdRodoviaCtrl.clear();

    // estimativa (IDs e labels)
    fundingSourceId = null;
    dfdFonteRecursoCtrl.clear();

    programId = null;
    dfdProgramaTrabalhoCtrl.clear();

    expenseNatureId = null;
    dfdNaturezaDespesaCtrl.clear();

    companyNonce++;
    notifyListeners();
  }

  void setCompany({required String id, String? label}) {
    companyId = id;
    companyName = label;
    dfdOrgaoDemandanteCtrl.text = label ?? dfdOrgaoDemandanteCtrl.text;

    // limpa dependentes
    unitId = null;
    dfdUnidadeSolicitanteCtrl.clear();

    regionId = null;
    dfdRegionalValue = null;
    dfdRegionalCtrl.clear();

    // rodovia
    dfdRodoviaId = null;
    roadId = null;
    roadName = null;
    dfdRodoviaCtrl.clear();

    // estimativa (IDs e labels)
    fundingSourceId = null;
    dfdFonteRecursoCtrl.clear();

    programId = null;
    dfdProgramaTrabalhoCtrl.clear();

    expenseNatureId = null;
    dfdNaturezaDespesaCtrl.clear();

    companyNonce++;
    notifyListeners();
  }

  /// Define unidade selecionada (id + label)
  void setUnit({required String id, required String label}) {
    unitId = id;
    dfdUnidadeSolicitanteCtrl.text = label;
    notifyListeners();
  }

  /// Define regional selecionada (id + label)
  void setRegion({required String id, required String label}) {
    regionId = id;
    dfdRegionalValue = label;
    dfdRegionalCtrl.text = label;
    notifyListeners();
  }

  /// Define UF
  void setUf(String? uf) {
    dfdUFCtrl.text = (uf ?? '').trim().toUpperCase();
    notifyListeners();
  }

  /// Define Município
  void setMunicipio(String? municipio) {
    dfdMunicipioCtrl.text = (municipio ?? '').trim();
    notifyListeners();
  }

  /// Define rodovia por ID + label (preferencial)
  void setRodovia({required String id, required String label}) {
    dfdRodoviaId = id;      // usado como selectedId do dropdown
    roadId       = id;      // persistência na seção 'localizacao'
    roadName     = label;   // persistência (e apresentação)
    dfdRodoviaCtrl.text = label; // compat com UI atual
    notifyListeners();
  }

  /// Método legado mantido: delega para setRodovia
  void setRoad({required String id, required String label}) {
    setRodovia(id: id, label: label);
  }

  /// Apenas define label da rodovia (compat legado, sem conhecer o ID)
  void setRodoviaLabel(String? label) {
    final clean = (label ?? '').trim();
    if (clean.isEmpty) {
      dfdRodoviaId = null;
      roadId = null;
      roadName = null;
      dfdRodoviaCtrl.clear();
    } else {
      dfdRodoviaId = null;      // sem ID conhecido
      roadId = null;
      roadName = clean;
      dfdRodoviaCtrl.text = clean;
    }
    notifyListeners();
  }

  // ==== Estimativa: setters com ID + label (para dropdowns com selectedId) ====

  void setFundingSource({required String id, required String label}) {
    fundingSourceId = id;
    dfdFonteRecursoCtrl.text = label;
    notifyListeners();
  }

  void setProgram({required String id, required String label}) {
    programId = id;
    dfdProgramaTrabalhoCtrl.text = label;
    notifyListeners();
  }

  void setExpenseNature({required String id, required String label}) {
    expenseNatureId = id;
    dfdNaturezaDespesaCtrl.text = label;
    notifyListeners();
  }

  String? quickValidate() {
    if ((companyId == null || companyId!.isEmpty) &&
        dfdOrgaoDemandanteCtrl.text.trim().isEmpty) {
      return 'Informe o Contratante (empresa).';
    }
    if (dfdDescricaoObjetoCtrl.text.trim().isEmpty) {
      return 'Descreva o objeto da contratação.';
    }
    if (dfdTipoContratacaoValue == null) {
      return 'Selecione o tipo de contratação.';
    }
    if (dfdNaturezaIntervencaoValue == null) {
      return 'Selecione a natureza da intervenção.';
    }
    return null;
  }

  // ───────────────── helpers ─────────────────
  bool _looksUid(String? v) =>
      v != null && v.trim().length >= 20 && !v.contains(' ');

  // ───────────────── (de)serialização geral ─────────────────

  Map<String, dynamic> toMap() => {
    'companyId': companyId,
    'companyName': companyName,

    // compat + novos campos de rodovia
    'rodoviaId': dfdRodoviaId,
    'rodovia': dfdRodoviaCtrl.text,
    'roadId': roadId,
    'roadName': roadName ?? dfdRodoviaCtrl.text,

    // estimativa: também persistimos os IDs (além dos labels já existentes)
    'fundingSourceId': fundingSourceId,
    'programId': programId,
    'expenseNatureId': expenseNatureId,

    'orgaoDemandante': dfdOrgaoDemandanteCtrl.text,
    'unitId': unitId,
    'unidadeSolicitante': dfdUnidadeSolicitanteCtrl.text,
    'regionId': regionId,
    'regional': dfdRegionalValue,
    'solicitanteNome': dfdSolicitanteCtrl.text,
    'solicitanteUserId': dfdSolicitanteUserId,
    'solicitanteCpf': dfdCpfSolicitanteCtrl.text,
    'solicitanteCargo': dfdCargoSolicitanteCtrl.text,
    'solicitanteEmail': dfdEmailSolicitanteCtrl.text,
    'solicitanteTelefone': dfdTelefoneSolicitanteCtrl.text,
    'dataSolicitacao': dfdDataSolicitacaoCtrl.text,
    'protocoloSei': dfdProtocoloSeiCtrl.text,
    'tipoContratacao': dfdTipoContratacaoValue,
    'modalidadeEstimativa': dfdModalidadeEstimativaValue,
    'regimeExecucao': dfdRegimeExecucaoValue,
    'descricaoObjeto': dfdDescricaoObjetoCtrl.text,
    'justificativa': dfdJustificativaCtrl.text,
    'uf': dfdUFCtrl.text,
    'municipio': dfdMunicipioCtrl.text,
    'kmInicial': dfdKmInicialCtrl.text,
    'kmFinal': dfdKmFinalCtrl.text,
    'naturezaIntervencao': dfdNaturezaIntervencaoValue,
    'prazoExecucaoDias': dfdPrazoExecucaoDiasCtrl.text,
    'vigenciaMeses': dfdVigenciaMesesCtrl.text,
    'fonteRecurso': dfdFonteRecursoCtrl.text,
    'programaTrabalho': dfdProgramaTrabalhoCtrl.text,
    'ptres': dfdPtresCtrl.text,
    'naturezaDespesa': dfdNaturezaDespesaCtrl.text,
    'estimativaValor': dfdEstimativaValorCtrl.text,
    'metodologiaEstimativa': dfdMetodologiaEstimativaCtrl.text,
    'riscos': dfdRiscosPrincipaisCtrl.text,
    'impactoNaoContratar': dfdImpactoNaoContratarCtrl.text,
    'prioridade': dfdPrioridadeValue,
    'dataLimite': dfdDataLimiteUrgenciaCtrl.text,
    'motivacaoLegal': dfdMotivacaoLegalCtrl.text,
    'amparoNormativo': dfdAmparoNormativoCtrl.text,
    'etpAnexo': dfdEtpAnexoValue,
    'projetoBasico': dfdProjetoBasicoValue,
    'termoMatrizRiscos': dfdTermoMatrizRiscosValue,
    'parecerJuridico': dfdParecerJuridicoValue,
    'autorizacaoAbertura': dfdAutorizacaoAberturaValue,
    'linksDocumentos': dfdLinksDocumentosCtrl.text,
    'autoridadeAprovadora': dfdAutoridadeAprovadoraCtrl.text,
    'autoridadeUserId': dfdAutoridadeAprovadoraUserId,
    'autoridadeCpf': dfdCpfAutoridadeCtrl.text,
    'dataAprovacao': dfdDataAprovacaoCtrl.text,
    'parecerResumo': dfdParecerResumoCtrl.text,
    'observacoes': dfdObservacoesCtrl.text,

    // NOVOS (espalhados nas seções mas útil no snapshot completo)
    'statusContrato': dfdStatusContratoValue,
    'numeroProcessoContratacao': dfdNumeroProcessoCtrl.text,
    'extensaoKm': dfdExtensaoKmCtrl.text,
    'tipoObra': dfdTipoObraValue,
  };

  void fromMap(Map<String, dynamic> map) {
    companyId = map['companyId'];
    companyName = map['companyName'];

    // compat + novos campos de rodovia
    dfdRodoviaId = map['rodoviaId']; // compat legado
    final legacyRoadLabel = map['rodovia'] as String?;
    roadId = (map['roadId'] as String?) ?? dfdRodoviaId;
    roadName = (map['roadName'] as String?) ?? legacyRoadLabel;
    dfdRodoviaId = roadId; // <- garante selectedId
    dfdRodoviaCtrl.text = roadName ?? legacyRoadLabel ?? '';

    // Estimativa: IDs (se existirem)
    fundingSourceId = map['fundingSourceId'];
    programId       = map['programId'];
    expenseNatureId = map['expenseNatureId'];

    // Preferir companyName se existir (apresentação do contratante)
    final orgaoDemandante = (map['orgaoDemandante'] as String?)?.trim();
    dfdOrgaoDemandanteCtrl.text =
    (companyName?.trim().isNotEmpty ?? false) ? companyName! : (orgaoDemandante ?? '');

    // Unidade (id + label)
    unitId = map['unitId'];
    dfdUnidadeSolicitanteCtrl.text = map['unidadeSolicitante'] ?? '';

    // Regional (id + label)
    regionId = map['regionId'];
    dfdRegionalValue = map['regional'];
    dfdRegionalCtrl.text = dfdRegionalValue ?? '';

    // Solicitante
    final sNome = map['solicitanteNome'] as String?;
    final sId = map['solicitanteUserId'] as String?;
    dfdSolicitanteUserId = sId ?? (_looksUid(sNome) ? sNome : null);
    dfdSolicitanteCtrl.text = _looksUid(sNome) ? '' : (sNome ?? '');

    dfdCpfSolicitanteCtrl.text = map['solicitanteCpf'] ?? '';
    dfdCargoSolicitanteCtrl.text = map['solicitanteCargo'] ?? '';
    dfdEmailSolicitanteCtrl.text = map['solicitanteEmail'] ?? '';
    dfdTelefoneSolicitanteCtrl.text = map['solicitanteTelefone'] ?? '';
    dfdDataSolicitacaoCtrl.text = map['dataSolicitacao'] ?? '';
    dfdProtocoloSeiCtrl.text = map['protocoloSei'] ?? '';

    dfdTipoContratacaoValue = map['tipoContratacao'];
    dfdModalidadeEstimativaValue = map['modalidadeEstimativa'];
    dfdRegimeExecucaoValue = map['regimeExecucao'];
    dfdDescricaoObjetoCtrl.text = map['descricaoObjeto'] ?? '';
    dfdJustificativaCtrl.text = map['justificativa'] ?? '';

    dfdUFCtrl.text = map['uf'] ?? '';
    dfdMunicipioCtrl.text = map['municipio'] ?? '';

    dfdKmInicialCtrl.text = map['kmInicial'] ?? '';
    dfdKmFinalCtrl.text = map['kmFinal'] ?? '';
    dfdNaturezaIntervencaoValue = map['naturezaIntervencao'];
    dfdPrazoExecucaoDiasCtrl.text = map['prazoExecucaoDias'] ?? '';
    dfdVigenciaMesesCtrl.text = map['vigenciaMeses'] ?? '';

    // Labels da estimativa (mantidos)
    dfdFonteRecursoCtrl.text = map['fonteRecurso'] ?? '';
    dfdProgramaTrabalhoCtrl.text = map['programaTrabalho'] ?? '';
    dfdPtresCtrl.text = map['ptres'] ?? '';
    dfdNaturezaDespesaCtrl.text = map['naturezaDespesa'] ?? '';
    dfdEstimativaValorCtrl.text = map['estimativaValor'] ?? '';
    dfdMetodologiaEstimativaCtrl.text = map['metodologiaEstimativa'] ?? '';

    dfdRiscosPrincipaisCtrl.text = map['riscos'] ?? '';
    dfdImpactoNaoContratarCtrl.text = map['impactoNaoContratar'] ?? '';
    dfdPrioridadeValue = map['prioridade'];
    dfdDataLimiteUrgenciaCtrl.text = map['dataLimite'] ?? '';
    dfdMotivacaoLegalCtrl.text = map['motivacaoLegal'] ?? '';
    dfdAmparoNormativoCtrl.text = map['amparoNormativo'] ?? '';

    dfdEtpAnexoValue = map['etpAnexo'];
    dfdProjetoBasicoValue = map['projetoBasico'];
    dfdTermoMatrizRiscosValue = map['termoMatrizRiscos'];
    dfdParecerJuridicoValue = map['parecerJuridico'];
    dfdAutorizacaoAberturaValue = map['autorizacaoAbertura'];
    dfdLinksDocumentosCtrl.text = map['linksDocumentos'] ?? '';

    dfdAutoridadeAprovadoraCtrl.text = map['autoridadeAprovadora'] ?? '';
    dfdAutoridadeAprovadoraUserId = map['autoridadeUserId'];
    dfdCpfAutoridadeCtrl.text = map['autoridadeCpf'] ?? '';
    dfdDataAprovacaoCtrl.text = map['dataAprovacao'] ?? '';
    dfdParecerResumoCtrl.text = map['parecerResumo'] ?? '';

    dfdObservacoesCtrl.text = map['observacoes'] ?? '';

    // NOVOS (snapshot completo — útil para compat geral)
    dfdStatusContratoValue = map['statusContrato'];
    dfdNumeroProcessoCtrl.text = map['numeroProcessoContratacao'] ?? '';
    dfdExtensaoKmCtrl.text = map['extensaoKm'] ?? '';
    dfdTipoObraValue = map['tipoObra'];

    companyNonce++; // força recarga dos dropdowns dependentes
    notifyListeners();
  }

  /// ==== Mapas por seção (para subcoleções) ====
  Map<String, Map<String, dynamic>> toSectionMaps() => {
    'identificacao': {
      'companyId': companyId,
      'companyName': companyName,
      'rodoviaId': dfdRodoviaId, // compat legado (identificação)
      'rodovia': dfdRodoviaCtrl.text,
      'orgaoDemandante': dfdOrgaoDemandanteCtrl.text,
      'unitId': unitId,
      'unidadeSolicitante': dfdUnidadeSolicitanteCtrl.text,
      'regionId': regionId,
      'regional': dfdRegionalValue,
      'solicitanteNome': dfdSolicitanteCtrl.text,
      'solicitanteUserId': dfdSolicitanteUserId,
      'solicitanteCpf': dfdCpfSolicitanteCtrl.text,
      'solicitanteCargo': dfdCargoSolicitanteCtrl.text,
      'solicitanteEmail': dfdEmailSolicitanteCtrl.text,
      'solicitanteTelefone': dfdTelefoneSolicitanteCtrl.text,
      'dataSolicitacao': dfdDataSolicitacaoCtrl.text,
      'protocoloSei': dfdProtocoloSeiCtrl.text,

      // NOVOS
      'statusContrato': dfdStatusContratoValue,
      'numeroProcessoContratacao': dfdNumeroProcessoCtrl.text,
    },
    'objeto': {
      'tipoContratacao': dfdTipoContratacaoValue,
      'modalidadeEstimativa': dfdModalidadeEstimativaValue,
      'regimeExecucao': dfdRegimeExecucaoValue,
      'descricaoObjeto': dfdDescricaoObjetoCtrl.text,
      'justificativa': dfdJustificativaCtrl.text,

      // NOVO
      'tipoObra': dfdTipoObraValue,
    },
    'localizacao': {
      'uf': dfdUFCtrl.text,
      'municipio': dfdMunicipioCtrl.text,
      // compat + novos campos
      'rodovia': dfdRodoviaCtrl.text,
      'roadId': roadId,
      'roadName': roadName ?? dfdRodoviaCtrl.text,
      'kmInicial': dfdKmInicialCtrl.text,
      'kmFinal': dfdKmFinalCtrl.text,
      'naturezaIntervencao': dfdNaturezaIntervencaoValue,
      'prazoExecucaoDias': dfdPrazoExecucaoDiasCtrl.text,
      'vigenciaMeses': dfdVigenciaMesesCtrl.text,

      // NOVO
      'extensaoKm': dfdExtensaoKmCtrl.text,
    },
    'estimativa': {
      // IDs + labels
      'fundingSourceId': fundingSourceId,
      'programId': programId,
      'expenseNatureId': expenseNatureId,
      'fonteRecurso': dfdFonteRecursoCtrl.text,
      'programaTrabalho': dfdProgramaTrabalhoCtrl.text,
      'ptres': dfdPtresCtrl.text,
      'naturezaDespesa': dfdNaturezaDespesaCtrl.text,
      'estimativaValor': dfdEstimativaValorCtrl.text,
      'metodologiaEstimativa': dfdMetodologiaEstimativaCtrl.text,
    },
    'riscos': {
      'riscos': dfdRiscosPrincipaisCtrl.text,
      'impactoNaoContratar': dfdImpactoNaoContratarCtrl.text,
      'prioridade': dfdPrioridadeValue,
      'dataLimite': dfdDataLimiteUrgenciaCtrl.text,
      'motivacaoLegal': dfdMotivacaoLegalCtrl.text,
      'amparoNormativo': dfdAmparoNormativoCtrl.text,
    },
    'documentos': {
      'etpAnexo': dfdEtpAnexoValue,
      'projetoBasico': dfdProjetoBasicoValue,
      'termoMatrizRiscos': dfdTermoMatrizRiscosValue,
      'parecerJuridico': dfdParecerJuridicoValue,
      'autorizacaoAbertura': dfdAutorizacaoAberturaValue,
      'linksDocumentos': dfdLinksDocumentosCtrl.text,
    },
    'aprovacao': {
      'autoridadeAprovadora': dfdAutoridadeAprovadoraCtrl.text,
      'autoridadeUserId': dfdAutoridadeAprovadoraUserId,
      'autoridadeCpf': dfdCpfAutoridadeCtrl.text,
      'dataAprovacao': dfdDataAprovacaoCtrl.text,
      'parecerResumo': dfdParecerResumoCtrl.text,
    },
    'observacoes': {
      'observacoes': dfdObservacoesCtrl.text,
    },
  };

  /// ==== Preenche a partir de {secao: map} ====
  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    final id = sections['identificacao'] ?? const {};
    companyId = id['companyId'];
    companyName = id['companyName'];

    // compat (mantém campo legado)
    dfdRodoviaId = id['rodoviaId'];
    dfdRodoviaCtrl.text = id['rodovia'] ?? '';

    final orgaoDemandante = (id['orgaoDemandante'] as String?)?.trim();
    dfdOrgaoDemandanteCtrl.text =
    (companyName?.trim().isNotEmpty ?? false) ? companyName! : (orgaoDemandante ?? '');

    // Unidade
    unitId = id['unitId'];
    dfdUnidadeSolicitanteCtrl.text = id['unidadeSolicitante'] ?? '';

    // Regional
    regionId = id['regionId'];
    dfdRegionalValue = id['regional'];
    dfdRegionalCtrl.text = dfdRegionalValue ?? '';

    final sNome = id['solicitanteNome'] as String?;
    final sId = id['solicitanteUserId'] as String?;
    dfdSolicitanteUserId = sId ?? (_looksUid(sNome) ? sNome : null);
    dfdSolicitanteCtrl.text = _looksUid(sNome) ? '' : (sNome ?? '');

    dfdCpfSolicitanteCtrl.text = id['solicitanteCpf'] ?? '';
    dfdCargoSolicitanteCtrl.text = id['solicitanteCargo'] ?? '';
    dfdEmailSolicitanteCtrl.text = id['solicitanteEmail'] ?? '';
    dfdTelefoneSolicitanteCtrl.text = id['solicitanteTelefone'] ?? '';
    dfdDataSolicitacaoCtrl.text = id['dataSolicitacao'] ?? '';
    dfdProtocoloSeiCtrl.text = id['protocoloSei'] ?? '';

    // NOVOS (identificação)
    dfdStatusContratoValue = id['statusContrato'];
    dfdNumeroProcessoCtrl.text = id['numeroProcessoContratacao'] ?? '';

    final obj = sections['objeto'] ?? const {};
    dfdTipoContratacaoValue = obj['tipoContratacao'];
    dfdModalidadeEstimativaValue = obj['modalidadeEstimativa'];
    dfdRegimeExecucaoValue = obj['regimeExecucao'];
    dfdDescricaoObjetoCtrl.text = obj['descricaoObjeto'] ?? '';
    dfdJustificativaCtrl.text = obj['justificativa'] ?? '';
    // NOVO
    dfdTipoObraValue = obj['tipoObra'];

    final loc = sections['localizacao'] ?? const {};
    dfdUFCtrl.text = loc['uf'] ?? '';
    dfdMunicipioCtrl.text = loc['municipio'] ?? '';

    // rodovia compat + novos campos
    final legacyRoadLabel = loc['rodovia'] as String?;
    roadId = loc['roadId'] as String?;
    roadName = (loc['roadName'] as String?) ?? legacyRoadLabel;
    dfdRodoviaId = roadId; // <- garante selectedId
    dfdRodoviaCtrl.text = roadName ?? legacyRoadLabel ?? '';

    dfdKmInicialCtrl.text = loc['kmInicial'] ?? '';
    dfdKmFinalCtrl.text = loc['kmFinal'] ?? '';
    dfdNaturezaIntervencaoValue = loc['naturezaIntervencao'];
    dfdPrazoExecucaoDiasCtrl.text = loc['prazoExecucaoDias'] ?? '';
    dfdVigenciaMesesCtrl.text = loc['vigenciaMeses'] ?? '';
    // NOVO
    dfdExtensaoKmCtrl.text = loc['extensaoKm'] ?? '';

    final est = sections['estimativa'] ?? const {};
    // IDs + labels
    fundingSourceId = est['fundingSourceId'];
    programId       = est['programId'];
    expenseNatureId = est['expenseNatureId'];
    dfdFonteRecursoCtrl.text = est['fonteRecurso'] ?? '';
    dfdProgramaTrabalhoCtrl.text = est['programaTrabalho'] ?? '';
    dfdPtresCtrl.text = est['ptres'] ?? '';
    dfdNaturezaDespesaCtrl.text = est['naturezaDespesa'] ?? '';
    dfdEstimativaValorCtrl.text = est['estimativaValor'] ?? '';
    dfdMetodologiaEstimativaCtrl.text = est['metodologiaEstimativa'] ?? '';

    final rk = sections['riscos'] ?? const {};
    dfdRiscosPrincipaisCtrl.text = rk['riscos'] ?? '';
    dfdImpactoNaoContratarCtrl.text = rk['impactoNaoContratar'] ?? '';
    dfdPrioridadeValue = rk['prioridade'];
    dfdDataLimiteUrgenciaCtrl.text = rk['dataLimite'] ?? '';
    dfdMotivacaoLegalCtrl.text = rk['motivacaoLegal'] ?? '';
    dfdAmparoNormativoCtrl.text = rk['amparoNormativo'] ?? '';

    final doc = sections['documentos'] ?? const {};
    dfdEtpAnexoValue = doc['etpAnexo'];
    dfdProjetoBasicoValue = doc['projetoBasico'];
    dfdTermoMatrizRiscosValue = doc['termoMatrizRiscos'];
    dfdParecerJuridicoValue = doc['parecerJuridico'];
    dfdAutorizacaoAberturaValue = doc['autorizacaoAbertura'];
    dfdLinksDocumentosCtrl.text = doc['linksDocumentos'] ?? '';

    final ap = sections['aprovacao'] ?? const {};
    dfdAutoridadeAprovadoraCtrl.text = ap['autoridadeAprovadora'] ?? '';
    dfdAutoridadeAprovadoraUserId = ap['autoridadeUserId'];
    dfdCpfAutoridadeCtrl.text = ap['autoridadeCpf'] ?? '';
    dfdDataAprovacaoCtrl.text = ap['dataAprovacao'] ?? '';
    dfdParecerResumoCtrl.text = ap['parecerResumo'] ?? '';

    final ob = sections['observacoes'] ?? const {};
    dfdObservacoesCtrl.text = ob['observacoes'] ?? '';

    companyNonce++;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      dfdOrgaoDemandanteCtrl,
      dfdUnidadeSolicitanteCtrl,
      dfdRegionalCtrl,
      dfdSolicitanteCtrl,
      dfdCpfSolicitanteCtrl,
      dfdCargoSolicitanteCtrl,
      dfdEmailSolicitanteCtrl,
      dfdTelefoneSolicitanteCtrl,
      dfdDataSolicitacaoCtrl,
      dfdProtocoloSeiCtrl,
      dfdDescricaoObjetoCtrl,
      dfdJustificativaCtrl,
      dfdUFCtrl,
      dfdMunicipioCtrl,
      dfdRodoviaCtrl,
      dfdKmInicialCtrl,
      dfdKmFinalCtrl,
      dfdPrazoExecucaoDiasCtrl,
      dfdVigenciaMesesCtrl,
      dfdFonteRecursoCtrl,
      dfdProgramaTrabalhoCtrl,
      dfdPtresCtrl,
      dfdNaturezaDespesaCtrl,
      dfdEstimativaValorCtrl,
      dfdMetodologiaEstimativaCtrl,
      dfdRiscosPrincipaisCtrl,
      dfdImpactoNaoContratarCtrl,
      dfdDataLimiteUrgenciaCtrl,
      dfdMotivacaoLegalCtrl,
      dfdAmparoNormativoCtrl,
      dfdLinksDocumentosCtrl,
      dfdAutoridadeAprovadoraCtrl,
      dfdCpfAutoridadeCtrl,
      dfdDataAprovacaoCtrl,
      dfdParecerResumoCtrl,

      // NOVOS
      dfdNumeroProcessoCtrl,
      dfdExtensaoKmCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }
}
