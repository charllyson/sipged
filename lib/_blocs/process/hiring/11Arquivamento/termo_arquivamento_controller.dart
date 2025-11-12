import 'package:flutter/material.dart';
import 'package:siged/_blocs/process/hiring/11Arquivamento/termo_arquivamento_sections.dart';

class TermoArquivamentoController extends ChangeNotifier {
  bool isEditable;
  TermoArquivamentoController({this.isEditable = true});

  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  // 1) Metadados
  final taNumeroCtrl      = TextEditingController();
  final taDataCtrl        = TextEditingController(); // dd/MM/yyyy
  final taProcessoCtrl    = TextEditingController();
  final taResponsavelCtrl = TextEditingController(); // display
  String? taResponsavelUserId;                       // id salvo

  // 2) Motivo e Abrangência
  final taMotivoCtrl               = TextEditingController();
  final taAbrangenciaCtrl          = TextEditingController();
  final taDescricaoAbrangenciaCtrl = TextEditingController();

  // 3) Fundamentação
  final taFundamentosLegaisCtrl = TextEditingController();
  final taJustificativaCtrl     = TextEditingController();

  // 4) Peças Anexas
  final taPecasAnexasCtrl = TextEditingController();
  final taLinksCtrl       = TextEditingController();

  // 5) Decisão da Autoridade
  final taAutoridadeCtrl         = TextEditingController(); // display
  String? taAutoridadeUserId;                               // id salvo
  final taDecisaoCtrl            = TextEditingController();
  final taDataDecisaoCtrl        = TextEditingController(); // dd/MM/yyyy
  final taObservacoesDecisaoCtrl = TextEditingController();

  // 6) Reabertura
  final taReaberturaCondicaoCtrl = TextEditingController();
  final taPrazoReaberturaCtrl    = TextEditingController();

  bool _looksUid(String? v) => v != null && v.trim().length >= 20 && !v.contains(' ');

  Map<String, Map<String, dynamic>> toSectionMaps() => {
    TermoArquivamentoSections.metadados: {
      'taNumero': taNumeroCtrl.text,
      'taData': taDataCtrl.text,
      'taProcesso': taProcessoCtrl.text,
      'taResponsavelUserId': taResponsavelUserId,
    },
    TermoArquivamentoSections.motivo: {
      'taMotivo': taMotivoCtrl.text,
      'taAbrangencia': taAbrangenciaCtrl.text,
      'taDescricaoAbrangencia': taDescricaoAbrangenciaCtrl.text,
    },
    TermoArquivamentoSections.fundamentacao: {
      'taFundamentosLegais': taFundamentosLegaisCtrl.text,
      'taJustificativa': taJustificativaCtrl.text,
    },
    TermoArquivamentoSections.pecas: {
      'taPecasAnexas': taPecasAnexasCtrl.text,
      'taLinks': taLinksCtrl.text,
    },
    TermoArquivamentoSections.decisao: {
      'taAutoridadeUserId': taAutoridadeUserId,
      'taDecisao': taDecisaoCtrl.text,
      'taDataDecisao': taDataDecisaoCtrl.text,
      'taObservacoesDecisao': taObservacoesDecisaoCtrl.text,
    },
    TermoArquivamentoSections.reabertura: {
      'taReaberturaCondicao': taReaberturaCondicaoCtrl.text,
      'taPrazoReabertura': taPrazoReaberturaCtrl.text,
    },
  };

  void fromSectionMaps(Map<String, Map<String, dynamic>> sections) {
    String _s(Map m, String k) => (m[k] ?? '').toString();

    final meta = sections[TermoArquivamentoSections.metadados] ?? const {};
    taNumeroCtrl.text   = _s(meta, 'taNumero');
    taDataCtrl.text     = _s(meta, 'taData');
    taProcessoCtrl.text = _s(meta, 'taProcesso');

    // Normaliza responsável (se 'nome' vier como UID, move para UserId)
    final respId = meta['taResponsavelUserId'];
    final respNome = meta['taResponsavelNome']; // caso você salve o nome em algum lugar
    taResponsavelUserId = respId ?? (_looksUid(respNome) ? respNome : null);
    taResponsavelCtrl.text = _looksUid(respNome) ? '' : (respNome ?? '');

    final mot = sections[TermoArquivamentoSections.motivo] ?? const {};
    taMotivoCtrl.text               = _s(mot, 'taMotivo');
    taAbrangenciaCtrl.text          = _s(mot, 'taAbrangencia');
    taDescricaoAbrangenciaCtrl.text = _s(mot, 'taDescricaoAbrangencia');

    final fund = sections[TermoArquivamentoSections.fundamentacao] ?? const {};
    taFundamentosLegaisCtrl.text = _s(fund, 'taFundamentosLegais');
    taJustificativaCtrl.text     = _s(fund, 'taJustificativa');

    final pec = sections[TermoArquivamentoSections.pecas] ?? const {};
    taPecasAnexasCtrl.text = _s(pec, 'taPecasAnexas');
    taLinksCtrl.text       = _s(pec, 'taLinks');

    final dec = sections[TermoArquivamentoSections.decisao] ?? const {};
    final autId = dec['taAutoridadeUserId'];
    final autNome = dec['taAutoridadeNome'];
    taAutoridadeUserId = autId ?? (_looksUid(autNome) ? autNome : null);
    taAutoridadeCtrl.text = _looksUid(autNome) ? '' : (autNome ?? '');
    taDecisaoCtrl.text            = _s(dec, 'taDecisao');
    taDataDecisaoCtrl.text        = _s(dec, 'taDataDecisao');
    taObservacoesDecisaoCtrl.text = _s(dec, 'taObservacoesDecisao');

    final reab = sections[TermoArquivamentoSections.reabertura] ?? const {};
    taReaberturaCondicaoCtrl.text = _s(reab, 'taReaberturaCondicao');
    taPrazoReaberturaCtrl.text    = _s(reab, 'taPrazoReabertura');

    notifyListeners();
  }

  String? quickValidate() {
    if (taNumeroCtrl.text.trim().isEmpty) return 'Informe o Nº do Termo.';
    if (taDataCtrl.text.trim().isEmpty) return 'Informe a data do Termo.';
    if (taProcessoCtrl.text.trim().isEmpty) return 'Informe o Nº do processo.';
    if (taMotivoCtrl.text.trim().isEmpty) return 'Selecione o motivo do arquivamento.';
    if (taFundamentosLegaisCtrl.text.trim().isEmpty) return 'Informe os fundamentos legais.';
    if (taDecisaoCtrl.text.trim().isEmpty) return 'Selecione a decisão da autoridade.';
    return null;
  }

  @override
  void dispose() {
    for (final c in [
      taNumeroCtrl, taDataCtrl, taProcessoCtrl, taResponsavelCtrl,
      taMotivoCtrl, taAbrangenciaCtrl, taDescricaoAbrangenciaCtrl,
      taFundamentosLegaisCtrl, taJustificativaCtrl,
      taPecasAnexasCtrl, taLinksCtrl,
      taAutoridadeCtrl, taDecisaoCtrl, taDataDecisaoCtrl, taObservacoesDecisaoCtrl,
      taReaberturaCondicaoCtrl, taPrazoReaberturaCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }
}
