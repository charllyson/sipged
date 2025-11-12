import 'package:flutter/material.dart';

class HabilitacaoController extends ChangeNotifier {
  bool isEditable;
  HabilitacaoController({this.isEditable = true});

  // ───── 1) Metadados ─────
  final dgNumeroDossieCtrl      = TextEditingController();
  final dgDataMontagemCtrl      = TextEditingController(); // dd/mm/aaaa
  final dgResponsavelCtrl       = TextEditingController(); // nome p/ UI
  String? dgResponsavelUserId;                              // id p/ Autocomplete
  final dgLinksPastaCtrl        = TextEditingController();

  // ───── 2) Empresa ─────
  final empRazaoSocialCtrl      = TextEditingController();
  final empCnpjCtrl             = TextEditingController();
  final empSociosRepresentantesCtrl = TextEditingController(); // multi-linha

  // ───── 3) Certidões ─────
  final crfFgtsStatusCtrl       = TextEditingController();
  final crfFgtsValidadeCtrl     = TextEditingController();
  final crfFgtsLinkCtrl         = TextEditingController();

  final cndInssStatusCtrl       = TextEditingController();
  final cndInssValidadeCtrl     = TextEditingController();
  final cndInssLinkCtrl         = TextEditingController();

  final cndFederalStatusCtrl    = TextEditingController();
  final cndFederalValidadeCtrl  = TextEditingController();
  final cndFederalLinkCtrl      = TextEditingController();

  final cndEstadualStatusCtrl   = TextEditingController();
  final cndEstadualValidadeCtrl = TextEditingController();
  final cndEstadualLinkCtrl     = TextEditingController();

  final cndMunicipalStatusCtrl  = TextEditingController();
  final cndMunicipalValidadeCtrl= TextEditingController();
  final cndMunicipalLinkCtrl    = TextEditingController();

  final cndtStatusCtrl          = TextEditingController();
  final cndtValidadeCtrl        = TextEditingController();
  final cndtLinkCtrl            = TextEditingController();

  // ───── 4) Jurídica/Técnica ─────
  final docContratoSocialCtrl   = TextEditingController();
  final docCnpjCartaoCtrl       = TextEditingController();
  final docAtestadosStatusCtrl  = TextEditingController();
  final docAtestadosLinksCtrl   = TextEditingController();

  // ───── 5) Licitação/Adesão ─────
  final procModalidadeCtrl          = TextEditingController();
  final procNumeroCtrl              = TextEditingController();
  final procAtaSessaoLinkCtrl       = TextEditingController();
  final procAtaAdjudicacaoLinkCtrl  = TextEditingController();
  final procEditalLinkCtrl          = TextEditingController();
  final procOficiosComunicacoesCtrl = TextEditingController();

  // ───── 6) Consolidação/Parecer ─────
  final dgSituacaoHabilitacaoCtrl = TextEditingController();
  final dgDataConclusaoCtrl       = TextEditingController(); // dd/mm/aaaa
  final dgParecerConclusivoCtrl   = TextEditingController();

  // helpers
  void setEditable(bool v) {
    isEditable = v;
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> toSectionMaps() => {
    'metadados': {
      'numeroDossie': dgNumeroDossieCtrl.text,
      'dataMontagem': dgDataMontagemCtrl.text,
      'responsavelNome': dgResponsavelCtrl.text,
      'responsavelUserId': dgResponsavelUserId,
      'linksPasta': dgLinksPastaCtrl.text,
    },
    'empresa': {
      'razaoSocial': empRazaoSocialCtrl.text,
      'cnpj': empCnpjCtrl.text,
      'sociosRepresentantes': empSociosRepresentantesCtrl.text,
    },
    'certidoes': {
      'fgtsStatus': crfFgtsStatusCtrl.text,
      'fgtsValidade': crfFgtsValidadeCtrl.text,
      'fgtsLink': crfFgtsLinkCtrl.text,
      'inssStatus': cndInssStatusCtrl.text,
      'inssValidade': cndInssValidadeCtrl.text,
      'inssLink': cndInssLinkCtrl.text,
      'federalStatus': cndFederalStatusCtrl.text,
      'federalValidade': cndFederalValidadeCtrl.text,
      'federalLink': cndFederalLinkCtrl.text,
      'estadualStatus': cndEstadualStatusCtrl.text,
      'estadualValidade': cndEstadualValidadeCtrl.text,
      'estadualLink': cndEstadualLinkCtrl.text,
      'municipalStatus': cndMunicipalStatusCtrl.text,
      'municipalValidade': cndMunicipalValidadeCtrl.text,
      'municipalLink': cndMunicipalLinkCtrl.text,
      'cndtStatus': cndtStatusCtrl.text,
      'cndtValidade': cndtValidadeCtrl.text,
      'cndtLink': cndtLinkCtrl.text,
    },
    'juridicaTecnica': {
      'contratoSocialLink': docContratoSocialCtrl.text,
      'cartaoCnpjLink': docCnpjCartaoCtrl.text,
      'atestadosStatus': docAtestadosStatusCtrl.text,
      'atestadosLinks': docAtestadosLinksCtrl.text,
    },
    'licitacaoAdesao': {
      'modalidade': procModalidadeCtrl.text,
      'numeroProcesso': procNumeroCtrl.text,
      'ataSessaoLink': procAtaSessaoLinkCtrl.text,
      'ataAdjudicacaoLink': procAtaAdjudicacaoLinkCtrl.text,
      'editalLink': procEditalLinkCtrl.text,
      'oficiosLinks': procOficiosComunicacoesCtrl.text,
    },
    'consolidacao': {
      'situacaoHabilitacao': dgSituacaoHabilitacaoCtrl.text,
      'dataConclusao': dgDataConclusaoCtrl.text,
      'parecerConclusivo': dgParecerConclusivoCtrl.text,
    },
  };

  void fromSectionMaps(Map<String, Map<String, dynamic>> s) {
    final m  = s['metadados'] ?? const {};
    dgNumeroDossieCtrl.text = m['numeroDossie'] ?? '';
    dgDataMontagemCtrl.text = m['dataMontagem'] ?? '';
    dgResponsavelUserId     = m['responsavelUserId'];
    dgResponsavelCtrl.text  = m['responsavelNome'] ?? '';
    dgLinksPastaCtrl.text   = m['linksPasta'] ?? '';

    final e  = s['empresa'] ?? const {};
    empRazaoSocialCtrl.text = e['razaoSocial'] ?? '';
    empCnpjCtrl.text        = e['cnpj'] ?? '';
    empSociosRepresentantesCtrl.text = e['sociosRepresentantes'] ?? '';

    final c  = s['certidoes'] ?? const {};
    crfFgtsStatusCtrl.text       = c['fgtsStatus'] ?? '';
    crfFgtsValidadeCtrl.text     = c['fgtsValidade'] ?? '';
    crfFgtsLinkCtrl.text         = c['fgtsLink'] ?? '';
    cndInssStatusCtrl.text       = c['inssStatus'] ?? '';
    cndInssValidadeCtrl.text     = c['inssValidade'] ?? '';
    cndInssLinkCtrl.text         = c['inssLink'] ?? '';
    cndFederalStatusCtrl.text    = c['federalStatus'] ?? '';
    cndFederalValidadeCtrl.text  = c['federalValidade'] ?? '';
    cndFederalLinkCtrl.text      = c['federalLink'] ?? '';
    cndEstadualStatusCtrl.text   = c['estadualStatus'] ?? '';
    cndEstadualValidadeCtrl.text = c['estadualValidade'] ?? '';
    cndEstadualLinkCtrl.text     = c['estadualLink'] ?? '';
    cndMunicipalStatusCtrl.text  = c['municipalStatus'] ?? '';
    cndMunicipalValidadeCtrl.text= c['municipalValidade'] ?? '';
    cndMunicipalLinkCtrl.text    = c['municipalLink'] ?? '';
    cndtStatusCtrl.text          = c['cndtStatus'] ?? '';
    cndtValidadeCtrl.text        = c['cndtValidade'] ?? '';
    cndtLinkCtrl.text            = c['cndtLink'] ?? '';

    final jt = s['juridicaTecnica'] ?? const {};
    docContratoSocialCtrl.text  = jt['contratoSocialLink'] ?? '';
    docCnpjCartaoCtrl.text      = jt['cartaoCnpjLink'] ?? '';
    docAtestadosStatusCtrl.text = jt['atestadosStatus'] ?? '';
    docAtestadosLinksCtrl.text  = jt['atestadosLinks'] ?? '';

    final l  = s['licitacaoAdesao'] ?? const {};
    procModalidadeCtrl.text          = l['modalidade'] ?? '';
    procNumeroCtrl.text              = l['numeroProcesso'] ?? '';
    procAtaSessaoLinkCtrl.text       = l['ataSessaoLink'] ?? '';
    procAtaAdjudicacaoLinkCtrl.text  = l['ataAdjudicacaoLink'] ?? '';
    procEditalLinkCtrl.text          = l['editalLink'] ?? '';
    procOficiosComunicacoesCtrl.text = l['oficiosLinks'] ?? '';

    final co = s['consolidacao'] ?? const {};
    dgSituacaoHabilitacaoCtrl.text = co['situacaoHabilitacao'] ?? '';
    dgDataConclusaoCtrl.text       = co['dataConclusao'] ?? '';
    dgParecerConclusivoCtrl.text   = co['parecerConclusivo'] ?? '';

    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [
      dgNumeroDossieCtrl, dgDataMontagemCtrl, dgResponsavelCtrl, dgLinksPastaCtrl,
      empRazaoSocialCtrl, empCnpjCtrl, empSociosRepresentantesCtrl,
      crfFgtsStatusCtrl, crfFgtsValidadeCtrl, crfFgtsLinkCtrl,
      cndInssStatusCtrl, cndInssValidadeCtrl, cndInssLinkCtrl,
      cndFederalStatusCtrl, cndFederalValidadeCtrl, cndFederalLinkCtrl,
      cndEstadualStatusCtrl, cndEstadualValidadeCtrl, cndEstadualLinkCtrl,
      cndMunicipalStatusCtrl, cndMunicipalValidadeCtrl, cndMunicipalLinkCtrl,
      cndtStatusCtrl, cndtValidadeCtrl, cndtLinkCtrl,
      docContratoSocialCtrl, docCnpjCartaoCtrl, docAtestadosStatusCtrl, docAtestadosLinksCtrl,
      procModalidadeCtrl, procNumeroCtrl, procAtaSessaoLinkCtrl, procAtaAdjudicacaoLinkCtrl,
      procEditalLinkCtrl, procOficiosComunicacoesCtrl,
      dgSituacaoHabilitacaoCtrl, dgDataConclusaoCtrl, dgParecerConclusivoCtrl,
    ]) { c.dispose(); }
    super.dispose();
  }
}
