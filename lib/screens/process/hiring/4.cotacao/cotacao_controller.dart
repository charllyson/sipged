import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para a etapa de Cotação/Pesquisa de Preços.
/// - TUDO com TextEditingController (inclui dropdowns com controller).
class CotacaoController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Metadados
  final ctNumeroCtrl = TextEditingController();
  final ctDataAberturaCtrl = TextEditingController();
  final ctDataEncerramentoCtrl = TextEditingController();
  final ctResponsavelCtrl = TextEditingController(); // Autocomplete fake
  String? ctResponsavelUserId;
  final ctMetodologiaCtrl = TextEditingController(); // DropDown

  // 2) Objeto/Itens (resumo)
  final ctObjetoCtrl = TextEditingController();
  final ctUnidadeMedidaCtrl = TextEditingController();
  final ctQuantidadeCtrl = TextEditingController();
  final ctEspecificacoesCtrl = TextEditingController();

  // 3) Convite/Divulgação
  final ctMeioDivulgacaoCtrl = TextEditingController(); // DropDown
  final ctFornecedoresConvidadosCtrl = TextEditingController();
  final ctPrazoRespostaCtrl = TextEditingController();

  // 4) Respostas (até 3 fornecedores)
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

  // 5) Consolidação
  final ctCriterioConsolidacaoCtrl = TextEditingController(); // DropDown
  final ctValorConsolidadoCtrl = TextEditingController();
  final ctObservacoesCtrl = TextEditingController();

  // 6) Evidências/Anexos
  final ctLinksAnexosCtrl = TextEditingController();

  void initWithMock() {
    ctNumeroCtrl.text = 'COT-2025-004';
    ctDataAberturaCtrl.text = '24/09/2025';
    ctDataEncerramentoCtrl.text = '30/09/2025';
    ctResponsavelCtrl.text = 'Carla Menezes (uid:u1)'; ctResponsavelUserId = 'u1';
    ctMetodologiaCtrl.text = 'Misto';

    ctObjetoCtrl.text = 'Emulsão asfáltica e CBUQ para restauração AL-101.';
    ctUnidadeMedidaCtrl.text = 'ton';
    ctQuantidadeCtrl.text = '1200';
    ctEspecificacoesCtrl.text = 'CBUQ faixa C DNIT; CAP 50/70; transporte incluso.';

    ctMeioDivulgacaoCtrl.text = 'E-mail';
    ctFornecedoresConvidadosCtrl.text = 'Empresa A (00.000.000/0001-00); Empresa B (11.111.111/0001-11); Empresa C (22.222.222/0001-22)';
    ctPrazoRespostaCtrl.text = '29/09/2025 18:00';

    f1NomeCtrl.text = 'Empresa A'; f1CnpjCtrl.text = '00.000.000/0001-00';
    f1ValorCtrl.text = '8.400.000,00'; f1DataRecebimentoCtrl.text = '28/09/2025';
    f1LinkPropostaCtrl.text = 'SEI://propostaA';

    f2NomeCtrl.text = 'Empresa B'; f2CnpjCtrl.text = '11.111.111/0001-11';
    f2ValorCtrl.text = '8.750.000,00'; f2DataRecebimentoCtrl.text = '29/09/2025';
    f2LinkPropostaCtrl.text = 'SEI://propostaB';

    f3NomeCtrl.text = 'Empresa C'; f3CnpjCtrl.text = '22.222.222/0001-22';
    f3ValorCtrl.text = '8.620.000,00'; f3DataRecebimentoCtrl.text = '29/09/2025';
    f3LinkPropostaCtrl.text = 'SEI://propostaC';

    ctCriterioConsolidacaoCtrl.text = 'Mediana';
    ctValorConsolidadoCtrl.text = '8.620.000,00';
    ctObservacoesCtrl.text = 'Desclassificada A por ausência de atestado; usada mediana entre válidas.';

    ctLinksAnexosCtrl.text = 'Planilha: /storage/cotacao/planilha.xlsx; Prints Painel: /storage/cotacao/prints';
    notifyListeners();
  }

  String? quickValidate() {
    if (ctNumeroCtrl.text.trim().isEmpty) return 'Informe o Nº da cotação.';
    if (ctDataAberturaCtrl.text.trim().isEmpty) return 'Informe a data de abertura.';
    if (ctObjetoCtrl.text.trim().isEmpty) return 'Descreva o objeto.';
    if (ctMetodologiaCtrl.text.trim().isEmpty) return 'Selecione a metodologia.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    // 1) Metadados
    'numero': ctNumeroCtrl.text,
    'dataAbertura': ctDataAberturaCtrl.text,
    'dataEncerramento': ctDataEncerramentoCtrl.text,
    'responsavelNome': ctResponsavelCtrl.text,
    'responsavelUserId': ctResponsavelUserId,
    'metodologia': ctMetodologiaCtrl.text,

    // 2) Objeto/Itens
    'objeto': ctObjetoCtrl.text,
    'unidadeMedida': ctUnidadeMedidaCtrl.text,
    'quantidade': ctQuantidadeCtrl.text,
    'especificacoes': ctEspecificacoesCtrl.text,

    // 3) Divulgação
    'meioDivulgacao': ctMeioDivulgacaoCtrl.text,
    'fornecedoresConvidados': ctFornecedoresConvidadosCtrl.text,
    'prazoResposta': ctPrazoRespostaCtrl.text,

    // 4) Respostas
    'fornecedor1': {
      'nome': f1NomeCtrl.text,
      'cnpj': f1CnpjCtrl.text,
      'valor': f1ValorCtrl.text,
      'data': f1DataRecebimentoCtrl.text,
      'link': f1LinkPropostaCtrl.text,
    },
    'fornecedor2': {
      'nome': f2NomeCtrl.text,
      'cnpj': f2CnpjCtrl.text,
      'valor': f2ValorCtrl.text,
      'data': f2DataRecebimentoCtrl.text,
      'link': f2LinkPropostaCtrl.text,
    },
    'fornecedor3': {
      'nome': f3NomeCtrl.text,
      'cnpj': f3CnpjCtrl.text,
      'valor': f3ValorCtrl.text,
      'data': f3DataRecebimentoCtrl.text,
      'link': f3LinkPropostaCtrl.text,
    },

    // 5) Consolidação
    'criterioConsolidacao': ctCriterioConsolidacaoCtrl.text,
    'valorConsolidado': ctValorConsolidadoCtrl.text,
    'observacoes': ctObservacoesCtrl.text,

    // 6) Evidências
    'linksAnexos': ctLinksAnexosCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    ctNumeroCtrl.text = m['numero'] ?? '';
    ctDataAberturaCtrl.text = m['dataAbertura'] ?? '';
    ctDataEncerramentoCtrl.text = m['dataEncerramento'] ?? '';
    ctResponsavelCtrl.text = m['responsavelNome'] ?? '';
    ctResponsavelUserId = m['responsavelUserId'];
    ctMetodologiaCtrl.text = m['metodologia'] ?? '';

    ctObjetoCtrl.text = m['objeto'] ?? '';
    ctUnidadeMedidaCtrl.text = m['unidadeMedida'] ?? '';
    ctQuantidadeCtrl.text = m['quantidade'] ?? '';
    ctEspecificacoesCtrl.text = m['especificacoes'] ?? '';

    ctMeioDivulgacaoCtrl.text = m['meioDivulgacao'] ?? '';
    ctFornecedoresConvidadosCtrl.text = m['fornecedoresConvidados'] ?? '';
    ctPrazoRespostaCtrl.text = m['prazoResposta'] ?? '';

    final f1 = (m['fornecedor1'] as Map?) ?? {};
    f1NomeCtrl.text = f1['nome'] ?? '';
    f1CnpjCtrl.text = f1['cnpj'] ?? '';
    f1ValorCtrl.text = f1['valor'] ?? '';
    f1DataRecebimentoCtrl.text = f1['data'] ?? '';
    f1LinkPropostaCtrl.text = f1['link'] ?? '';

    final f2 = (m['fornecedor2'] as Map?) ?? {};
    f2NomeCtrl.text = f2['nome'] ?? '';
    f2CnpjCtrl.text = f2['cnpj'] ?? '';
    f2ValorCtrl.text = f2['valor'] ?? '';
    f2DataRecebimentoCtrl.text = f2['data'] ?? '';
    f2LinkPropostaCtrl.text = f2['link'] ?? '';

    final f3 = (m['fornecedor3'] as Map?) ?? {};
    f3NomeCtrl.text = f3['nome'] ?? '';
    f3CnpjCtrl.text = f3['cnpj'] ?? '';
    f3ValorCtrl.text = f3['valor'] ?? '';
    f3DataRecebimentoCtrl.text = f3['data'] ?? '';
    f3LinkPropostaCtrl.text = f3['link'] ?? '';

    ctCriterioConsolidacaoCtrl.text = m['criterioConsolidacao'] ?? '';
    ctValorConsolidadoCtrl.text = m['valorConsolidado'] ?? '';
    ctObservacoesCtrl.text = m['observacoes'] ?? '';

    ctLinksAnexosCtrl.text = m['linksAnexos'] ?? '';
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      ctNumeroCtrl, ctDataAberturaCtrl, ctDataEncerramentoCtrl,
      ctResponsavelCtrl, ctMetodologiaCtrl,
      ctObjetoCtrl, ctUnidadeMedidaCtrl, ctQuantidadeCtrl, ctEspecificacoesCtrl,
      ctMeioDivulgacaoCtrl, ctFornecedoresConvidadosCtrl, ctPrazoRespostaCtrl,
      f1NomeCtrl, f1CnpjCtrl, f1ValorCtrl, f1DataRecebimentoCtrl, f1LinkPropostaCtrl,
      f2NomeCtrl, f2CnpjCtrl, f2ValorCtrl, f2DataRecebimentoCtrl, f2LinkPropostaCtrl,
      f3NomeCtrl, f3CnpjCtrl, f3ValorCtrl, f3DataRecebimentoCtrl, f3LinkPropostaCtrl,
      ctCriterioConsolidacaoCtrl, ctValorConsolidadoCtrl, ctObservacoesCtrl,
      ctLinksAnexosCtrl,
    ]) { ctrl.clear(); }
    ctResponsavelUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      ctNumeroCtrl, ctDataAberturaCtrl, ctDataEncerramentoCtrl,
      ctResponsavelCtrl, ctMetodologiaCtrl,
      ctObjetoCtrl, ctUnidadeMedidaCtrl, ctQuantidadeCtrl, ctEspecificacoesCtrl,
      ctMeioDivulgacaoCtrl, ctFornecedoresConvidadosCtrl, ctPrazoRespostaCtrl,
      f1NomeCtrl, f1CnpjCtrl, f1ValorCtrl, f1DataRecebimentoCtrl, f1LinkPropostaCtrl,
      f2NomeCtrl, f2CnpjCtrl, f2ValorCtrl, f2DataRecebimentoCtrl, f2LinkPropostaCtrl,
      f3NomeCtrl, f3CnpjCtrl, f3ValorCtrl, f3DataRecebimentoCtrl, f3LinkPropostaCtrl,
      ctCriterioConsolidacaoCtrl, ctValorConsolidadoCtrl, ctObservacoesCtrl,
      ctLinksAnexosCtrl,
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
