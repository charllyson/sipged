import 'package:flutter/material.dart';

class MinutaContratoController extends ChangeNotifier {
  bool isEditable;
  MinutaContratoController({this.isEditable = true});

  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  // ==== 1) Identificação da Minuta ====
  final mcNumeroCtrl = TextEditingController();
  final mcVersaoCtrl = TextEditingController();
  final mcDataElaboracaoCtrl = TextEditingController(); // dd/mm/aaaa

  // ==== 2) Partes e Objeto ====
  final mcContratanteCtrl = TextEditingController();
  final mcContratadaRazaoCtrl = TextEditingController();
  final mcContratadaCnpjCtrl = TextEditingController();
  final mcObjetoResumoCtrl = TextEditingController();

  // ==== 3) Valor ====
  final mcValorGlobalCtrl = TextEditingController();

  // ==== 4) Gestão e Referências ====
  final mcGestorCtrl = TextEditingController();
  String? mcGestorUserId;

  final mcFiscalCtrl = TextEditingController();
  String? mcFiscalUserId;

  final mcLinksAnexosCtrl = TextEditingController();
  String? mcRegimeExecucaoRef; // só leitura (virá do TR)
  String? mcPrazosRef;         // só leitura (virá do TR)

  // ───────── (de)serialização ─────────
  Map<String, Map<String, dynamic>> toSectionMaps() => {
    'identificacao': {
      'numero': mcNumeroCtrl.text,
      'versao': mcVersaoCtrl.text,
      'dataElaboracao': mcDataElaboracaoCtrl.text,
    },
    'partes_objeto': {
      'contratante': mcContratanteCtrl.text,
      'contratadaRazao': mcContratadaRazaoCtrl.text,
      'contratadaCnpj': mcContratadaCnpjCtrl.text,
      'objetoResumo': mcObjetoResumoCtrl.text,
    },
    'valor': {
      'valorGlobal': mcValorGlobalCtrl.text,
    },
    'gestao_refs': {
      'gestorNome': mcGestorCtrl.text,
      'gestorUserId': mcGestorUserId,
      'fiscalNome': mcFiscalCtrl.text,
      'fiscalUserId': mcFiscalUserId,
      'linksAnexos': mcLinksAnexosCtrl.text,
      'regimeExecucaoRef': mcRegimeExecucaoRef,
      'prazosRef': mcPrazosRef,
    },
  };

  bool _looksUid(String? v) => v != null && v.trim().length >= 20 && !v.contains(' ');

  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    final id = sections['identificacao'] ?? const {};
    mcNumeroCtrl.text = id['numero'] ?? '';
    mcVersaoCtrl.text = id['versao'] ?? '';
    mcDataElaboracaoCtrl.text = id['dataElaboracao'] ?? '';

    final po = sections['partes_objeto'] ?? const {};
    mcContratanteCtrl.text = po['contratante'] ?? '';
    mcContratadaRazaoCtrl.text = po['contratadaRazao'] ?? '';
    mcContratadaCnpjCtrl.text = po['contratadaCnpj'] ?? '';
    mcObjetoResumoCtrl.text = po['objetoResumo'] ?? '';

    final v = sections['valor'] ?? const {};
    mcValorGlobalCtrl.text = v['valorGlobal'] ?? '';

    final g = sections['gestao_refs'] ?? const {};
    mcGestorUserId = g['gestorUserId'] ?? (_looksUid(g['gestorNome']) ? g['gestorNome'] : null);
    mcGestorCtrl.text = _looksUid(g['gestorNome']) ? '' : (g['gestorNome'] ?? '');

    mcFiscalUserId = g['fiscalUserId'] ?? (_looksUid(g['fiscalNome']) ? g['fiscalNome'] : null);
    mcFiscalCtrl.text = _looksUid(g['fiscalNome']) ? '' : (g['fiscalNome'] ?? '');

    mcLinksAnexosCtrl.text = g['linksAnexos'] ?? '';
    mcRegimeExecucaoRef = g['regimeExecucaoRef'];
    mcPrazosRef = g['prazosRef'];

    notifyListeners();
  }

  String? quickValidate() {
    if (mcNumeroCtrl.text.trim().isEmpty) return 'Informe o Nº da minuta.';
    if (mcDataElaboracaoCtrl.text.trim().isEmpty) return 'Informe a data de elaboração.';
    if (mcContratanteCtrl.text.trim().isEmpty) return 'Informe o contratante.';
    if (mcContratadaRazaoCtrl.text.trim().isEmpty) return 'Informe a razão social da contratada.';
    if (mcContratadaCnpjCtrl.text.trim().isEmpty) return 'Informe o CNPJ da contratada.';
    if (mcObjetoResumoCtrl.text.trim().isEmpty) return 'Informe o objeto (resumo).';
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      mcNumeroCtrl, mcVersaoCtrl, mcDataElaboracaoCtrl,
      mcContratanteCtrl, mcContratadaRazaoCtrl, mcContratadaCnpjCtrl, mcObjetoResumoCtrl,
      mcValorGlobalCtrl,
      mcGestorCtrl, mcFiscalCtrl, mcLinksAnexosCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }
}
