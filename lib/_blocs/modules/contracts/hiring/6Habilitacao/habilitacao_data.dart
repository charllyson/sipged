// lib/_blocs/modules/contracts/hiring/6Habilitacao/habilitacao_data.dart

import 'package:equatable/equatable.dart';

class HabilitacaoData extends Equatable {
  /// Chaves estáveis das seções da Habilitação.
  /// Substitui o antigo arquivo habilitacao_sections.dart.
  static const sectionMetadados = 'metadados';
  static const sectionEmpresa = 'empresa';
  static const sectionCertidoes = 'certidoes';
  static const sectionJuridicaTecnica = 'juridicaTecnica';
  static const sectionLicitacaoAdesao = 'licitacaoAdesao';
  static const sectionConsolidacao = 'consolidacao';

  static const sectionKeys = <String>[
    sectionMetadados,
    sectionEmpresa,
    sectionCertidoes,
    sectionJuridicaTecnica,
    sectionLicitacaoAdesao,
    sectionConsolidacao,
  ];

  // ───── 1) Metadados ─────
  final String? numeroDossie;
  final String? dataMontagem;
  final String? responsavelNome;
  final String? responsavelUserId;
  final String? linksPasta;

  // ───── 2) Empresa ─────
  final String? razaoSocial;
  final String? cnpj;
  final String? sociosRepresentantes;

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
  final String? dataConclusao;
  final String? parecerConclusivo;

  const HabilitacaoData({
    this.numeroDossie,
    this.dataMontagem,
    this.responsavelNome,
    this.responsavelUserId,
    this.linksPasta,
    this.razaoSocial,
    this.cnpj,
    this.sociosRepresentantes,
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
    this.contratoSocialLink,
    this.cartaoCnpjLink,
    this.atestadosStatus,
    this.atestadosLinks,
    this.modalidade,
    this.numeroProcesso,
    this.ataSessaoLink,
    this.ataAdjudicacaoLink,
    this.editalLink,
    this.oficiosLinks,
    this.situacaoHabilitacao,
    this.dataConclusao,
    this.parecerConclusivo,
  });

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

  static String _text(dynamic value) {
    return (value ?? '').toString();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'numeroDossie': numeroDossie,
      'dataMontagem': dataMontagem,
      'responsavelNome': responsavelNome,
      'responsavelUserId': responsavelUserId,
      'linksPasta': linksPasta,
      'razaoSocial': razaoSocial,
      'cnpj': cnpj,
      'sociosRepresentantes': sociosRepresentantes,
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
      'contratoSocialLink': contratoSocialLink,
      'cartaoCnpjLink': cartaoCnpjLink,
      'atestadosStatus': atestadosStatus,
      'atestadosLinks': atestadosLinks,
      'modalidade': modalidade,
      'numeroProcesso': numeroProcesso,
      'ataSessaoLink': ataSessaoLink,
      'ataAdjudicacaoLink': ataAdjudicacaoLink,
      'editalLink': editalLink,
      'oficiosLinks': oficiosLinks,
      'situacaoHabilitacao': situacaoHabilitacao,
      'dataConclusao': dataConclusao,
      'parecerConclusivo': parecerConclusivo,
    };
  }

  factory HabilitacaoData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const HabilitacaoData.empty();

    return HabilitacaoData(
      numeroDossie: _text(map['numeroDossie']),
      dataMontagem: _text(map['dataMontagem']),
      responsavelNome: _text(map['responsavelNome']),
      responsavelUserId: map['responsavelUserId']?.toString(),
      linksPasta: _text(map['linksPasta']),
      razaoSocial: _text(map['razaoSocial']),
      cnpj: _text(map['cnpj']),
      sociosRepresentantes: _text(map['sociosRepresentantes']),
      fgtsStatus: _text(map['fgtsStatus']),
      fgtsValidade: _text(map['fgtsValidade']),
      fgtsLink: _text(map['fgtsLink']),
      inssStatus: _text(map['inssStatus']),
      inssValidade: _text(map['inssValidade']),
      inssLink: _text(map['inssLink']),
      federalStatus: _text(map['federalStatus']),
      federalValidade: _text(map['federalValidade']),
      federalLink: _text(map['federalLink']),
      estadualStatus: _text(map['estadualStatus']),
      estadualValidade: _text(map['estadualValidade']),
      estadualLink: _text(map['estadualLink']),
      municipalStatus: _text(map['municipalStatus']),
      municipalValidade: _text(map['municipalValidade']),
      municipalLink: _text(map['municipalLink']),
      cndtStatus: _text(map['cndtStatus']),
      cndtValidade: _text(map['cndtValidade']),
      cndtLink: _text(map['cndtLink']),
      contratoSocialLink: _text(map['contratoSocialLink']),
      cartaoCnpjLink: _text(map['cartaoCnpjLink']),
      atestadosStatus: _text(map['atestadosStatus']),
      atestadosLinks: _text(map['atestadosLinks']),
      modalidade: _text(map['modalidade']),
      numeroProcesso: _text(map['numeroProcesso']),
      ataSessaoLink: _text(map['ataSessaoLink']),
      ataAdjudicacaoLink: _text(map['ataAdjudicacaoLink']),
      editalLink: _text(map['editalLink']),
      oficiosLinks: _text(map['oficiosLinks']),
      situacaoHabilitacao: _text(map['situacaoHabilitacao']),
      dataConclusao: _text(map['dataConclusao']),
      parecerConclusivo: _text(map['parecerConclusivo']),
    );
  }

  factory HabilitacaoData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final m = sections[sectionMetadados] ?? const <String, dynamic>{};
    final e = sections[sectionEmpresa] ?? const <String, dynamic>{};
    final c = sections[sectionCertidoes] ?? const <String, dynamic>{};
    final jt = sections[sectionJuridicaTecnica] ?? const <String, dynamic>{};
    final l = sections[sectionLicitacaoAdesao] ?? const <String, dynamic>{};
    final co = sections[sectionConsolidacao] ?? const <String, dynamic>{};

    return HabilitacaoData(
      numeroDossie: _text(m['numeroDossie']),
      dataMontagem: _text(m['dataMontagem']),
      responsavelNome: _text(m['responsavelNome']),
      responsavelUserId: m['responsavelUserId']?.toString(),
      linksPasta: _text(m['linksPasta']),
      razaoSocial: _text(e['razaoSocial']),
      cnpj: _text(e['cnpj']),
      sociosRepresentantes: _text(e['sociosRepresentantes']),
      fgtsStatus: _text(c['fgtsStatus']),
      fgtsValidade: _text(c['fgtsValidade']),
      fgtsLink: _text(c['fgtsLink']),
      inssStatus: _text(c['inssStatus']),
      inssValidade: _text(c['inssValidade']),
      inssLink: _text(c['inssLink']),
      federalStatus: _text(c['federalStatus']),
      federalValidade: _text(c['federalValidade']),
      federalLink: _text(c['federalLink']),
      estadualStatus: _text(c['estadualStatus']),
      estadualValidade: _text(c['estadualValidade']),
      estadualLink: _text(c['estadualLink']),
      municipalStatus: _text(c['municipalStatus']),
      municipalValidade: _text(c['municipalValidade']),
      municipalLink: _text(c['municipalLink']),
      cndtStatus: _text(c['cndtStatus']),
      cndtValidade: _text(c['cndtValidade']),
      cndtLink: _text(c['cndtLink']),
      contratoSocialLink: _text(jt['contratoSocialLink']),
      cartaoCnpjLink: _text(jt['cartaoCnpjLink']),
      atestadosStatus: _text(jt['atestadosStatus']),
      atestadosLinks: _text(jt['atestadosLinks']),
      modalidade: _text(l['modalidade']),
      numeroProcesso: _text(l['numeroProcesso']),
      ataSessaoLink: _text(l['ataSessaoLink']),
      ataAdjudicacaoLink: _text(l['ataAdjudicacaoLink']),
      editalLink: _text(l['editalLink']),
      oficiosLinks: _text(l['oficiosLinks']),
      situacaoHabilitacao: _text(co['situacaoHabilitacao']),
      dataConclusao: _text(co['dataConclusao']),
      parecerConclusivo: _text(co['parecerConclusivo']),
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
      responsavelNome: responsavelNome ?? this.responsavelNome,
      responsavelUserId: responsavelUserId ?? this.responsavelUserId,
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
      federalStatus: federalStatus ?? this.federalStatus,
      federalValidade: federalValidade ?? this.federalValidade,
      federalLink: federalLink ?? this.federalLink,
      estadualStatus: estadualStatus ?? this.estadualStatus,
      estadualValidade: estadualValidade ?? this.estadualValidade,
      estadualLink: estadualLink ?? this.estadualLink,
      municipalStatus: municipalStatus ?? this.municipalStatus,
      municipalValidade: municipalValidade ?? this.municipalValidade,
      municipalLink: municipalLink ?? this.municipalLink,
      cndtStatus: cndtStatus ?? this.cndtStatus,
      cndtValidade: cndtValidade ?? this.cndtValidade,
      cndtLink: cndtLink ?? this.cndtLink,
      contratoSocialLink: contratoSocialLink ?? this.contratoSocialLink,
      cartaoCnpjLink: cartaoCnpjLink ?? this.cartaoCnpjLink,
      atestadosStatus: atestadosStatus ?? this.atestadosStatus,
      atestadosLinks: atestadosLinks ?? this.atestadosLinks,
      modalidade: modalidade ?? this.modalidade,
      numeroProcesso: numeroProcesso ?? this.numeroProcesso,
      ataSessaoLink: ataSessaoLink ?? this.ataSessaoLink,
      ataAdjudicacaoLink: ataAdjudicacaoLink ?? this.ataAdjudicacaoLink,
      editalLink: editalLink ?? this.editalLink,
      oficiosLinks: oficiosLinks ?? this.oficiosLinks,
      situacaoHabilitacao:
      situacaoHabilitacao ?? this.situacaoHabilitacao,
      dataConclusao: dataConclusao ?? this.dataConclusao,
      parecerConclusivo: parecerConclusivo ?? this.parecerConclusivo,
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionMetadados: <String, dynamic>{
        'numeroDossie': numeroDossie,
        'dataMontagem': dataMontagem,
        'responsavelNome': responsavelNome,
        'responsavelUserId': responsavelUserId,
        'linksPasta': linksPasta,
      },
      sectionEmpresa: <String, dynamic>{
        'razaoSocial': razaoSocial,
        'cnpj': cnpj,
        'sociosRepresentantes': sociosRepresentantes,
      },
      sectionCertidoes: <String, dynamic>{
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
      sectionJuridicaTecnica: <String, dynamic>{
        'contratoSocialLink': contratoSocialLink,
        'cartaoCnpjLink': cartaoCnpjLink,
        'atestadosStatus': atestadosStatus,
        'atestadosLinks': atestadosLinks,
      },
      sectionLicitacaoAdesao: <String, dynamic>{
        'modalidade': modalidade,
        'numeroProcesso': numeroProcesso,
        'ataSessaoLink': ataSessaoLink,
        'ataAdjudicacaoLink': ataAdjudicacaoLink,
        'editalLink': editalLink,
        'oficiosLinks': oficiosLinks,
      },
      sectionConsolidacao: <String, dynamic>{
        'situacaoHabilitacao': situacaoHabilitacao,
        'dataConclusao': dataConclusao,
        'parecerConclusivo': parecerConclusivo,
      },
    };
  }

  @override
  List<Object?> get props => <Object?>[
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