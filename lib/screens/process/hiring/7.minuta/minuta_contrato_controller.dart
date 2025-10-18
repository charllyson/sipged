import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para Minuta do Contrato (sem backend).
/// Dropdowns também usam TextEditingController (compatível com DropDownButtonChange).
class MinutaContratoController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Identificação
  final mcNumeroCtrl = TextEditingController();
  final mcVersaoCtrl = TextEditingController();
  final mcDataElaboracaoCtrl = TextEditingController();

  // 2) Partes/Objeto
  final mcContratanteCtrl = TextEditingController();
  final mcContratadaRazaoCtrl = TextEditingController();
  final mcContratadaCnpjCtrl = TextEditingController();
  final mcObjetoResumoCtrl = TextEditingController();

  // 3) Vigência/Regime/Valor
  final mcPrazoExecucaoDiasCtrl = TextEditingController();
  final mcVigenciaMesesCtrl = TextEditingController();
  final mcRegimeExecucaoCtrl = TextEditingController(); // DropDown
  final mcValorGlobalCtrl = TextEditingController();

  // 4) Reajuste/Garantia/Seguros
  final mcIndiceReajusteCtrl = TextEditingController(); // DropDown
  final mcGarantiaCtrl = TextEditingController();       // DropDown
  final mcSegurosObrigatoriosCtrl = TextEditingController();

  // 5) Gestão/Fiscalização/Pagamento
  final mcGestorCtrl = TextEditingController(); // Autocomplete fake
  String? mcGestorUserId;
  final mcFiscalCtrl = TextEditingController(); // Autocomplete fake
  String? mcFiscalUserId;
  final mcCriteriosMedicaoAceiteCtrl = TextEditingController();
  final mcCondicoesPagamentoCtrl = TextEditingController();

  // 6) Cláusulas especiais
  final mcMatrizRiscosCtrl = TextEditingController();
  final mcPenalidadesCtrl = TextEditingController();
  final mcForoCtrl = TextEditingController();

  // 7) Anexos/Referências
  final mcBaseDocumentalCtrl = TextEditingController(); // DropDown
  final mcLinksAnexosCtrl = TextEditingController();

  MinutaContratoController() {
    // Notifica mudanças quando campos que impactam resumos são alterados
    for (final ctrl in [
      mcPrazoExecucaoDiasCtrl,
      mcVigenciaMesesCtrl,
      mcRegimeExecucaoCtrl,
      mcValorGlobalCtrl,
    ]) {
      ctrl.addListener(notifyListeners);
    }
  }

  /// Texto resumido de prazos: "180 dias | Vigência 12 meses"
  String get mcPrazosRef {
    final dias = mcPrazoExecucaoDiasCtrl.text.trim();
    final meses = mcVigenciaMesesCtrl.text.trim();
    final p1 = dias.isEmpty ? '' : '$dias dias';
    final p2 = meses.isEmpty ? '' : 'Vigência $meses meses';
    if (p1.isEmpty && p2.isEmpty) return '';
    if (p1.isEmpty) return p2;
    if (p2.isEmpty) return p1;
    return '$p1 | $p2';
  }

  /// Apenas espelha o valor do dropdown de regime
  String get mcRegimeExecucaoRef => mcRegimeExecucaoCtrl.text.trim();

  // ----- MOCK -----
  void initWithMock() {
    mcNumeroCtrl.text = 'MIN-2025-001';
    mcVersaoCtrl.text = 'v1';
    mcDataElaboracaoCtrl.text = '24/09/2025';

    mcContratanteCtrl.text = 'DER/AL - Diretoria de Obras';
    mcContratadaRazaoCtrl.text = 'FC Empreendimentos Ltda.';
    mcContratadaCnpjCtrl.text = '12.345.678/0001-90';
    mcObjetoResumoCtrl.text =
    'Restauração de pavimento e melhoria de sinalização na AL-101, km 0–12,5.';

    mcPrazoExecucaoDiasCtrl.text = '180';
    mcVigenciaMesesCtrl.text = '12';
    mcRegimeExecucaoCtrl.text = 'Preço global';
    mcValorGlobalCtrl.text = '12.500.000,00';

    mcIndiceReajusteCtrl.text = 'IPCA';
    mcGarantiaCtrl.text = 'Seguro-garantia';
    mcSegurosObrigatoriosCtrl.text = 'Seguro de obras, RC e equipamentos.';

    mcGestorCtrl.text = 'Maria Souza (uid:def)'; mcGestorUserId = 'def';
    mcFiscalCtrl.text = 'João da Silva (uid:abc)'; mcFiscalUserId = 'abc';
    mcCriteriosMedicaoAceiteCtrl.text =
    'Boletins mensais; IRI, macrotextura e retrorrefletância.';
    mcCondicoesPagamentoCtrl.text = 'Pagamento em 30 dias após aceite.';

    mcMatrizRiscosCtrl.text = 'Chuvas; variação de CAP; interferências de terceiros.';
    mcPenalidadesCtrl.text = 'Multas, advertência, suspensão (Lei 14.133/2021).';
    mcForoCtrl.text = 'Comarca de Maceió/AL';

    mcBaseDocumentalCtrl.text = 'TR + ARP (adesão)';
    mcLinksAnexosCtrl.text =
    'SEI://TR.pdf; SEI://ETP.pdf; SEI://ARP19-2024.pdf; SEI://proposta.pdf; Drive://Documentos do Gestor';
    notifyListeners();
  }

  // ----- VALIDAÇÃO / PERSISTÊNCIA (fake) -----
  String? quickValidate() {
    if (mcNumeroCtrl.text.trim().isEmpty) return 'Informe o nº da minuta.';
    if (mcDataElaboracaoCtrl.text.trim().isEmpty) return 'Informe a data de elaboração.';
    if (mcContratadaRazaoCtrl.text.trim().isEmpty) return 'Informe a contratada.';
    if (mcContratadaCnpjCtrl.text.trim().isEmpty) return 'Informe o CNPJ da contratada.';
    if (mcObjetoResumoCtrl.text.trim().isEmpty) return 'Descreva o objeto.';
    if (mcRegimeExecucaoCtrl.text.trim().isEmpty) return 'Selecione o regime de execução.';
    if (mcValorGlobalCtrl.text.trim().isEmpty) return 'Informe o valor global.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    // 1
    'numero': mcNumeroCtrl.text,
    'versao': mcVersaoCtrl.text,
    'dataElaboracao': mcDataElaboracaoCtrl.text,

    // 2
    'contratante': mcContratanteCtrl.text,
    'contratadaRazao': mcContratadaRazaoCtrl.text,
    'contratadaCnpj': mcContratadaCnpjCtrl.text,
    'objetoResumo': mcObjetoResumoCtrl.text,

    // 3
    'prazoExecucaoDias': mcPrazoExecucaoDiasCtrl.text,
    'vigenciaMeses': mcVigenciaMesesCtrl.text,
    'regimeExecucao': mcRegimeExecucaoCtrl.text,
    'valorGlobal': mcValorGlobalCtrl.text,

    // 4
    'indiceReajuste': mcIndiceReajusteCtrl.text,
    'garantia': mcGarantiaCtrl.text,
    'segurosObrigatorios': mcSegurosObrigatoriosCtrl.text,

    // 5
    'gestorNome': mcGestorCtrl.text,
    'gestorUserId': mcGestorUserId,
    'fiscalNome': mcFiscalCtrl.text,
    'fiscalUserId': mcFiscalUserId,
    'criteriosMedicaoAceite': mcCriteriosMedicaoAceiteCtrl.text,
    'condicoesPagamento': mcCondicoesPagamentoCtrl.text,

    // 6
    'matrizRiscos': mcMatrizRiscosCtrl.text,
    'penalidades': mcPenalidadesCtrl.text,
    'foro': mcForoCtrl.text,

    // 7
    'baseDocumental': mcBaseDocumentalCtrl.text,
    'linksAnexos': mcLinksAnexosCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    mcNumeroCtrl.text = m['numero'] ?? '';
    mcVersaoCtrl.text = m['versao'] ?? '';
    mcDataElaboracaoCtrl.text = m['dataElaboracao'] ?? '';

    mcContratanteCtrl.text = m['contratante'] ?? '';
    mcContratadaRazaoCtrl.text = m['contratadaRazao'] ?? '';
    mcContratadaCnpjCtrl.text = m['contratadaCnpj'] ?? '';
    mcObjetoResumoCtrl.text = m['objetoResumo'] ?? '';

    mcPrazoExecucaoDiasCtrl.text = m['prazoExecucaoDias'] ?? '';
    mcVigenciaMesesCtrl.text = m['vigenciaMeses'] ?? '';
    mcRegimeExecucaoCtrl.text = m['regimeExecucao'] ?? '';
    mcValorGlobalCtrl.text = m['valorGlobal'] ?? '';

    mcIndiceReajusteCtrl.text = m['indiceReajuste'] ?? '';
    mcGarantiaCtrl.text = m['garantia'] ?? '';
    mcSegurosObrigatoriosCtrl.text = m['segurosObrigatorios'] ?? '';

    mcGestorCtrl.text = m['gestorNome'] ?? '';
    mcGestorUserId = m['gestorUserId'];
    mcFiscalCtrl.text = m['fiscalNome'] ?? '';
    mcFiscalUserId = m['fiscalUserId'];
    mcCriteriosMedicaoAceiteCtrl.text = m['criteriosMedicaoAceite'] ?? '';
    mcCondicoesPagamentoCtrl.text = m['condicoesPagamento'] ?? '';

    mcMatrizRiscosCtrl.text = m['matrizRiscos'] ?? '';
    mcPenalidadesCtrl.text = m['penalidades'] ?? '';
    mcForoCtrl.text = m['foro'] ?? '';

    mcBaseDocumentalCtrl.text = m['baseDocumental'] ?? '';
    mcLinksAnexosCtrl.text = m['linksAnexos'] ?? '';
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      mcNumeroCtrl, mcVersaoCtrl, mcDataElaboracaoCtrl,
      mcContratanteCtrl, mcContratadaRazaoCtrl, mcContratadaCnpjCtrl, mcObjetoResumoCtrl,
      mcPrazoExecucaoDiasCtrl, mcVigenciaMesesCtrl, mcRegimeExecucaoCtrl, mcValorGlobalCtrl,
      mcIndiceReajusteCtrl, mcGarantiaCtrl, mcSegurosObrigatoriosCtrl,
      mcGestorCtrl, mcFiscalCtrl, mcCriteriosMedicaoAceiteCtrl, mcCondicoesPagamentoCtrl,
      mcMatrizRiscosCtrl, mcPenalidadesCtrl, mcForoCtrl,
      mcBaseDocumentalCtrl, mcLinksAnexosCtrl,
    ]) {
      ctrl.clear();
    }
    mcGestorUserId = null;
    mcFiscalUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      mcNumeroCtrl, mcVersaoCtrl, mcDataElaboracaoCtrl,
      mcContratanteCtrl, mcContratadaRazaoCtrl, mcContratadaCnpjCtrl, mcObjetoResumoCtrl,
      mcPrazoExecucaoDiasCtrl, mcVigenciaMesesCtrl, mcRegimeExecucaoCtrl, mcValorGlobalCtrl,
      mcIndiceReajusteCtrl, mcGarantiaCtrl, mcSegurosObrigatoriosCtrl,
      mcGestorCtrl, mcFiscalCtrl, mcCriteriosMedicaoAceiteCtrl, mcCondicoesPagamentoCtrl,
      mcMatrizRiscosCtrl, mcPenalidadesCtrl, mcForoCtrl,
      mcBaseDocumentalCtrl, mcLinksAnexosCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }
}
