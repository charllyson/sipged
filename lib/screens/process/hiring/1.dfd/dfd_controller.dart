import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para o Documento de Formalização de Demanda (DFD).
/// - Sem dependência de Firebase.
/// - Possui campos básicos + métodos utilitários para fluxo.
/// - Use temporariamente até integrar ao seu ContractsController “real”.
class DfdController extends ChangeNotifier {
  // ---- estado geral ----
  bool isEditable;

  // ==== 1) Identificação ====
  final dfdOrgaoDemandanteCtrl = TextEditingController();
  final dfdUnidadeSolicitanteCtrl = TextEditingController();
  String? dfdRegionalValue;
  final List<String> dfdRegionaisOptions = const [
    'Sede', '1ª Regional', '2ª Regional', '3ª Regional'
  ];
  final dfdSolicitanteCtrl = TextEditingController(); // (Autocomplete fake)
  String? dfdSolicitanteUserId;
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
  String? dfdEtpAnexoValue;            // Sim/Não/N/A
  String? dfdProjetoBasicoValue;       // Sim/Não/N/A
  String? dfdTermoMatrizRiscosValue;   // Sim/Não/N/A
  String? dfdParecerJuridicoValue;     // Sim/Não/N/A
  String? dfdAutorizacaoAberturaValue; // Sim/Não/N/A
  final dfdLinksDocumentosCtrl = TextEditingController();

  // ==== 7) Aprovação / Alçada ====
  final dfdAutoridadeAprovadoraCtrl = TextEditingController(); // (Autocomplete fake)
  String? dfdAutoridadeAprovadoraUserId;
  final dfdCpfAutoridadeCtrl = TextEditingController();
  final dfdDataAprovacaoCtrl = TextEditingController();
  final dfdParecerResumoCtrl = TextEditingController();

  // ==== 8) Observações ====
  final dfdObservacoesCtrl = TextEditingController();

  DfdController({this.isEditable = true});

  // --- helpers de fluxo ---
  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  /// Inicializa com valores de exemplo para testar renderização/validação.
  void initWithMock() {
    dfdOrgaoDemandanteCtrl.text = 'DER/AL';
    dfdUnidadeSolicitanteCtrl.text = 'Gerência de Obras';
    dfdRegionalValue = dfdRegionaisOptions.first;
    dfdSolicitanteCtrl.text = 'João da Silva (uid:abc)';
    dfdSolicitanteUserId = 'abc';
    dfdCpfSolicitanteCtrl.text = '123.456.789-00';
    dfdCargoSolicitanteCtrl.text = 'Engenheiro Fiscal';
    dfdEmailSolicitanteCtrl.text = 'joao.silva@der.al.gov.br';
    dfdTelefoneSolicitanteCtrl.text = '(82) 98888-7777';
    dfdDataSolicitacaoCtrl.text = '24/09/2025';
    dfdProtocoloSeiCtrl.text = '64000.000000/2025-11';

    dfdTipoContratacaoValue = 'Obra de engenharia';
    dfdModalidadeEstimativaValue = 'Concorrência';
    dfdRegimeExecucaoValue = 'Preço global';
    dfdDescricaoObjetoCtrl.text = 'Restauração do pavimento e sinalização.';
    dfdJustificativaCtrl.text = 'Condições de segurança e trafegabilidade comprometidas.';

    dfdUFCtrl.text = 'AL';
    dfdMunicipioCtrl.text = 'Maceió';
    dfdRodoviaCtrl.text = 'AL-101 SUL';
    dfdKmInicialCtrl.text = '0';
    dfdKmFinalCtrl.text = '12.5';
    dfdNaturezaIntervencaoValue = 'Restauração';
    dfdPrazoExecucaoDiasCtrl.text = '180';
    dfdVigenciaMesesCtrl.text = '12';

    dfdFonteRecursoCtrl.text = 'Tesouro Estadual';
    dfdProgramaTrabalhoCtrl.text = 'Programa de Conservação';
    dfdPtresCtrl.text = '12345';
    dfdNaturezaDespesaCtrl.text = '44.90.51';
    dfdEstimativaValorCtrl.text = '12.500.000,00';
    dfdMetodologiaEstimativaCtrl.text = 'SINAPI + DER referência';

    dfdRiscosPrincipaisCtrl.text = 'Chuvas intensas; desapropriações pontuais.';
    dfdImpactoNaoContratarCtrl.text = 'Aumento de acidentes e custo de manutenção.';
    dfdPrioridadeValue = 'Alta';
    dfdDataLimiteUrgenciaCtrl.text = '31/12/2025';
    dfdMotivacaoLegalCtrl.text = 'Decisão judicial 0001234-56.2025.8.02.0001';
    dfdAmparoNormativoCtrl.text = 'Lei 14.133/2021';

    dfdEtpAnexoValue = 'Sim';
    dfdProjetoBasicoValue = 'Não';
    dfdTermoMatrizRiscosValue = 'Sim';
    dfdParecerJuridicoValue = 'N/A';
    dfdAutorizacaoAberturaValue = 'Sim';
    dfdLinksDocumentosCtrl.text = 'SEI: link; Storage: link';

    dfdAutoridadeAprovadoraCtrl.text = 'Maria Souza (uid:def)';
    dfdAutoridadeAprovadoraUserId = 'def';
    dfdCpfAutoridadeCtrl.text = '987.654.321-00';
    dfdDataAprovacaoCtrl.text = '30/09/2025';
    dfdParecerResumoCtrl.text = 'Aprovado para instrução do processo licitatório.';

    dfdObservacoesCtrl.text = 'Incluir condicionantes ambientais no TR.';
    notifyListeners();
  }

  /// Validação mínima para “ver fluxo” (só checa campos críticos).
  /// Retorna null se estiver ok; caso contrário, uma mensagem de erro.
  String? quickValidate() {
    if (dfdOrgaoDemandanteCtrl.text.trim().isEmpty) {
      return 'Informe o órgão demandante.';
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

  /// Simula um “salvar” (aqui apenas retorna o map). Integre com Firestore depois.
  Map<String, dynamic> save() {
    final error = quickValidate();
    if (error != null) {
      throw StateError(error);
    }
    final map = toMap();
    // Aqui você chamaria seu repositório. Por enquanto, só retorna o map.
    return map;
  }

  Map<String, dynamic> toMap() => {
    // 1) Identificação
    'orgaoDemandante': dfdOrgaoDemandanteCtrl.text,
    'unidadeSolicitante': dfdUnidadeSolicitanteCtrl.text,
    'regional': dfdRegionalValue,
    'solicitanteNome': dfdSolicitanteCtrl.text,
    'solicitanteUserId': dfdSolicitanteUserId,
    'solicitanteCpf': dfdCpfSolicitanteCtrl.text,
    'solicitanteCargo': dfdCargoSolicitanteCtrl.text,
    'solicitanteEmail': dfdEmailSolicitanteCtrl.text,
    'solicitanteTelefone': dfdTelefoneSolicitanteCtrl.text,
    'dataSolicitacao': dfdDataSolicitacaoCtrl.text,
    'protocoloSei': dfdProtocoloSeiCtrl.text,

    // 2) Objeto
    'tipoContratacao': dfdTipoContratacaoValue,
    'modalidadeEstimativa': dfdModalidadeEstimativaValue,
    'regimeExecucao': dfdRegimeExecucaoValue,
    'descricaoObjeto': dfdDescricaoObjetoCtrl.text,
    'justificativa': dfdJustificativaCtrl.text,

    // 3) Localização
    'uf': dfdUFCtrl.text,
    'municipio': dfdMunicipioCtrl.text,
    'rodovia': dfdRodoviaCtrl.text,
    'kmInicial': dfdKmInicialCtrl.text,
    'kmFinal': dfdKmFinalCtrl.text,
    'naturezaIntervencao': dfdNaturezaIntervencaoValue,
    'prazoExecucaoDias': dfdPrazoExecucaoDiasCtrl.text,
    'vigenciaMeses': dfdVigenciaMesesCtrl.text,

    // 4) Orçamento
    'fonteRecurso': dfdFonteRecursoCtrl.text,
    'programaTrabalho': dfdProgramaTrabalhoCtrl.text,
    'ptres': dfdPtresCtrl.text,
    'naturezaDespesa': dfdNaturezaDespesaCtrl.text,
    'estimativaValor': dfdEstimativaValorCtrl.text,
    'metodologiaEstimativa': dfdMetodologiaEstimativaCtrl.text,

    // 5) Riscos
    'riscos': dfdRiscosPrincipaisCtrl.text,
    'impactoNaoContratar': dfdImpactoNaoContratarCtrl.text,
    'prioridade': dfdPrioridadeValue,
    'dataLimite': dfdDataLimiteUrgenciaCtrl.text,
    'motivacaoLegal': dfdMotivacaoLegalCtrl.text,
    'amparoNormativo': dfdAmparoNormativoCtrl.text,

    // 6) Docs
    'etpAnexo': dfdEtpAnexoValue,
    'projetoBasico': dfdProjetoBasicoValue,
    'termoMatrizRiscos': dfdTermoMatrizRiscosValue,
    'parecerJuridico': dfdParecerJuridicoValue,
    'autorizacaoAbertura': dfdAutorizacaoAberturaValue,
    'linksDocumentos': dfdLinksDocumentosCtrl.text,

    // 7) Aprovação
    'autoridadeAprovadora': dfdAutoridadeAprovadoraCtrl.text,
    'autoridadeUserId': dfdAutoridadeAprovadoraUserId,
    'autoridadeCpf': dfdCpfAutoridadeCtrl.text,
    'dataAprovacao': dfdDataAprovacaoCtrl.text,
    'parecerResumo': dfdParecerResumoCtrl.text,

    // 8) Observações
    'observacoes': dfdObservacoesCtrl.text,
  };

  void fromMap(Map<String, dynamic> map) {
    dfdOrgaoDemandanteCtrl.text = map['orgaoDemandante'] ?? '';
    dfdUnidadeSolicitanteCtrl.text = map['unidadeSolicitante'] ?? '';
    dfdRegionalValue = map['regional'];
    dfdSolicitanteCtrl.text = map['solicitanteNome'] ?? '';
    dfdSolicitanteUserId = map['solicitanteUserId'];
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
    dfdRodoviaCtrl.text = map['rodovia'] ?? '';
    dfdKmInicialCtrl.text = map['kmInicial'] ?? '';
    dfdKmFinalCtrl.text = map['kmFinal'] ?? '';
    dfdNaturezaIntervencaoValue = map['naturezaIntervencao'];
    dfdPrazoExecucaoDiasCtrl.text = map['prazoExecucaoDias'] ?? '';
    dfdVigenciaMesesCtrl.text = map['vigenciaMeses'] ?? '';

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
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      dfdOrgaoDemandanteCtrl,
      dfdUnidadeSolicitanteCtrl,
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
      dfdObservacoesCtrl,
    ]) {
      ctrl.clear();
    }
    dfdRegionalValue = null;
    dfdSolicitanteUserId = null;
    dfdTipoContratacaoValue = null;
    dfdModalidadeEstimativaValue = null;
    dfdRegimeExecucaoValue = null;
    dfdNaturezaIntervencaoValue = null;
    dfdPrioridadeValue = null;
    dfdEtpAnexoValue = null;
    dfdProjetoBasicoValue = null;
    dfdTermoMatrizRiscosValue = null;
    dfdParecerJuridicoValue = null;
    dfdAutorizacaoAberturaValue = null;
    dfdAutoridadeAprovadoraUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    // Libera todos os controllers
    for (final ctrl in [
      dfdOrgaoDemandanteCtrl,
      dfdUnidadeSolicitanteCtrl,
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
      dfdObservacoesCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }
}
