import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Controller de TESTE para Documentos do Gestor / Habilitação.
/// - Usa TextEditingController inclusive para dropdowns (compatível com DropDownButtonChange).
class RegularidadeController extends ChangeNotifier {
  bool isEditable = true;

  // 1) Metadados
  final dgNumeroDossieCtrl = TextEditingController();
  final dgDataMontagemCtrl = TextEditingController();
  final dgResponsavelCtrl = TextEditingController(); // Autocomplete fake
  String? dgResponsavelUserId;
  final dgLinksPastaCtrl = TextEditingController();

  // 2) Empresa
  final empRazaoSocialCtrl = TextEditingController();
  final empCnpjCtrl = TextEditingController();
  final empSociosRepresentantesCtrl = TextEditingController();

  // 3) Certidões
  final crfFgtsStatusCtrl = TextEditingController();
  final crfFgtsValidadeCtrl = TextEditingController();
  final crfFgtsLinkCtrl = TextEditingController();

  final cndInssStatusCtrl = TextEditingController();
  final cndInssValidadeCtrl = TextEditingController();
  final cndInssLinkCtrl = TextEditingController();

  final cndFederalStatusCtrl = TextEditingController();
  final cndFederalValidadeCtrl = TextEditingController();
  final cndFederalLinkCtrl = TextEditingController();

  final cndEstadualStatusCtrl = TextEditingController();
  final cndEstadualValidadeCtrl = TextEditingController();
  final cndEstadualLinkCtrl = TextEditingController();

  final cndMunicipalStatusCtrl = TextEditingController();
  final cndMunicipalValidadeCtrl = TextEditingController();
  final cndMunicipalLinkCtrl = TextEditingController();

  final cndtStatusCtrl = TextEditingController();
  final cndtValidadeCtrl = TextEditingController();
  final cndtLinkCtrl = TextEditingController();

  // 4) Habilitação Jurídica / Técnica
  final docContratoSocialCtrl = TextEditingController();
  final docCnpjCartaoCtrl = TextEditingController();
  final docAtestadosStatusCtrl = TextEditingController();
  final docAtestadosLinksCtrl = TextEditingController();

  // 5) Documentos da licitação/adesão
  final procModalidadeCtrl = TextEditingController();
  final procNumeroCtrl = TextEditingController();
  final procAtaSessaoLinkCtrl = TextEditingController();
  final procAtaAdjudicacaoLinkCtrl = TextEditingController();
  final procEditalLinkCtrl = TextEditingController();
  final procOficiosComunicacoesCtrl = TextEditingController();

  // 6) Consolidação
  final dgSituacaoHabilitacaoCtrl = TextEditingController();
  final dgDataConclusaoCtrl = TextEditingController();
  final dgParecerConclusivoCtrl = TextEditingController();

  void initWithMock() {
    dgNumeroDossieCtrl.text = 'SEI 64000.000000/2025-11';
    dgDataMontagemCtrl.text = '07/04/2025';
    dgResponsavelCtrl.text = 'Licitacoes Bom Conselho (uid:l1)';
    dgResponsavelUserId = 'l1';
    dgLinksPastaCtrl.text = 'Drive://Documentos do Gestor; PNCP://link';

    empRazaoSocialCtrl.text = 'FC Empreendimentos Ltda.';
    empCnpjCtrl.text = '12.345.678/0001-90';
    empSociosRepresentantesCtrl.text = 'Fulano (000.000.000-00); Sicrana (111.111.111-11)';

    crfFgtsStatusCtrl.text = 'Válida';
    crfFgtsValidadeCtrl.text = '30/10/2025';
    crfFgtsLinkCtrl.text = 'SEI://crf-fgts.pdf';

    cndInssStatusCtrl.text = 'Válida';
    cndInssValidadeCtrl.text = '30/10/2025';
    cndInssLinkCtrl.text = 'SEI://cnd-inss.pdf';

    cndFederalStatusCtrl.text = 'Válida';
    cndFederalValidadeCtrl.text = '30/10/2025';
    cndFederalLinkCtrl.text = 'SEI://cnd-federal.pdf';

    cndEstadualStatusCtrl.text = 'Válida';
    cndEstadualValidadeCtrl.text = '30/10/2025';
    cndEstadualLinkCtrl.text = 'SEI://cnd-estadual.pdf';

    cndMunicipalStatusCtrl.text = 'Válida';
    cndMunicipalValidadeCtrl.text = '30/10/2025';
    cndMunicipalLinkCtrl.text = 'SEI://cnd-municipal.pdf';

    cndtStatusCtrl.text = 'Válida';
    cndtValidadeCtrl.text = '30/10/2025';
    cndtLinkCtrl.text = 'SEI://cndt.pdf';

    docContratoSocialCtrl.text = 'SEI://contrato-social.pdf';
    docCnpjCartaoCtrl.text = 'SEI://cartao-cnpj.pdf';
    docAtestadosStatusCtrl.text = 'Apresentados';
    docAtestadosLinksCtrl.text = 'SEI://atestados.zip';

    procModalidadeCtrl.text = 'Adesão a ARP';
    procNumeroCtrl.text = 'ARP 19/2024';
    procAtaSessaoLinkCtrl.text = 'SEI://ata-sessao.pdf';
    procAtaAdjudicacaoLinkCtrl.text = 'SEI://ata-adjudicacao.pdf';
    procEditalLinkCtrl.text = 'SEI://edital-arp.pdf';
    procOficiosComunicacoesCtrl.text = 'SEI://oficios.zip';

    dgSituacaoHabilitacaoCtrl.text = 'Habilitada';
    dgDataConclusaoCtrl.text = '26/05/2025';
    dgParecerConclusivoCtrl.text = 'Empresa habilitada: toda regularidade comprovada.';
    notifyListeners();
  }

  String? quickValidate() {
    if (dgNumeroDossieCtrl.text.trim().isEmpty) return 'Informe o Nº do dossiê.';
    if (dgDataMontagemCtrl.text.trim().isEmpty) return 'Informe a data de montagem.';
    if (empRazaoSocialCtrl.text.trim().isEmpty) return 'Informe a razão social.';
    if (empCnpjCtrl.text.trim().isEmpty) return 'Informe o CNPJ.';
    if (dgSituacaoHabilitacaoCtrl.text.trim().isEmpty) return 'Selecione a situação da habilitação.';
    return null;
  }

  Map<String, dynamic> save() {
    final e = quickValidate();
    if (e != null) throw StateError(e);
    return toMap();
  }

  Map<String, dynamic> toMap() => {
    // 1) Metadados
    'numeroDossie': dgNumeroDossieCtrl.text,
    'dataMontagem': dgDataMontagemCtrl.text,
    'responsavelNome': dgResponsavelCtrl.text,
    'responsavelUserId': dgResponsavelUserId,
    'linksPasta': dgLinksPastaCtrl.text,

    // 2) Empresa
    'razaoSocial': empRazaoSocialCtrl.text,
    'cnpj': empCnpjCtrl.text,
    'sociosRepresentantes': empSociosRepresentantesCtrl.text,

    // 3) Certidões
    'crfFgts': {
      'status': crfFgtsStatusCtrl.text,
      'validade': crfFgtsValidadeCtrl.text,
      'link': crfFgtsLinkCtrl.text,
    },
    'cndInss': {
      'status': cndInssStatusCtrl.text,
      'validade': cndInssValidadeCtrl.text,
      'link': cndInssLinkCtrl.text,
    },
    'cndFederal': {
      'status': cndFederalStatusCtrl.text,
      'validade': cndFederalValidadeCtrl.text,
      'link': cndFederalLinkCtrl.text,
    },
    'cndEstadual': {
      'status': cndEstadualStatusCtrl.text,
      'validade': cndEstadualValidadeCtrl.text,
      'link': cndEstadualLinkCtrl.text,
    },
    'cndMunicipal': {
      'status': cndMunicipalStatusCtrl.text,
      'validade': cndMunicipalValidadeCtrl.text,
      'link': cndMunicipalLinkCtrl.text,
    },
    'cndt': {
      'status': cndtStatusCtrl.text,
      'validade': cndtValidadeCtrl.text,
      'link': cndtLinkCtrl.text,
    },

    // 4) Habilitação jurídica/técnica
    'contratoSocial': docContratoSocialCtrl.text,
    'cartaoCnpj': docCnpjCartaoCtrl.text,
    'atestadosStatus': docAtestadosStatusCtrl.text,
    'atestadosLinks': docAtestadosLinksCtrl.text,

    // 5) Licitação/Adesão
    'modalidadeProcesso': procModalidadeCtrl.text,
    'numeroProcesso': procNumeroCtrl.text,
    'ataSessaoLink': procAtaSessaoLinkCtrl.text,
    'ataAdjudicacaoLink': procAtaAdjudicacaoLinkCtrl.text,
    'editalLink': procEditalLinkCtrl.text,
    'oficiosLinks': procOficiosComunicacoesCtrl.text,

    // 6) Consolidação
    'situacaoHabilitacao': dgSituacaoHabilitacaoCtrl.text,
    'dataConclusao': dgDataConclusaoCtrl.text,
    'parecerConclusivo': dgParecerConclusivoCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    dgNumeroDossieCtrl.text = m['numeroDossie'] ?? '';
    dgDataMontagemCtrl.text = m['dataMontagem'] ?? '';
    dgResponsavelCtrl.text = m['responsavelNome'] ?? '';
    dgResponsavelUserId = m['responsavelUserId'];
    dgLinksPastaCtrl.text = m['linksPasta'] ?? '';

    empRazaoSocialCtrl.text = m['razaoSocial'] ?? '';
    empCnpjCtrl.text = m['cnpj'] ?? '';
    empSociosRepresentantesCtrl.text = m['sociosRepresentantes'] ?? '';

    final fgts = (m['crfFgts'] as Map?) ?? {};
    crfFgtsStatusCtrl.text = fgts['status'] ?? '';
    crfFgtsValidadeCtrl.text = fgts['validade'] ?? '';
    crfFgtsLinkCtrl.text = fgts['link'] ?? '';

    final inss = (m['cndInss'] as Map?) ?? {};
    cndInssStatusCtrl.text = inss['status'] ?? '';
    cndInssValidadeCtrl.text = inss['validade'] ?? '';
    cndInssLinkCtrl.text = inss['link'] ?? '';

    final fed = (m['cndFederal'] as Map?) ?? {};
    cndFederalStatusCtrl.text = fed['status'] ?? '';
    cndFederalValidadeCtrl.text = fed['validade'] ?? '';
    cndFederalLinkCtrl.text = fed['link'] ?? '';

    final est = (m['cndEstadual'] as Map?) ?? {};
    cndEstadualStatusCtrl.text = est['status'] ?? '';
    cndEstadualValidadeCtrl.text = est['validade'] ?? '';
    cndEstadualLinkCtrl.text = est['link'] ?? '';

    final mun = (m['cndMunicipal'] as Map?) ?? {};
    cndMunicipalStatusCtrl.text = mun['status'] ?? '';
    cndMunicipalValidadeCtrl.text = mun['validade'] ?? '';
    cndMunicipalLinkCtrl.text = mun['link'] ?? '';

    final t = (m['cndt'] as Map?) ?? {};
    cndtStatusCtrl.text = t['status'] ?? '';
    cndtValidadeCtrl.text = t['validade'] ?? '';
    cndtLinkCtrl.text = t['link'] ?? '';

    docContratoSocialCtrl.text = m['contratoSocial'] ?? '';
    docCnpjCartaoCtrl.text = m['cartaoCnpj'] ?? '';
    docAtestadosStatusCtrl.text = m['atestadosStatus'] ?? '';
    docAtestadosLinksCtrl.text = m['atestadosLinks'] ?? '';

    procModalidadeCtrl.text = m['modalidadeProcesso'] ?? '';
    procNumeroCtrl.text = m['numeroProcesso'] ?? '';
    procAtaSessaoLinkCtrl.text = m['ataSessaoLink'] ?? '';
    procAtaAdjudicacaoLinkCtrl.text = m['ataAdjudicacaoLink'] ?? '';
    procEditalLinkCtrl.text = m['editalLink'] ?? '';
    procOficiosComunicacoesCtrl.text = m['oficiosLinks'] ?? '';

    dgSituacaoHabilitacaoCtrl.text = m['situacaoHabilitacao'] ?? '';
    dgDataConclusaoCtrl.text = m['dataConclusao'] ?? '';
    dgParecerConclusivoCtrl.text = m['parecerConclusivo'] ?? '';
    notifyListeners();
  }

  void clear() {
    for (final ctrl in [
      dgNumeroDossieCtrl, dgDataMontagemCtrl, dgResponsavelCtrl, dgLinksPastaCtrl,
      empRazaoSocialCtrl, empCnpjCtrl, empSociosRepresentantesCtrl,
      crfFgtsStatusCtrl, crfFgtsValidadeCtrl, crfFgtsLinkCtrl,
      cndInssStatusCtrl, cndInssValidadeCtrl, cndInssLinkCtrl,
      cndFederalStatusCtrl, cndFederalValidadeCtrl, cndFederalLinkCtrl,
      cndEstadualStatusCtrl, cndEstadualValidadeCtrl, cndEstadualLinkCtrl,
      cndMunicipalStatusCtrl, cndMunicipalValidadeCtrl, cndMunicipalLinkCtrl,
      cndtStatusCtrl, cndtValidadeCtrl, cndtLinkCtrl,
      docContratoSocialCtrl, docCnpjCartaoCtrl, docAtestadosStatusCtrl, docAtestadosLinksCtrl,
      procModalidadeCtrl, procNumeroCtrl, procAtaSessaoLinkCtrl, procAtaAdjudicacaoLinkCtrl, procEditalLinkCtrl, procOficiosComunicacoesCtrl,
      dgSituacaoHabilitacaoCtrl, dgDataConclusaoCtrl, dgParecerConclusivoCtrl,
    ]) { ctrl.clear(); }
    dgResponsavelUserId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final ctrl in [
      dgNumeroDossieCtrl, dgDataMontagemCtrl, dgResponsavelCtrl, dgLinksPastaCtrl,
      empRazaoSocialCtrl, empCnpjCtrl, empSociosRepresentantesCtrl,
      crfFgtsStatusCtrl, crfFgtsValidadeCtrl, crfFgtsLinkCtrl,
      cndInssStatusCtrl, cndInssValidadeCtrl, cndInssLinkCtrl,
      cndFederalStatusCtrl, cndFederalValidadeCtrl, cndFederalLinkCtrl,
      cndEstadualStatusCtrl, cndEstadualValidadeCtrl, cndEstadualLinkCtrl,
      cndMunicipalStatusCtrl, cndMunicipalValidadeCtrl, cndMunicipalLinkCtrl,
      cndtStatusCtrl, cndtValidadeCtrl, cndtLinkCtrl,
      docContratoSocialCtrl, docCnpjCartaoCtrl, docAtestadosStatusCtrl, docAtestadosLinksCtrl,
      procModalidadeCtrl, procNumeroCtrl, procAtaSessaoLinkCtrl, procAtaAdjudicacaoLinkCtrl, procEditalLinkCtrl, procOficiosComunicacoesCtrl,
      dgSituacaoHabilitacaoCtrl, dgDataConclusaoCtrl, dgParecerConclusivoCtrl,
    ]) { ctrl.dispose(); }
    super.dispose();
  }
}
