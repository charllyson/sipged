// lib/_blocs/modules/contracts/hiring/5Edital/edital_data.dart

import 'package:equatable/equatable.dart';

class EditalData extends Equatable {
  /// Chaves estáveis para as seções do Edital.
  /// Substitui o antigo arquivo edital_sections.dart.
  static const sectionDivulgacao = 'divulgacao';
  static const sectionSessao = 'sessao';
  static const sectionPropostas = 'propostas';
  static const sectionLances = 'lances';
  static const sectionJulgamento = 'julgamento';
  static const sectionResultado = 'resultado';
  static const sectionRecursos = 'recursos';
  static const sectionObservacoes = 'observacoes';
  static const sectionDocumentos = 'documentos';

  static const sectionKeys = <String>[
    sectionDivulgacao,
    sectionSessao,
    sectionPropostas,
    sectionLances,
    sectionJulgamento,
    sectionResultado,
    sectionRecursos,
    sectionObservacoes,
    sectionDocumentos,
  ];

  // ===== 1) DIVULGAÇÃO / PNCP / PRAZOS =====
  final String numero;
  final String modalidade;
  final String criterio;
  final String idPncp;
  final String linkPncp;
  final String linkSei;
  final String linksPublicacoes;
  final String dataPublicacao;
  final String prazoImpugnacao;
  final String prazoPropostas;
  final String observacoes;

  // ===== 2) SESSÃO =====
  final String dataSessao;
  final String horaSessao;
  final String responsavel;
  final String localPlataforma;

  // ===== 3) PROPOSTAS =====
  final List<Map<String, dynamic>> propostasItems;

  // ===== 4) LANCES =====
  final List<Map<String, dynamic>> lancesItems;

  // ===== 5) JULGAMENTO / ATAS / RECURSOS =====
  final String parecer;
  final String criterioAplicado;
  final String linkAta;
  final String recursosHouve;
  final String decisaoRecursos;
  final String linksRecursos;

  // ===== 6) RESULTADO / ADJUDICAÇÃO / HOMOLOGAÇÃO =====
  final String vencedor;
  final String vencedorCnpj;
  final String valorVencedor;
  final String dataResultado;
  final String adjudicacaoData;
  final String adjudicacaoLink;
  final String homologacaoData;
  final String homologacaoLink;
  final bool highlightWinner;
  final bool habilitarSomenteVencedor;

  // ===== 7) DOCUMENTOS =====
  final String linksDocumentos;

  const EditalData({
    this.numero = '',
    this.modalidade = '',
    this.criterio = '',
    this.idPncp = '',
    this.linkPncp = '',
    this.linkSei = '',
    this.linksPublicacoes = '',
    this.dataPublicacao = '',
    this.prazoImpugnacao = '',
    this.prazoPropostas = '',
    this.observacoes = '',
    this.dataSessao = '',
    this.horaSessao = '',
    this.responsavel = '',
    this.localPlataforma = '',
    this.propostasItems = const <Map<String, dynamic>>[],
    this.lancesItems = const <Map<String, dynamic>>[],
    this.parecer = '',
    this.criterioAplicado = '',
    this.linkAta = '',
    this.recursosHouve = '',
    this.decisaoRecursos = '',
    this.linksRecursos = '',
    this.vencedor = '',
    this.vencedorCnpj = '',
    this.valorVencedor = '',
    this.dataResultado = '',
    this.adjudicacaoData = '',
    this.adjudicacaoLink = '',
    this.homologacaoData = '',
    this.homologacaoLink = '',
    this.highlightWinner = false,
    this.habilitarSomenteVencedor = false,
    this.linksDocumentos = '',
  });

  const EditalData.empty() : this();

  static String _text(dynamic value) {
    return (value ?? '').toString();
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;

    final text = value?.toString().trim().toLowerCase();

    if (text == 'true' || text == '1' || text == 'sim') return true;
    if (text == 'false' || text == '0' || text == 'nao' || text == 'não') {
      return false;
    }

    return false;
  }

  static List<Map<String, dynamic>> _items(dynamic value) {
    if (value is! List) return const <Map<String, dynamic>>[];

    return value.whereType<Map>().map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'numero': numero,
      'modalidade': modalidade,
      'criterio': criterio,
      'idPncp': idPncp,
      'linkPncp': linkPncp,
      'linkSei': linkSei,
      'linksPublicacoes': linksPublicacoes,
      'dataPublicacao': dataPublicacao,
      'prazoImpugnacao': prazoImpugnacao,
      'prazoPropostas': prazoPropostas,
      'observacoes': observacoes,
      'dataSessao': dataSessao,
      'horaSessao': horaSessao,
      'responsavel': responsavel,
      'localPlataforma': localPlataforma,
      'propostasItems': propostasItems,
      'lancesItems': lancesItems,
      'parecer': parecer,
      'criterioAplicado': criterioAplicado,
      'linkAta': linkAta,
      'recursosHouve': recursosHouve,
      'decisaoRecursos': decisaoRecursos,
      'linksRecursos': linksRecursos,
      'vencedor': vencedor,
      'vencedorCnpj': vencedorCnpj,
      'valorVencedor': valorVencedor,
      'dataResultado': dataResultado,
      'adjudicacaoData': adjudicacaoData,
      'adjudicacaoLink': adjudicacaoLink,
      'homologacaoData': homologacaoData,
      'homologacaoLink': homologacaoLink,
      'highlightWinner': highlightWinner,
      'habilitarSomenteVencedor': habilitarSomenteVencedor,
      'linksDocumentos': linksDocumentos,
    };
  }

  factory EditalData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EditalData.empty();

    return EditalData(
      numero: _text(map['numero']),
      modalidade: _text(map['modalidade']),
      criterio: _text(map['criterio']),
      idPncp: _text(map['idPncp']),
      linkPncp: _text(map['linkPncp']),
      linkSei: _text(map['linkSei']),
      linksPublicacoes: _text(map['linksPublicacoes']),
      dataPublicacao: _text(map['dataPublicacao']),
      prazoImpugnacao: _text(map['prazoImpugnacao']),
      prazoPropostas: _text(map['prazoPropostas']),
      observacoes: _text(map['observacoes']),
      dataSessao: _text(map['dataSessao']),
      horaSessao: _text(map['horaSessao']),
      responsavel: _text(map['responsavel']),
      localPlataforma: _text(map['localPlataforma']),
      propostasItems: _items(map['propostasItems']),
      lancesItems: _items(map['lancesItems']),
      parecer: _text(map['parecer']),
      criterioAplicado: _text(map['criterioAplicado']),
      linkAta: _text(map['linkAta']),
      recursosHouve: _text(map['recursosHouve']),
      decisaoRecursos: _text(map['decisaoRecursos']),
      linksRecursos: _text(map['linksRecursos']),
      vencedor: _text(map['vencedor']),
      vencedorCnpj: _text(map['vencedorCnpj']),
      valorVencedor: _text(map['valorVencedor']),
      dataResultado: _text(map['dataResultado']),
      adjudicacaoData: _text(map['adjudicacaoData']),
      adjudicacaoLink: _text(map['adjudicacaoLink']),
      homologacaoData: _text(map['homologacaoData']),
      homologacaoLink: _text(map['homologacaoLink']),
      highlightWinner: _bool(map['highlightWinner']),
      habilitarSomenteVencedor: _bool(map['habilitarSomenteVencedor']),
      linksDocumentos: _text(map['linksDocumentos']),
    );
  }

  factory EditalData.fromSectionsMap(
      Map<String, Map<String, dynamic>> sections,
      ) {
    final div = sections[sectionDivulgacao] ?? const <String, dynamic>{};
    final sess = sections[sectionSessao] ?? const <String, dynamic>{};
    final pro = sections[sectionPropostas] ?? const <String, dynamic>{};
    final lan = sections[sectionLances] ?? const <String, dynamic>{};
    final jul = sections[sectionJulgamento] ?? const <String, dynamic>{};
    final res = sections[sectionResultado] ?? const <String, dynamic>{};
    final rec = sections[sectionRecursos] ?? const <String, dynamic>{};
    final obs = sections[sectionObservacoes] ?? const <String, dynamic>{};
    final doc = sections[sectionDocumentos] ?? const <String, dynamic>{};

    String recursosHouve = _text(jul['recursosHouve']);
    String decisaoRecursos = _text(jul['decisaoRecursos']);
    String linksRecursos = _text(jul['linksRecursos']);

    final recHouve = _text(rec['houve']);
    final recDecisao = _text(rec['decisao']);
    final recLinks = _text(rec['links']);

    if (recHouve.trim().isNotEmpty) {
      recursosHouve = recHouve;
    }

    if (recDecisao.trim().isNotEmpty) {
      decisaoRecursos = recDecisao;
    }

    if (recLinks.trim().isNotEmpty) {
      linksRecursos = recLinks;
    }

    final observacoesDiv = _text(div['observacoes']);
    final observacoesSec = _text(obs['observacoes']);
    final observacoes =
    observacoesSec.trim().isNotEmpty ? observacoesSec : observacoesDiv;

    return EditalData(
      numero: _text(div['numero']),
      modalidade: _text(div['modalidade']),
      criterio: _text(div['criterio']),
      idPncp: _text(div['idPncp']),
      linkPncp: _text(div['linkPncp']),
      linkSei: _text(div['linkSei']),
      linksPublicacoes: _text(div['linksPublicacoes']),
      dataPublicacao: _text(div['dataPublicacao']),
      prazoImpugnacao: _text(div['prazoImpugnacao']),
      prazoPropostas: _text(div['prazoPropostas']),
      observacoes: observacoes,
      dataSessao: _text(sess['dataSessao']),
      horaSessao: _text(sess['horaSessao']),
      responsavel: _text(sess['responsavel']),
      localPlataforma: _text(sess['localPlataforma']),
      propostasItems: _items(pro['items']),
      lancesItems: _items(lan['items']),
      parecer: _text(jul['parecer']),
      criterioAplicado: _text(jul['criterioAplicado']),
      linkAta: _text(jul['linkAta']),
      recursosHouve: recursosHouve,
      decisaoRecursos: decisaoRecursos,
      linksRecursos: linksRecursos,
      vencedor: _text(res['vencedor']),
      vencedorCnpj: _text(res['vencedorCnpj']),
      valorVencedor: _text(res['valorVencedor']),
      dataResultado: _text(res['dataResultado']),
      adjudicacaoData: _text(res['adjudicacaoData']),
      adjudicacaoLink: _text(res['adjudicacaoLink']),
      homologacaoData: _text(res['homologacaoData']),
      homologacaoLink: _text(res['homologacaoLink']),
      highlightWinner: _bool(res['highlightWinner']),
      habilitarSomenteVencedor: _bool(res['habilitarSomenteVencedor']),
      linksDocumentos: _text(doc['linksDocumentos']),
    );
  }

  Map<String, Map<String, dynamic>> toSectionsMap() {
    return <String, Map<String, dynamic>>{
      sectionDivulgacao: <String, dynamic>{
        'numero': numero,
        'modalidade': modalidade,
        'criterio': criterio,
        'idPncp': idPncp,
        'linkPncp': linkPncp,
        'linkSei': linkSei,
        'linksPublicacoes': linksPublicacoes,
        'dataPublicacao': dataPublicacao,
        'prazoImpugnacao': prazoImpugnacao,
        'prazoPropostas': prazoPropostas,
        'observacoes': observacoes,
      },
      sectionSessao: <String, dynamic>{
        'dataSessao': dataSessao,
        'horaSessao': horaSessao,
        'responsavel': responsavel,
        'localPlataforma': localPlataforma,
      },
      sectionPropostas: <String, dynamic>{
        'items': propostasItems,
      },
      sectionLances: <String, dynamic>{
        'items': lancesItems,
      },
      sectionJulgamento: <String, dynamic>{
        'parecer': parecer,
        'criterioAplicado': criterioAplicado,
        'linkAta': linkAta,
        'recursosHouve': recursosHouve,
        'decisaoRecursos': decisaoRecursos,
        'linksRecursos': linksRecursos,
      },
      sectionResultado: <String, dynamic>{
        'vencedor': vencedor,
        'vencedorCnpj': vencedorCnpj,
        'valorVencedor': valorVencedor,
        'dataResultado': dataResultado,
        'adjudicacaoData': adjudicacaoData,
        'adjudicacaoLink': adjudicacaoLink,
        'homologacaoData': homologacaoData,
        'homologacaoLink': homologacaoLink,
        'highlightWinner': highlightWinner,
        'habilitarSomenteVencedor': habilitarSomenteVencedor,
      },
      sectionRecursos: <String, dynamic>{
        'houve': recursosHouve,
        'decisao': decisaoRecursos,
        'links': linksRecursos,
      },
      sectionObservacoes: <String, dynamic>{
        'observacoes': observacoes,
      },
      sectionDocumentos: <String, dynamic>{
        'linksDocumentos': linksDocumentos,
      },
    };
  }

  EditalData copyWith({
    String? numero,
    String? modalidade,
    String? criterio,
    String? idPncp,
    String? linkPncp,
    String? linkSei,
    String? linksPublicacoes,
    String? dataPublicacao,
    String? prazoImpugnacao,
    String? prazoPropostas,
    String? observacoes,
    String? dataSessao,
    String? horaSessao,
    String? responsavel,
    String? localPlataforma,
    List<Map<String, dynamic>>? propostasItems,
    List<Map<String, dynamic>>? lancesItems,
    String? parecer,
    String? criterioAplicado,
    String? linkAta,
    String? recursosHouve,
    String? decisaoRecursos,
    String? linksRecursos,
    String? vencedor,
    String? vencedorCnpj,
    String? valorVencedor,
    String? dataResultado,
    String? adjudicacaoData,
    String? adjudicacaoLink,
    String? homologacaoData,
    String? homologacaoLink,
    bool? highlightWinner,
    bool? habilitarSomenteVencedor,
    String? linksDocumentos,
  }) {
    return EditalData(
      numero: numero ?? this.numero,
      modalidade: modalidade ?? this.modalidade,
      criterio: criterio ?? this.criterio,
      idPncp: idPncp ?? this.idPncp,
      linkPncp: linkPncp ?? this.linkPncp,
      linkSei: linkSei ?? this.linkSei,
      linksPublicacoes: linksPublicacoes ?? this.linksPublicacoes,
      dataPublicacao: dataPublicacao ?? this.dataPublicacao,
      prazoImpugnacao: prazoImpugnacao ?? this.prazoImpugnacao,
      prazoPropostas: prazoPropostas ?? this.prazoPropostas,
      observacoes: observacoes ?? this.observacoes,
      dataSessao: dataSessao ?? this.dataSessao,
      horaSessao: horaSessao ?? this.horaSessao,
      responsavel: responsavel ?? this.responsavel,
      localPlataforma: localPlataforma ?? this.localPlataforma,
      propostasItems: propostasItems ?? this.propostasItems,
      lancesItems: lancesItems ?? this.lancesItems,
      parecer: parecer ?? this.parecer,
      criterioAplicado: criterioAplicado ?? this.criterioAplicado,
      linkAta: linkAta ?? this.linkAta,
      recursosHouve: recursosHouve ?? this.recursosHouve,
      decisaoRecursos: decisaoRecursos ?? this.decisaoRecursos,
      linksRecursos: linksRecursos ?? this.linksRecursos,
      vencedor: vencedor ?? this.vencedor,
      vencedorCnpj: vencedorCnpj ?? this.vencedorCnpj,
      valorVencedor: valorVencedor ?? this.valorVencedor,
      dataResultado: dataResultado ?? this.dataResultado,
      adjudicacaoData: adjudicacaoData ?? this.adjudicacaoData,
      adjudicacaoLink: adjudicacaoLink ?? this.adjudicacaoLink,
      homologacaoData: homologacaoData ?? this.homologacaoData,
      homologacaoLink: homologacaoLink ?? this.homologacaoLink,
      highlightWinner: highlightWinner ?? this.highlightWinner,
      habilitarSomenteVencedor:
      habilitarSomenteVencedor ?? this.habilitarSomenteVencedor,
      linksDocumentos: linksDocumentos ?? this.linksDocumentos,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    numero,
    modalidade,
    criterio,
    idPncp,
    linkPncp,
    linkSei,
    linksPublicacoes,
    dataPublicacao,
    prazoImpugnacao,
    prazoPropostas,
    observacoes,
    dataSessao,
    horaSessao,
    responsavel,
    localPlataforma,
    propostasItems,
    lancesItems,
    parecer,
    criterioAplicado,
    linkAta,
    recursosHouve,
    decisaoRecursos,
    linksRecursos,
    vencedor,
    vencedorCnpj,
    valorVencedor,
    dataResultado,
    adjudicacaoData,
    adjudicacaoLink,
    homologacaoData,
    homologacaoLink,
    highlightWinner,
    habilitarSomenteVencedor,
    linksDocumentos,
  ];
}