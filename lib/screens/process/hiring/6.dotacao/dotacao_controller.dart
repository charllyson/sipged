import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para Dotação Orçamentária.
/// Usa TextEditingController inclusive para dropdowns.
class DotacaoController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Identificação
  final exercicioCtrl = TextEditingController();
  final processoSeiCtrl = TextEditingController();
  final responsavelOrcCtrl = TextEditingController(); // Autocomplete fake
  String? responsavelOrcUserId;

  // 2) Vinculação Programática
  final unidadeOrcCtrl = TextEditingController();
  final ugCtrl = TextEditingController();
  final programaCtrl = TextEditingController();
  final acaoCtrl = TextEditingController();
  final ptresCtrl = TextEditingController();
  final planoOrcCtrl = TextEditingController();
  final fonteRecursoCtrl = TextEditingController(); // DropDown

  // 3) Natureza da Despesa
  final modalidadeAplicacaoCtrl = TextEditingController();
  final elementoDespesaCtrl = TextEditingController();
  final subelementoCtrl = TextEditingController();
  final descricaoNdCtrl = TextEditingController();

  // 4) Reserva
  final reservaNumeroCtrl = TextEditingController();
  final reservaDataCtrl = TextEditingController();
  final reservaValorCtrl = TextEditingController();
  final reservaObservacoesCtrl = TextEditingController();

  // 5) Empenho
  final empenhoModalidadeCtrl = TextEditingController(); // DropDown
  final empenhoNumeroCtrl = TextEditingController();
  final empenhoDataCtrl = TextEditingController();
  final empenhoValorCtrl = TextEditingController();

  // 6) Desembolso
  final desembolsoPeriodicidadeCtrl = TextEditingController(); // DropDown
  final desembolsoMesesCtrl = TextEditingController();
  final desembolsoObservacoesCtrl = TextEditingController();

  // 7) Links
  final linksComprovacoesCtrl = TextEditingController();

  void initWithMock() {
    exercicioCtrl.text = '2025';
    processoSeiCtrl.text = 'SEI 64000.000000/2025-11';
    responsavelOrcCtrl.text = 'Ana Paula (uid:r1)'; responsavelOrcUserId = 'r1';

    unidadeOrcCtrl.text = 'DER/AL - UO 009';
    ugCtrl.text = 'UG 090001';
    programaCtrl.text = 'Programa 123 - Infraestrutura Viária';
    acaoCtrl.text = 'Ação 2001 - Manutenção de Rodovias';
    ptresCtrl.text = 'PTRES 123456; PI 78910';
    planoOrcCtrl.text = 'PO 0001';
    fonteRecursoCtrl.text = '0100 - Tesouro';

    modalidadeAplicacaoCtrl.text = '90';
    elementoDespesaCtrl.text = '44';
    subelementoCtrl.text = '45';
    descricaoNdCtrl.text = 'Obras e Instalações';

    reservaNumeroCtrl.text = 'RES-2025-00077';
    reservaDataCtrl.text = '15/04/2025';
    reservaValorCtrl.text = '8.750.000,00';
    reservaObservacoesCtrl.text = 'Reserva vinculada ao TR AL-101.';

    empenhoModalidadeCtrl.text = 'Global';
    empenhoNumeroCtrl.text = 'NE 2025NE000123';
    empenhoDataCtrl.text = '10/06/2025';
    empenhoValorCtrl.text = '8.750.000,00';

    desembolsoPeriodicidadeCtrl.text = 'Mensal';
    desembolsoMesesCtrl.text = 'Jul–Dez/2025';
    desembolsoObservacoesCtrl.text = 'Sujeito a liberação de cota.';

    linksComprovacoesCtrl.text = 'SIAF: prints; SEI: notas; Planilha: /storage/dotacao.xlsx';
    notifyListeners();
  }

  String? quickValidate() {
    if (exercicioCtrl.text.trim().isEmpty) return 'Informe o exercício.';
    if (processoSeiCtrl.text.trim().isEmpty) return 'Informe o nº do processo.';
    if (unidadeOrcCtrl.text.trim().isEmpty) return 'Informe a Unidade Orçamentária.';
    if (fonteRecursoCtrl.text.trim().isEmpty) return 'Informe a fonte de recurso.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    'exercicio': exercicioCtrl.text,
    'processoSei': processoSeiCtrl.text,
    'responsavelOrcNome': responsavelOrcCtrl.text,
    'responsavelOrcUserId': responsavelOrcUserId,

    'unidadeOrc': unidadeOrcCtrl.text,
    'ug': ugCtrl.text,
    'programa': programaCtrl.text,
    'acao': acaoCtrl.text,
    'ptres': ptresCtrl.text,
    'planoOrc': planoOrcCtrl.text,
    'fonteRecurso': fonteRecursoCtrl.text,

    'modalidadeAplicacao': modalidadeAplicacaoCtrl.text,
    'elementoDespesa': elementoDespesaCtrl.text,
    'subelemento': subelementoCtrl.text,
    'descricaoNd': descricaoNdCtrl.text,

    'reservaNumero': reservaNumeroCtrl.text,
    'reservaData': reservaDataCtrl.text,
    'reservaValor': reservaValorCtrl.text,
    'reservaObservacoes': reservaObservacoesCtrl.text,

    'empenhoModalidade': empenhoModalidadeCtrl.text,
    'empenhoNumero': empenhoNumeroCtrl.text,
    'empenhoData': empenhoDataCtrl.text,
    'empenhoValor': empenhoValorCtrl.text,

    'desembolsoPeriodicidade': desembolsoPeriodicidadeCtrl.text,
    'desembolsoMeses': desembolsoMesesCtrl.text,
    'desembolsoObservacoes': desembolsoObservacoesCtrl.text,

    'linksComprovacoes': linksComprovacoesCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    exercicioCtrl.text = m['exercicio'] ?? '';
    processoSeiCtrl.text = m['processoSei'] ?? '';
    responsavelOrcCtrl.text = m['responsavelOrcNome'] ?? '';
    responsavelOrcUserId = m['responsavelOrcUserId'];

    unidadeOrcCtrl.text = m['unidadeOrc'] ?? '';
    ugCtrl.text = m['ug'] ?? '';
    programaCtrl.text = m['programa'] ?? '';
    acaoCtrl.text = m['acao'] ?? '';
    ptresCtrl.text = m['ptres'] ?? '';
    planoOrcCtrl.text = m['planoOrc'] ?? '';
    fonteRecursoCtrl.text = m['fonteRecurso'] ?? '';

    modalidadeAplicacaoCtrl.text = m['modalidadeAplicacao'] ?? '';
    elementoDespesaCtrl.text = m['elementoDespesa'] ?? '';
    subelementoCtrl.text = m['subelemento'] ?? '';
    descricaoNdCtrl.text = m['descricaoNd'] ?? '';

    reservaNumeroCtrl.text = m['reservaNumero'] ?? '';
    reservaDataCtrl.text = m['reservaData'] ?? '';
    reservaValorCtrl.text = m['reservaValor'] ?? '';
    reservaObservacoesCtrl.text = m['reservaObservacoes'] ?? '';

    empenhoModalidadeCtrl.text = m['empenhoModalidade'] ?? '';
    empenhoNumeroCtrl.text = m['empenhoNumero'] ?? '';
    empenhoDataCtrl.text = m['empenhoData'] ?? '';
    empenhoValorCtrl.text = m['empenhoValor'] ?? '';

    desembolsoPeriodicidadeCtrl.text = m['desembolsoPeriodicidade'] ?? '';
    desembolsoMesesCtrl.text = m['desembolsoMeses'] ?? '';
    desembolsoObservacoesCtrl.text = m['desembolsoObservacoes'] ?? '';

    linksComprovacoesCtrl.text = m['linksComprovacoes'] ?? '';
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      exercicioCtrl, processoSeiCtrl, responsavelOrcCtrl,
      unidadeOrcCtrl, ugCtrl, programaCtrl, acaoCtrl, ptresCtrl, planoOrcCtrl, fonteRecursoCtrl,
      modalidadeAplicacaoCtrl, elementoDespesaCtrl, subelementoCtrl, descricaoNdCtrl,
      reservaNumeroCtrl, reservaDataCtrl, reservaValorCtrl, reservaObservacoesCtrl,
      empenhoModalidadeCtrl, empenhoNumeroCtrl, empenhoDataCtrl, empenhoValorCtrl,
      desembolsoPeriodicidadeCtrl, desembolsoMesesCtrl, desembolsoObservacoesCtrl,
      linksComprovacoesCtrl,
    ]) { ctrl.clear(); }
    responsavelOrcUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      exercicioCtrl, processoSeiCtrl, responsavelOrcCtrl,
      unidadeOrcCtrl, ugCtrl, programaCtrl, acaoCtrl, ptresCtrl, planoOrcCtrl, fonteRecursoCtrl,
      modalidadeAplicacaoCtrl, elementoDespesaCtrl, subelementoCtrl, descricaoNdCtrl,
      reservaNumeroCtrl, reservaDataCtrl, reservaValorCtrl, reservaObservacoesCtrl,
      empenhoModalidadeCtrl, empenhoNumeroCtrl, empenhoDataCtrl, empenhoValorCtrl,
      desembolsoPeriodicidadeCtrl, desembolsoMesesCtrl, desembolsoObservacoesCtrl,
      linksComprovacoesCtrl,
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
