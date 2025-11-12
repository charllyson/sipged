import 'package:flutter/material.dart';
import 'cotacao_sections.dart';

class CotacaoController extends ChangeNotifier {
  bool isEditable = true;

  // ===== 1) Metadados =====
  final ctNumeroCtrl = TextEditingController();
  final ctDataAberturaCtrl = TextEditingController();
  final ctDataEncerramentoCtrl = TextEditingController();
  final ctResponsavelCtrl = TextEditingController();
  String? ctResponsavelUserId;
  final ctMetodologiaCtrl = TextEditingController();

  // ===== 2) Objeto/Itens (resumo) =====
  final ctObjetoCtrl = TextEditingController();
  final ctUnidadeMedidaCtrl = TextEditingController();
  final ctQuantidadeCtrl = TextEditingController();
  final ctEspecificacoesCtrl = TextEditingController();

  // ===== 3) Convite/Divulgação =====
  final ctMeioDivulgacaoCtrl = TextEditingController();
  final ctFornecedoresConvidadosCtrl = TextEditingController();
  final ctPrazoRespostaCtrl = TextEditingController();

  // ===== 4) Respostas dos Fornecedores (até 3) =====
  final f1NomeCtrl = TextEditingController();
  final f1CnpjCtrl = TextEditingController();
  final f1ValorCtrl = TextEditingController();
  final f1DataRecebimentoCtrl = TextEditingController();
  final f1LinkPropostaCtrl = TextEditingController();

  final f2NomeCtrl = TextEditingController();
  final f2CnpjCtrl = TextEditingController();
  final f2ValorCtrl = TextEditingController();
  final f2DataRecebimentoCtrl = TextEditingController();
  final f2LinkPropostaCtrl = TextEditingController();

  final f3NomeCtrl = TextEditingController();
  final f3CnpjCtrl = TextEditingController();
  final f3ValorCtrl = TextEditingController();
  final f3DataRecebimentoCtrl = TextEditingController();
  final f3LinkPropostaCtrl = TextEditingController();

  // ===== Empresa vencedora =====
  final vEmpresaLiderCtrl = TextEditingController();
  final vConsorcioEnvolvidasCtrl = TextEditingController();

  // ===== 5) Consolidação/Resultado =====
  final ctCriterioConsolidacaoCtrl = TextEditingController();
  final ctValorConsolidadoCtrl = TextEditingController();
  final ctObservacoesCtrl = TextEditingController();

  // ===== 6) Anexos/Evidências =====
  final ctLinksAnexosCtrl = TextEditingController();

  // ───────────────────────── helpers ─────────────────────────
  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  String? quickValidate() {
    if (ctNumeroCtrl.text.trim().isEmpty) return 'Informe o nº da cotação.';
    if (ctDataAberturaCtrl.text.trim().isEmpty) return 'Informe a data de abertura.';
    if (ctMetodologiaCtrl.text.trim().isEmpty) return 'Selecione a metodologia.';
    if (ctObjetoCtrl.text.trim().isEmpty) return 'Informe o objeto/escopo.';
    return null;
  }

  // ────────────────────── (de)serialização POR SEÇÃO ──────────────────────
  Map<String, Map<String, dynamic>> toSectionMaps() => {
    CotacaoSections.metadados: {
      'numero': ctNumeroCtrl.text,
      'dataAbertura': ctDataAberturaCtrl.text,
      'dataEncerramento': ctDataEncerramentoCtrl.text,
      'responsavelNome': ctResponsavelCtrl.text,
      'responsavelUserId': ctResponsavelUserId,
      'metodologia': ctMetodologiaCtrl.text,
    },
    CotacaoSections.objetoItens: {
      'objeto': ctObjetoCtrl.text,
      'unidadeMedida': ctUnidadeMedidaCtrl.text,
      'quantidade': ctQuantidadeCtrl.text,
      'especificacoes': ctEspecificacoesCtrl.text,
    },
    CotacaoSections.conviteDivulgacao: {
      'meioDivulgacao': ctMeioDivulgacaoCtrl.text,
      'fornecedoresConvidados': ctFornecedoresConvidadosCtrl.text,
      'prazoResposta': ctPrazoRespostaCtrl.text,
    },
    CotacaoSections.respostasFornecedores: {
      // fornecedor 1
      'f1Nome': f1NomeCtrl.text,
      'f1Cnpj': f1CnpjCtrl.text,
      'f1Valor': f1ValorCtrl.text,
      'f1DataRecebimento': f1DataRecebimentoCtrl.text,
      'f1LinkProposta': f1LinkPropostaCtrl.text,
      // fornecedor 2
      'f2Nome': f2NomeCtrl.text,
      'f2Cnpj': f2CnpjCtrl.text,
      'f2Valor': f2ValorCtrl.text,
      'f2DataRecebimento': f2DataRecebimentoCtrl.text,
      'f2LinkProposta': f2LinkPropostaCtrl.text,
      // fornecedor 3
      'f3Nome': f3NomeCtrl.text,
      'f3Cnpj': f3CnpjCtrl.text,
      'f3Valor': f3ValorCtrl.text,
      'f3DataRecebimento': f3DataRecebimentoCtrl.text,
      'f3LinkProposta': f3LinkPropostaCtrl.text,
    },
    CotacaoSections.vencedora: {
      'empresaLider': vEmpresaLiderCtrl.text,
      'consorcioEnvolvidas': vConsorcioEnvolvidasCtrl.text,
    },
    CotacaoSections.consolidacaoResultado: {
      'criterioConsolidacao': ctCriterioConsolidacaoCtrl.text,
      'valorConsolidado': ctValorConsolidadoCtrl.text,
      'observacoes': ctObservacoesCtrl.text,
    },
    CotacaoSections.anexosEvidencias: {
      'linksAnexos': ctLinksAnexosCtrl.text,
    },
  };

  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    String get(String sec, String key) => sections[sec]?[key]?.toString() ?? '';

    // 1) Metadados
    ctNumeroCtrl.text           = get(CotacaoSections.metadados, 'numero');
    ctDataAberturaCtrl.text     = get(CotacaoSections.metadados, 'dataAbertura');
    ctDataEncerramentoCtrl.text = get(CotacaoSections.metadados, 'dataEncerramento');
    ctResponsavelCtrl.text      = get(CotacaoSections.metadados, 'responsavelNome');
    ctResponsavelUserId         = sections[CotacaoSections.metadados]?['responsavelUserId'];
    ctMetodologiaCtrl.text      = get(CotacaoSections.metadados, 'metodologia');

    // 2) Objeto/Itens
    ctObjetoCtrl.text           = get(CotacaoSections.objetoItens, 'objeto');
    ctUnidadeMedidaCtrl.text    = get(CotacaoSections.objetoItens, 'unidadeMedida');
    ctQuantidadeCtrl.text       = get(CotacaoSections.objetoItens, 'quantidade');
    ctEspecificacoesCtrl.text   = get(CotacaoSections.objetoItens, 'especificacoes');

    // 3) Convite/Divulgação
    ctMeioDivulgacaoCtrl.text          = get(CotacaoSections.conviteDivulgacao, 'meioDivulgacao');
    ctFornecedoresConvidadosCtrl.text  = get(CotacaoSections.conviteDivulgacao, 'fornecedoresConvidados');
    ctPrazoRespostaCtrl.text           = get(CotacaoSections.conviteDivulgacao, 'prazoResposta');

    // 4) Fornecedores
    f1NomeCtrl.text            = get(CotacaoSections.respostasFornecedores, 'f1Nome');
    f1CnpjCtrl.text            = get(CotacaoSections.respostasFornecedores, 'f1Cnpj');
    f1ValorCtrl.text           = get(CotacaoSections.respostasFornecedores, 'f1Valor');
    f1DataRecebimentoCtrl.text = get(CotacaoSections.respostasFornecedores, 'f1DataRecebimento');
    f1LinkPropostaCtrl.text    = get(CotacaoSections.respostasFornecedores, 'f1LinkProposta');

    f2NomeCtrl.text            = get(CotacaoSections.respostasFornecedores, 'f2Nome');
    f2CnpjCtrl.text            = get(CotacaoSections.respostasFornecedores, 'f2Cnpj');
    f2ValorCtrl.text           = get(CotacaoSections.respostasFornecedores, 'f2Valor');
    f2DataRecebimentoCtrl.text = get(CotacaoSections.respostasFornecedores, 'f2DataRecebimento');
    f2LinkPropostaCtrl.text    = get(CotacaoSections.respostasFornecedores, 'f2LinkProposta');

    f3NomeCtrl.text            = get(CotacaoSections.respostasFornecedores, 'f3Nome');
    f3CnpjCtrl.text            = get(CotacaoSections.respostasFornecedores, 'f3Cnpj');
    f3ValorCtrl.text           = get(CotacaoSections.respostasFornecedores, 'f3Valor');
    f3DataRecebimentoCtrl.text = get(CotacaoSections.respostasFornecedores, 'f3DataRecebimento');
    f3LinkPropostaCtrl.text    = get(CotacaoSections.respostasFornecedores, 'f3LinkProposta');

    // 5) Vencedora
    vEmpresaLiderCtrl.text         = get(CotacaoSections.vencedora, 'empresaLider');
    vConsorcioEnvolvidasCtrl.text  = get(CotacaoSections.vencedora, 'consorcioEnvolvidas');

    // 6) Consolidação/Resultado
    ctCriterioConsolidacaoCtrl.text = get(CotacaoSections.consolidacaoResultado, 'criterioConsolidacao');
    ctValorConsolidadoCtrl.text     = get(CotacaoSections.consolidacaoResultado, 'valorConsolidado');
    ctObservacoesCtrl.text          = get(CotacaoSections.consolidacaoResultado, 'observacoes');

    // 7) Anexos
    ctLinksAnexosCtrl.text = get(CotacaoSections.anexosEvidencias, 'linksAnexos');

    notifyListeners();
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toSectionMaps()
        .values
        .expand((m) => m.entries)
        .fold<Map<String, dynamic>>({}, (acc, it) {
      acc[it.key] = it.value;
      return acc;
    });
  }

  void clear() {
    for (final ctrl in [
      ctNumeroCtrl, ctDataAberturaCtrl, ctDataEncerramentoCtrl, ctResponsavelCtrl,
      ctMetodologiaCtrl, ctObjetoCtrl, ctUnidadeMedidaCtrl, ctQuantidadeCtrl,
      ctEspecificacoesCtrl, ctMeioDivulgacaoCtrl, ctFornecedoresConvidadosCtrl,
      ctPrazoRespostaCtrl, f1NomeCtrl, f1CnpjCtrl, f1ValorCtrl, f1DataRecebimentoCtrl,
      f1LinkPropostaCtrl, f2NomeCtrl, f2CnpjCtrl, f2ValorCtrl, f2DataRecebimentoCtrl,
      f2LinkPropostaCtrl, f3NomeCtrl, f3CnpjCtrl, f3ValorCtrl, f3DataRecebimentoCtrl,
      f3LinkPropostaCtrl, vEmpresaLiderCtrl, vConsorcioEnvolvidasCtrl,
      ctCriterioConsolidacaoCtrl, ctValorConsolidadoCtrl, ctObservacoesCtrl,
      ctLinksAnexosCtrl,
    ]) {
      ctrl.clear();
    }
    ctResponsavelUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      ctNumeroCtrl, ctDataAberturaCtrl, ctDataEncerramentoCtrl, ctResponsavelCtrl,
      ctMetodologiaCtrl, ctObjetoCtrl, ctUnidadeMedidaCtrl, ctQuantidadeCtrl,
      ctEspecificacoesCtrl, ctMeioDivulgacaoCtrl, ctFornecedoresConvidadosCtrl,
      ctPrazoRespostaCtrl, f1NomeCtrl, f1CnpjCtrl, f1ValorCtrl, f1DataRecebimentoCtrl,
      f1LinkPropostaCtrl, f2NomeCtrl, f2CnpjCtrl, f2ValorCtrl, f2DataRecebimentoCtrl,
      f2LinkPropostaCtrl, f3NomeCtrl, f3CnpjCtrl, f3ValorCtrl, f3DataRecebimentoCtrl,
      f3LinkPropostaCtrl, vEmpresaLiderCtrl, vConsorcioEnvolvidasCtrl,
      ctCriterioConsolidacaoCtrl, ctValorConsolidadoCtrl, ctObservacoesCtrl,
      ctLinksAnexosCtrl,
    ]) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// Caso sua page use um “map geral”
  Map<String, Map<String, dynamic>> toMap() => toSectionMaps();

  /// (Opcional) hidratar a partir do ContractData
  void hydrateFromContractData(dynamic contractData) {/* no-op */}
}
