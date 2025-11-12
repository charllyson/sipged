// lib/_blocs/process/hiring/7Dotacao/dotacao_controller.dart
import 'package:flutter/material.dart';

class DotacaoController extends ChangeNotifier {
  bool isEditable;
  DotacaoController({this.isEditable = true});

  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  // ==== 1) Identificação / Exercício ====
  final exercicioCtrl = TextEditingController();          // ano
  final processoSeiCtrl = TextEditingController();        // SEI/Interno
  final responsavelOrcCtrl = TextEditingController();     // nome p/ UI
  String? responsavelOrcUserId;

  // ==== 2) Vinculação Programática ====
  final unidadeOrcCtrl = TextEditingController();         // UO
  final ugCtrl = TextEditingController();                 // UG
  final programaCtrl = TextEditingController();
  final acaoCtrl = TextEditingController();
  final ptresCtrl = TextEditingController();              // PTRES/PI/OB
  final planoOrcCtrl = TextEditingController();
  final fonteRecursoCtrl = TextEditingController();       // dropdown label

  // ==== 3) Natureza da Despesa ====
  final modalidadeAplicacaoCtrl = TextEditingController();// ex. 90
  final elementoDespesaCtrl = TextEditingController();    // ex. 39/44
  final subelementoCtrl = TextEditingController();        // opcional
  final descricaoNdCtrl = TextEditingController();        // texto

  // ==== 4) Reserva Orçamentária ====
  final reservaNumeroCtrl = TextEditingController();
  final reservaDataCtrl = TextEditingController();        // dd/mm/aaaa
  final reservaValorCtrl = TextEditingController();
  final reservaObservacoesCtrl = TextEditingController();

  // ==== 5) Empenho ====
  final empenhoModalidadeCtrl = TextEditingController();  // (Ordinário/Estimativo/Global)
  final empenhoNumeroCtrl = TextEditingController();      // NE
  final empenhoDataCtrl = TextEditingController();        // dd/mm/aaaa
  final empenhoValorCtrl = TextEditingController();

  // ==== 6) Cronograma ====
  final desembolsoPeriodicidadeCtrl = TextEditingController(); // Mensal/...
  final desembolsoMesesCtrl = TextEditingController();         // Jan–Jun
  final desembolsoObservacoesCtrl = TextEditingController();

  // ==== 7) Documentos / Links ====
  final linksComprovacoesCtrl = TextEditingController(); // links (NE, Reserva...)

  // ───────── (de)serialização ─────────
  Map<String, Map<String, dynamic>> toSectionMaps() => {
    'identificacao': {
      'exercicio': exercicioCtrl.text,
      'processoSei': processoSeiCtrl.text,
      'responsavelNome': responsavelOrcCtrl.text,
      'responsavelUserId': responsavelOrcUserId,
    },
    'vinculacao': {
      'uo': unidadeOrcCtrl.text,
      'ug': ugCtrl.text,
      'programa': programaCtrl.text,
      'acao': acaoCtrl.text,
      'ptres': ptresCtrl.text,
      'planoOrc': planoOrcCtrl.text,
      'fonteRecurso': fonteRecursoCtrl.text,
    },
    'natureza': {
      'modalidadeAplicacao': modalidadeAplicacaoCtrl.text,
      'elementoDespesa': elementoDespesaCtrl.text,
      'subelemento': subelementoCtrl.text,
      'descricaoNd': descricaoNdCtrl.text,
    },
    'reserva': {
      'numero': reservaNumeroCtrl.text,
      'data': reservaDataCtrl.text,
      'valor': reservaValorCtrl.text,
      'observacoes': reservaObservacoesCtrl.text,
    },
    'empenho': {
      'modalidade': empenhoModalidadeCtrl.text,
      'numero': empenhoNumeroCtrl.text,
      'data': empenhoDataCtrl.text,
      'valor': empenhoValorCtrl.text,
    },
    'cronograma': {
      'periodicidade': desembolsoPeriodicidadeCtrl.text,
      'meses': desembolsoMesesCtrl.text,
      'observacoes': desembolsoObservacoesCtrl.text,
    },
    'documentos': {
      'links': linksComprovacoesCtrl.text,
    },
  };

  bool _looksUid(String? v) => v != null && v.trim().length >= 20 && !v.contains(' ');

  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    final id = sections['identificacao'] ?? const {};
    exercicioCtrl.text = id['exercicio'] ?? '';
    processoSeiCtrl.text = id['processoSei'] ?? '';
    responsavelOrcUserId = id['responsavelUserId'] ?? (_looksUid(id['responsavelNome']) ? id['responsavelNome'] : null);
    responsavelOrcCtrl.text = _looksUid(id['responsavelNome']) ? '' : (id['responsavelNome'] ?? '');

    final v = sections['vinculacao'] ?? const {};
    unidadeOrcCtrl.text = v['uo'] ?? '';
    ugCtrl.text = v['ug'] ?? '';
    programaCtrl.text = v['programa'] ?? '';
    acaoCtrl.text = v['acao'] ?? '';
    ptresCtrl.text = v['ptres'] ?? '';
    planoOrcCtrl.text = v['planoOrc'] ?? '';
    fonteRecursoCtrl.text = v['fonteRecurso'] ?? '';

    final n = sections['natureza'] ?? const {};
    modalidadeAplicacaoCtrl.text = n['modalidadeAplicacao'] ?? '';
    elementoDespesaCtrl.text = n['elementoDespesa'] ?? '';
    subelementoCtrl.text = n['subelemento'] ?? '';
    descricaoNdCtrl.text = n['descricaoNd'] ?? '';

    final r = sections['reserva'] ?? const {};
    reservaNumeroCtrl.text = r['numero'] ?? '';
    reservaDataCtrl.text = r['data'] ?? '';
    reservaValorCtrl.text = r['valor'] ?? '';
    reservaObservacoesCtrl.text = r['observacoes'] ?? '';

    final e = sections['empenho'] ?? const {};
    empenhoModalidadeCtrl.text = e['modalidade'] ?? '';
    empenhoNumeroCtrl.text = e['numero'] ?? '';
    empenhoDataCtrl.text = e['data'] ?? '';
    empenhoValorCtrl.text = e['valor'] ?? '';

    final c = sections['cronograma'] ?? const {};
    desembolsoPeriodicidadeCtrl.text = c['periodicidade'] ?? '';
    desembolsoMesesCtrl.text = c['meses'] ?? '';
    desembolsoObservacoesCtrl.text = c['observacoes'] ?? '';

    final d = sections['documentos'] ?? const {};
    linksComprovacoesCtrl.text = d['links'] ?? '';

    notifyListeners();
  }

  String? quickValidate() {
    if (exercicioCtrl.text.trim().isEmpty)   return 'Informe o Exercício (ano).';
    if (processoSeiCtrl.text.trim().isEmpty) return 'Informe o Nº do processo (SEI/Interno).';
    if ((responsavelOrcUserId == null || responsavelOrcUserId!.isEmpty) &&
        responsavelOrcCtrl.text.trim().isEmpty) {
      return 'Selecione o responsável orçamentário.';
    }
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      exercicioCtrl, processoSeiCtrl, responsavelOrcCtrl,
      unidadeOrcCtrl, ugCtrl, programaCtrl, acaoCtrl, ptresCtrl, planoOrcCtrl, fonteRecursoCtrl,
      modalidadeAplicacaoCtrl, elementoDespesaCtrl, subelementoCtrl, descricaoNdCtrl,
      reservaNumeroCtrl, reservaDataCtrl, reservaValorCtrl, reservaObservacoesCtrl,
      empenhoModalidadeCtrl, empenhoNumeroCtrl, empenhoDataCtrl, empenhoValorCtrl,
      desembolsoPeriodicidadeCtrl, desembolsoMesesCtrl, desembolsoObservacoesCtrl,
      linksComprovacoesCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }
}
