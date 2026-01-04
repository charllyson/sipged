import 'package:equatable/equatable.dart';

import 'habilitacao_sections.dart';

class HabilitacaoData extends Equatable {
  // ───── 1) Metadados ─────
  final String? numeroDossie;
  final String? dataMontagem;       // dd/mm/aaaa
  final String? responsavelNome;    // nome p/ UI
  final String? responsavelUserId;  // id p/ Autocomplete
  final String? linksPasta;

  // ───── 2) Empresa ─────
  final String? razaoSocial;
  final String? cnpj;
  final String? sociosRepresentantes; // multi-linha

  // ───── 3) Certidões ─────
  final String? fgtsStatus;
  final String? fgtsValidade;
  final String? fgtsLink;

  final String? inssStatus;
  final String? inssValidade;
  final String? inssLink;

  final String? federalStatus;
  final String? federalValidade;
  final String? federalLink;

  final String? estadualStatus;
  final String? estadualValidade;
  final String? estadualLink;

  final String? municipalStatus;
  final String? municipalValidade;
  final String? municipalLink;

  final String? cndtStatus;
  final String? cndtValidade;
  final String? cndtLink;

  // ───── 4) Jurídica/Técnica ─────
  final String? contratoSocialLink;
  final String? cartaoCnpjLink;
  final String? atestadosStatus;
  final String? atestadosLinks;

  // ───── 5) Licitação/Adesão ─────
  final String? modalidade;
  final String? numeroProcesso;
  final String? ataSessaoLink;
  final String? ataAdjudicacaoLink;
  final String? editalLink;
  final String? oficiosLinks;

  // ───── 6) Consolidação/Parecer ─────
  final String? situacaoHabilitacao;
  final String? dataConclusao;      // dd/mm/aaaa
  final String? parecerConclusivo;

  const HabilitacaoData({
    // 1) Metadados
    this.numeroDossie,
    this.dataMontagem,
    this.responsavelNome,
    this.responsavelUserId,
    this.linksPasta,

    // 2) Empresa
    this.razaoSocial,
    this.cnpj,
    this.sociosRepresentantes,

    // 3) Certidões
    this.fgtsStatus,
    this.fgtsValidade,
    this.fgtsLink,
    this.inssStatus,
    this.inssValidade,
    this.inssLink,
    this.federalStatus,
    this.federalValidade,
    this.federalLink,
    this.estadualStatus,
    this.estadualValidade,
    this.estadualLink,
    this.municipalStatus,
    this.municipalValidade,
    this.municipalLink,
    this.cndtStatus,
    this.cndtValidade,
    this.cndtLink,

    // 4) Jurídica/Técnica
    this.contratoSocialLink,
    this.cartaoCnpjLink,
    this.atestadosStatus,
    this.atestadosLinks,

    // 5) Licitação/Adesão
    this.modalidade,
    this.numeroProcesso,
    this.ataSessaoLink,
    this.ataAdjudicacaoLink,
    this.editalLink,
    this.oficiosLinks,

    // 6) Consolidação/Parecer
    this.situacaoHabilitacao,
    this.dataConclusao,
    this.parecerConclusivo,
  });

  /// Construtor "vazio" no mesmo padrão dos outros Data
  const HabilitacaoData.empty()
      : numeroDossie = '',
        dataMontagem = '',
        responsavelNome = '',
        responsavelUserId = null,
        linksPasta = '',
        razaoSocial = '',
        cnpj = '',
        sociosRepresentantes = '',
        fgtsStatus = '',
        fgtsValidade = '',
        fgtsLink = '',
        inssStatus = '',
        inssValidade = '',
        inssLink = '',
        federalStatus = '',
        federalValidade = '',
        federalLink = '',
        estadualStatus = '',
        estadualValidade = '',
        estadualLink = '',
        municipalStatus = '',
        municipalValidade = '',
        municipalLink = '',
        cndtStatus = '',
        cndtValidade = '',
        cndtLink = '',
        contratoSocialLink = '',
        cartaoCnpjLink = '',
        atestadosStatus = '',
        atestadosLinks = '',
        modalidade = '',
        numeroProcesso = '',
        ataSessaoLink = '',
        ataAdjudicacaoLink = '',
        editalLink = '',
        oficiosLinks = '',
        situacaoHabilitacao = '',
        dataConclusao = '',
        parecerConclusivo = '';

  // ---------------------------------------------------------------------------
  // Map "flat" — compatível com um doc único no Firestore, se quiser
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    // Metadados
    'numeroDossie': numeroDossie,
    'dataMontagem': dataMontagem,
    'responsavelNome': responsavelNome,
    'responsavelUserId': responsavelUserId,
    'linksPasta': linksPasta,

    // Empresa
    'razaoSocial': razaoSocial,
    'cnpj': cnpj,
    'sociosRepresentantes': sociosRepresentantes,

    // Certidões
    'fgtsStatus': fgtsStatus,
    'fgtsValidade': fgtsValidade,
    'fgtsLink': fgtsLink,
    'inssStatus': inssStatus,
    'inssValidade': inssValidade,
    'inssLink': inssLink,
    'federalStatus': federalStatus,
    'federalValidade': federalValidade,
    'federalLink': federalLink,
    'estadualStatus': estadualStatus,
    'estadualValidade': estadualValidade,
    'estadualLink': estadualLink,
    'municipalStatus': municipalStatus,
    'municipalValidade': municipalValidade,
    'municipalLink': municipalLink,
    'cndtStatus': cndtStatus,
    'cndtValidade': cndtValidade,
    'cndtLink': cndtLink,

    // Jurídica/Técnica
    'contratoSocialLink': contratoSocialLink,
    'cartaoCnpjLink': cartaoCnpjLink,
    'atestadosStatus': atestadosStatus,
    'atestadosLinks': atestadosLinks,

    // Licitação/Adesão
    'modalidade': modalidade,
    'numeroProcesso': numeroProcesso,
    'ataSessaoLink': ataSessaoLink,
    'ataAdjudicacaoLink': ataAdjudicacaoLink,
    'editalLink': editalLink,
    'oficiosLinks': oficiosLinks,

    // Consolidação
    'situacaoHabilitacao': situacaoHabilitacao,
    'dataConclusao': dataConclusao,
    'parecerConclusivo': parecerConclusivo,
  };

  factory HabilitacaoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HabilitacaoData.empty();

    return HabilitacaoData(
      // Metadados
      numeroDossie: (map['numeroDossie'] ?? '').toString(),
      dataMontagem: (map['dataMontagem'] ?? '').toString(),
      responsavelNome:
      (map['responsavelNome'] ?? '').toString(),
      responsavelUserId:
      map['responsavelUserId']?.toString(),
      linksPasta: (map['linksPasta'] ?? '').toString(),

      // Empresa
      razaoSocial: (map['razaoSocial'] ?? '').toString(),
      cnpj: (map['cnpj'] ?? '').toString(),
      sociosRepresentantes:
      (map['sociosRepresentantes'] ?? '').toString(),

      // Certidões
      fgtsStatus: (map['fgtsStatus'] ?? '').toString(),
      fgtsValidade: (map['fgtsValidade'] ?? '').toString(),
      fgtsLink: (map['fgtsLink'] ?? '').toString(),
      inssStatus: (map['inssStatus'] ?? '').toString(),
      inssValidade: (map['inssValidade'] ?? '').toString(),
      inssLink: (map['inssLink'] ?? '').toString(),
      federalStatus:
      (map['federalStatus'] ?? '').toString(),
      federalValidade:
      (map['federalValidade'] ?? '').toString(),
      federalLink: (map['federalLink'] ?? '').toString(),
      estadualStatus:
      (map['estadualStatus'] ?? '').toString(),
      estadualValidade:
      (map['estadualValidade'] ?? '').toString(),
      estadualLink:
      (map['estadualLink'] ?? '').toString(),
      municipalStatus:
      (map['municipalStatus'] ?? '').toString(),
      municipalValidade:
      (map['municipalValidade'] ?? '').toString(),
      municipalLink:
      (map['municipalLink'] ?? '').toString(),
      cndtStatus: (map['cndtStatus'] ?? '').toString(),
      cndtValidade:
      (map['cndtValidade'] ?? '').toString(),
      cndtLink: (map['cndtLink'] ?? '').toString(),

      // Jurídica/Técnica
      contratoSocialLink:
      (map['contratoSocialLink'] ?? '').toString(),
      cartaoCnpjLink:
      (map['cartaoCnpjLink'] ?? '').toString(),
      atestadosStatus:
      (map['atestadosStatus'] ?? '').toString(),
      atestadosLinks:
      (map['atestadosLinks'] ?? '').toString(),

      // Licitação/Adesão
      modalidade: (map['modalidade'] ?? '').toString(),
      numeroProcesso:
      (map['numeroProcesso'] ?? '').toString(),
      ataSessaoLink:
      (map['ataSessaoLink'] ?? '').toString(),
      ataAdjudicacaoLink:
      (map['ataAdjudicacaoLink'] ?? '').toString(),
      editalLink: (map['editalLink'] ?? '').toString(),
      oficiosLinks:
      (map['oficiosLinks'] ?? '').toString(),

      // Consolidação
      situacaoHabilitacao:
      (map['situacaoHabilitacao'] ?? '').toString(),
      dataConclusao:
      (map['dataConclusao'] ?? '').toString(),
      parecerConclusivo:
      (map['parecerConclusivo'] ?? '').toString(),
    );
  }

  /// A partir da estrutura de seções usada no Firestore
  factory HabilitacaoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final m =
        sections[HabilitacaoSections.metadados] ??
            const <String, dynamic>{};
    final e =
        sections[HabilitacaoSections.empresa] ??
            const <String, dynamic>{};
    final c =
        sections[HabilitacaoSections.certidoes] ??
            const <String, dynamic>{};
    final jt =
        sections[HabilitacaoSections.juridicaTecnica] ??
            const <String, dynamic>{};
    final l =
        sections[HabilitacaoSections.licitacaoAdesao] ??
            const <String, dynamic>{};
    final co =
        sections[HabilitacaoSections.consolidacao] ??
            const <String, dynamic>{};

    return HabilitacaoData(
      // Metadados
      numeroDossie: (m['numeroDossie'] ?? '').toString(),
      dataMontagem: (m['dataMontagem'] ?? '').toString(),
      responsavelNome:
      (m['responsavelNome'] ?? '').toString(),
      responsavelUserId:
      m['responsavelUserId']?.toString(),
      linksPasta: (m['linksPasta'] ?? '').toString(),

      // Empresa
      razaoSocial:
      (e['razaoSocial'] ?? '').toString(),
      cnpj: (e['cnpj'] ?? '').toString(),
      sociosRepresentantes:
      (e['sociosRepresentantes'] ?? '').toString(),

      // Certidões
      fgtsStatus: (c['fgtsStatus'] ?? '').toString(),
      fgtsValidade:
      (c['fgtsValidade'] ?? '').toString(),
      fgtsLink: (c['fgtsLink'] ?? '').toString(),
      inssStatus: (c['inssStatus'] ?? '').toString(),
      inssValidade:
      (c['inssValidade'] ?? '').toString(),
      inssLink: (c['inssLink'] ?? '').toString(),
      federalStatus:
      (c['federalStatus'] ?? '').toString(),
      federalValidade:
      (c['federalValidade'] ?? '').toString(),
      federalLink: (c['federalLink'] ?? '').toString(),
      estadualStatus:
      (c['estadualStatus'] ?? '').toString(),
      estadualValidade:
      (c['estadualValidade'] ?? '').toString(),
      estadualLink:
      (c['estadualLink'] ?? '').toString(),
      municipalStatus:
      (c['municipalStatus'] ?? '').toString(),
      municipalValidade:
      (c['municipalValidade'] ?? '').toString(),
      municipalLink:
      (c['municipalLink'] ?? '').toString(),
      cndtStatus: (c['cndtStatus'] ?? '').toString(),
      cndtValidade:
      (c['cndtValidade'] ?? '').toString(),
      cndtLink: (c['cndtLink'] ?? '').toString(),

      // Jurídica/Técnica
      contratoSocialLink:
      (jt['contratoSocialLink'] ?? '').toString(),
      cartaoCnpjLink:
      (jt['cartaoCnpjLink'] ?? '').toString(),
      atestadosStatus:
      (jt['atestadosStatus'] ?? '').toString(),
      atestadosLinks:
      (jt['atestadosLinks'] ?? '').toString(),

      // Licitação/Adesão
      modalidade: (l['modalidade'] ?? '').toString(),
      numeroProcesso:
      (l['numeroProcesso'] ?? '').toString(),
      ataSessaoLink:
      (l['ataSessaoLink'] ?? '').toString(),
      ataAdjudicacaoLink:
      (l['ataAdjudicacaoLink'] ?? '').toString(),
      editalLink: (l['editalLink'] ?? '').toString(),
      oficiosLinks:
      (l['oficiosLinks'] ?? '').toString(),

      // Consolidação
      situacaoHabilitacao:
      (co['situacaoHabilitacao'] ?? '').toString(),
      dataConclusao:
      (co['dataConclusao'] ?? '').toString(),
      parecerConclusivo:
      (co['parecerConclusivo'] ?? '').toString(),
    );
  }

  HabilitacaoData copyWith({
    String? numeroDossie,
    String? dataMontagem,
    String? responsavelNome,
    String? responsavelUserId,
    String? linksPasta,
    String? razaoSocial,
    String? cnpj,
    String? sociosRepresentantes,
    String? fgtsStatus,
    String? fgtsValidade,
    String? fgtsLink,
    String? inssStatus,
    String? inssValidade,
    String? inssLink,
    String? federalStatus,
    String? federalValidade,
    String? federalLink,
    String? estadualStatus,
    String? estadualValidade,
    String? estadualLink,
    String? municipalStatus,
    String? municipalValidade,
    String? municipalLink,
    String? cndtStatus,
    String? cndtValidade,
    String? cndtLink,
    String? contratoSocialLink,
    String? cartaoCnpjLink,
    String? atestadosStatus,
    String? atestadosLinks,
    String? modalidade,
    String? numeroProcesso,
    String? ataSessaoLink,
    String? ataAdjudicacaoLink,
    String? editalLink,
    String? oficiosLinks,
    String? situacaoHabilitacao,
    String? dataConclusao,
    String? parecerConclusivo,
  }) {
    return HabilitacaoData(
      numeroDossie: numeroDossie ?? this.numeroDossie,
      dataMontagem: dataMontagem ?? this.dataMontagem,
      responsavelNome:
      responsavelNome ?? this.responsavelNome,
      responsavelUserId:
      responsavelUserId ?? this.responsavelUserId,
      linksPasta: linksPasta ?? this.linksPasta,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      cnpj: cnpj ?? this.cnpj,
      sociosRepresentantes:
      sociosRepresentantes ?? this.sociosRepresentantes,
      fgtsStatus: fgtsStatus ?? this.fgtsStatus,
      fgtsValidade: fgtsValidade ?? this.fgtsValidade,
      fgtsLink: fgtsLink ?? this.fgtsLink,
      inssStatus: inssStatus ?? this.inssStatus,
      inssValidade: inssValidade ?? this.inssValidade,
      inssLink: inssLink ?? this.inssLink,
      federalStatus:
      federalStatus ?? this.federalStatus,
      federalValidade:
      federalValidade ?? this.federalValidade,
      federalLink: federalLink ?? this.federalLink,
      estadualStatus:
      estadualStatus ?? this.estadualStatus,
      estadualValidade:
      estadualValidade ?? this.estadualValidade,
      estadualLink: estadualLink ?? this.estadualLink,
      municipalStatus:
      municipalStatus ?? this.municipalStatus,
      municipalValidade:
      municipalValidade ?? this.municipalValidade,
      municipalLink:
      municipalLink ?? this.municipalLink,
      cndtStatus: cndtStatus ?? this.cndtStatus,
      cndtValidade: cndtValidade ?? this.cndtValidade,
      cndtLink: cndtLink ?? this.cndtLink,
      contratoSocialLink:
      contratoSocialLink ?? this.contratoSocialLink,
      cartaoCnpjLink:
      cartaoCnpjLink ?? this.cartaoCnpjLink,
      atestadosStatus:
      atestadosStatus ?? this.atestadosStatus,
      atestadosLinks:
      atestadosLinks ?? this.atestadosLinks,
      modalidade: modalidade ?? this.modalidade,
      numeroProcesso:
      numeroProcesso ?? this.numeroProcesso,
      ataSessaoLink:
      ataSessaoLink ?? this.ataSessaoLink,
      ataAdjudicacaoLink:
      ataAdjudicacaoLink ?? this.ataAdjudicacaoLink,
      editalLink: editalLink ?? this.editalLink,
      oficiosLinks:
      oficiosLinks ?? this.oficiosLinks,
      situacaoHabilitacao:
      situacaoHabilitacao ?? this.situacaoHabilitacao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      parecerConclusivo:
      parecerConclusivo ?? this.parecerConclusivo,
    );
  }

  @override
  List<Object?> get props => [
    numeroDossie,
    dataMontagem,
    responsavelNome,
    responsavelUserId,
    linksPasta,
    razaoSocial,
    cnpj,
    sociosRepresentantes,
    fgtsStatus,
    fgtsValidade,
    fgtsLink,
    inssStatus,
    inssValidade,
    inssLink,
    federalStatus,
    federalValidade,
    federalLink,
    estadualStatus,
    estadualValidade,
    estadualLink,
    municipalStatus,
    municipalValidade,
    municipalLink,
    cndtStatus,
    cndtValidade,
    cndtLink,
    contratoSocialLink,
    cartaoCnpjLink,
    atestadosStatus,
    atestadosLinks,
    modalidade,
    numeroProcesso,
    ataSessaoLink,
    ataAdjudicacaoLink,
    editalLink,
    oficiosLinks,
    situacaoHabilitacao,
    dataConclusao,
    parecerConclusivo,
  ];
}

// -----------------------------------------------------------------------------
// Mapeamento para estrutura em seções (Firest
// -----------------------------------------------------------------------------
extension HabilitacaoDataSections on HabilitacaoData {
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      HabilitacaoSections.metadados: {
        'numeroDossie': numeroDossie,
        'dataMontagem': dataMontagem,
        'responsavelNome': responsavelNome,
        'responsavelUserId': responsavelUserId,
        'linksPasta': linksPasta,
      },
      HabilitacaoSections.empresa: {
        'razaoSocial': razaoSocial,
        'cnpj': cnpj,
        'sociosRepresentantes': sociosRepresentantes,
      },
      HabilitacaoSections.certidoes: {
        'fgtsStatus': fgtsStatus,
        'fgtsValidade': fgtsValidade,
        'fgtsLink': fgtsLink,
        'inssStatus': inssStatus,
        'inssValidade': inssValidade,
        'inssLink': inssLink,
        'federalStatus': federalStatus,
        'federalValidade': federalValidade,
        'federalLink': federalLink,
        'estadualStatus': estadualStatus,
        'estadualValidade': estadualValidade,
        'estadualLink': estadualLink,
        'municipalStatus': municipalStatus,
        'municipalValidade': municipalValidade,
        'municipalLink': municipalLink,
        'cndtStatus': cndtStatus,
        'cndtValidade': cndtValidade,
        'cndtLink': cndtLink,
      },
      HabilitacaoSections.juridicaTecnica: {
        'contratoSocialLink': contratoSocialLink,
        'cartaoCnpjLink': cartaoCnpjLink,
        'atestadosStatus': atestadosStatus,
        'atestadosLinks': atestadosLinks,
      },
      HabilitacaoSections.licitacaoAdesao: {
        'modalidade': modalidade,
        'numeroProcesso': numeroProcesso,
        'ataSessaoLink': ataSessaoLink,
        'ataAdjudicacaoLink': ataAdjudicacaoLink,
        'editalLink': editalLink,
        'oficiosLinks': oficiosLinks,
      },
      HabilitacaoSections.consolidacao: {
        'situacaoHabilitacao': situacaoHabilitacao,
        'dataConclusao': dataConclusao,
        'parecerConclusivo': parecerConclusivo,
      },
    };
  }
}
