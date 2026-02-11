// lib/_blocs/modules/contracts/hiring/5Edital/edital_data.dart
import 'package:equatable/equatable.dart';

import 'edital_sections.dart';

/// Data model do Edital (SEM controller / ChangeNotifier)
///
/// - Mantém os MESMOS nomes de campos do EditalJulgamentoController antigo.
///   (licitante, cnpj, valor, status, motivoDesclass, link, dataHora).
class EditalData extends Equatable {
  // ===== 1) DIVULGAÇÃO / PNCP / PRAZOS =====
  final String numero;              // edNumeroCtrl
  final String modalidade;          // edModalidadeCtrl
  final String criterio;            // edCriterioCtrl
  final String idPncp;              // edIdPncpCtrl
  final String linkPncp;            // edLinkPncpCtrl
  final String linkSei;             // edLinkSeiCtrl
  final String linksPublicacoes;    // edLinksPublicacoesCtrl
  final String dataPublicacao;      // edDataPublicacaoCtrl
  final String prazoImpugnacao;     // edPrazoImpugnacaoCtrl
  final String prazoPropostas;      // edPrazoPropostasCtrl
  final String observacoes;         // edObservacoesCtrl (também espelhado na seção observacoes)

  // ===== 2) SESSÃO =====
  final String dataSessao;          // sjDataSessaoCtrl
  final String horaSessao;          // sjHoraSessaoCtrl
  final String responsavel;         // sjResponsavelCtrl
  final String localPlataforma;     // sjLocalPlataformaCtrl

  // ===== 3) PROPOSTAS =====
  /// Lista de propostas:
  /// cada item: {
  ///   'licitante': String,
  ///   'cnpj': String,
  ///   'valor': String,
  ///   'status': String,
  ///   'motivoDesclass': String,
  ///   'link': String,
  /// }
  final List<Map<String, dynamic>> propostasItems;

  // ===== 4) LANCES =====
  /// Lista de lances:
  /// cada item: {
  ///   'licitante': String,
  ///   'valor': String,
  ///   'dataHora': String,
  /// }
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

  const EditalData({
    // 1) DIVULGAÇÃO
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

    // 2) SESSÃO
    this.dataSessao = '',
    this.horaSessao = '',
    this.responsavel = '',
    this.localPlataforma = '',

    // 3) PROPOSTAS
    this.propostasItems = const [],

    // 4) LANCES
    this.lancesItems = const [],

    // 5) JULGAMENTO
    this.parecer = '',
    this.criterioAplicado = '',
    this.linkAta = '',
    this.recursosHouve = '',
    this.decisaoRecursos = '',
    this.linksRecursos = '',

    // 6) RESULTADO
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
  });

  const EditalData.empty() : this();

  // ---------------------------------------------------------------------------
  // Map "flat" (sem seções) — se precisar salvar tudo em um único doc
  // ---------------------------------------------------------------------------
  Map<String, dynamic> toMap() => {
    // 1) DIVULGAÇÃO
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

    // 2) SESSÃO
    'dataSessao': dataSessao,
    'horaSessao': horaSessao,
    'responsavel': responsavel,
    'localPlataforma': localPlataforma,

    // 3) PROPOSTAS / 4) LANCES
    'propostasItems': propostasItems,
    'lancesItems': lancesItems,

    // 5) JULGAMENTO
    'parecer': parecer,
    'criterioAplicado': criterioAplicado,
    'linkAta': linkAta,
    'recursosHouve': recursosHouve,
    'decisaoRecursos': decisaoRecursos,
    'linksRecursos': linksRecursos,

    // 6) RESULTADO
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
  };

  factory EditalData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const EditalData.empty();

    final propostasItems =
        (map['propostasItems'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ??
            const <Map<String, dynamic>>[];

    final lancesItems =
        (map['lancesItems'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ??
            const <Map<String, dynamic>>[];

    return EditalData(
      numero: (map['numero'] ?? '').toString(),
      modalidade: (map['modalidade'] ?? '').toString(),
      criterio: (map['criterio'] ?? '').toString(),
      idPncp: (map['idPncp'] ?? '').toString(),
      linkPncp: (map['linkPncp'] ?? '').toString(),
      linkSei: (map['linkSei'] ?? '').toString(),
      linksPublicacoes: (map['linksPublicacoes'] ?? '').toString(),
      dataPublicacao: (map['dataPublicacao'] ?? '').toString(),
      prazoImpugnacao: (map['prazoImpugnacao'] ?? '').toString(),
      prazoPropostas: (map['prazoPropostas'] ?? '').toString(),
      observacoes: (map['observacoes'] ?? '').toString(),
      dataSessao: (map['dataSessao'] ?? '').toString(),
      horaSessao: (map['horaSessao'] ?? '').toString(),
      responsavel: (map['responsavel'] ?? '').toString(),
      localPlataforma: (map['localPlataforma'] ?? '').toString(),
      propostasItems: propostasItems,
      lancesItems: lancesItems,
      parecer: (map['parecer'] ?? '').toString(),
      criterioAplicado: (map['criterioAplicado'] ?? '').toString(),
      linkAta: (map['linkAta'] ?? '').toString(),
      recursosHouve: (map['recursosHouve'] ?? '').toString(),
      decisaoRecursos: (map['decisaoRecursos'] ?? '').toString(),
      linksRecursos: (map['linksRecursos'] ?? '').toString(),
      vencedor: (map['vencedor'] ?? '').toString(),
      vencedorCnpj: (map['vencedorCnpj'] ?? '').toString(),
      valorVencedor: (map['valorVencedor'] ?? '').toString(),
      dataResultado: (map['dataResultado'] ?? '').toString(),
      adjudicacaoData: (map['adjudicacaoData'] ?? '').toString(),
      adjudicacaoLink: (map['adjudicacaoLink'] ?? '').toString(),
      homologacaoData: (map['homologacaoData'] ?? '').toString(),
      homologacaoLink: (map['homologacaoLink'] ?? '').toString(),
      highlightWinner: (map['highlightWinner'] as bool?) ?? false,
      habilitarSomenteVencedor:
      (map['habilitarSomenteVencedor'] as bool?) ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // fromSectionsMap — mesma lógica do antigo EditalJulgamentoController
  // ---------------------------------------------------------------------------
  factory EditalData.fromSectionsMap(
      Map<String, Map<String, dynamic>> s,
      ) {
    // 1) DIVULGAÇÃO
    final div = s[EditalSections.divulgacao] ?? const {};
    final numero = (div['numero'] ?? '').toString();
    final modalidade = (div['modalidade'] ?? '').toString();
    final criterio = (div['criterio'] ?? '').toString();
    final idPncp = (div['idPncp'] ?? '').toString();
    final linkPncp = (div['linkPncp'] ?? '').toString();
    final linkSei = (div['linkSei'] ?? '').toString();
    final linksPublicacoes = (div['linksPublicacoes'] ?? '').toString();
    final dataPublicacao = (div['dataPublicacao'] ?? '').toString();
    final prazoImpugnacao = (div['prazoImpugnacao'] ?? '').toString();
    final prazoPropostas = (div['prazoPropostas'] ?? '').toString();
    final observacoesDiv = (div['observacoes'] ?? '').toString();

    // 2) SESSÃO
    final sess = s[EditalSections.sessao] ?? const {};
    final dataSessao = (sess['dataSessao'] ?? '').toString();
    final horaSessao = (sess['horaSessao'] ?? '').toString();
    final responsavel = (sess['responsavel'] ?? '').toString();
    final localPlataforma = (sess['localPlataforma'] ?? '').toString();

    // 3) PROPOSTAS
    final pro = s[EditalSections.propostas] ?? const {};
    final itemsP = (pro['items'] as List?) ?? const [];
    final propostasItems = itemsP
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    // 4) LANCES
    final la = s[EditalSections.lances] ?? const {};
    final itemsL = (la['items'] as List?) ?? const [];
    final lancesItems = itemsL
        .map((m) => Map<String, dynamic>.from(m as Map))
        .toList();

    // 5) JULGAMENTO
    final jul = s[EditalSections.julgamento] ?? const {};
    String parecer = (jul['parecer'] ?? '').toString();
    String criterioAplicado = (jul['criterioAplicado'] ?? '').toString();
    String linkAta = (jul['linkAta'] ?? '').toString();
    String recursosHouve = (jul['recursosHouve'] ?? '').toString();
    String decisaoRecursos = (jul['decisaoRecursos'] ?? '').toString();
    String linksRecursos = (jul['linksRecursos'] ?? '').toString();

    // 6) RESULTADO
    final res = s[EditalSections.resultado] ?? const {};
    final vencedor = (res['vencedor'] ?? '').toString();
    final vencedorCnpj = (res['vencedorCnpj'] ?? '').toString();
    final valorVencedor = (res['valorVencedor'] ?? '').toString();
    final dataResultado = (res['dataResultado'] ?? '').toString();
    final adjudicacaoData = (res['adjudicacaoData'] ?? '').toString();
    final adjudicacaoLink = (res['adjudicacaoLink'] ?? '').toString();
    final homologacaoData = (res['homologacaoData'] ?? '').toString();
    final homologacaoLink = (res['homologacaoLink'] ?? '').toString();
    final highlightWinner = (res['highlightWinner'] as bool?) ?? false;
    final habilitarSomenteVencedor =
        (res['habilitarSomenteVencedor'] as bool?) ?? false;

    // 7) RECURSOS (espelho opcional)
    final rec = s[EditalSections.recursos] ?? const {};
    final recHouve = (rec['houve'] ?? '').toString();
    final recDecisao = (rec['decisao'] ?? '').toString();
    final recLinks = (rec['links'] ?? '').toString();

    // Mesma lógica do controller: se veio algo em recursos, sobrescreve
    if (recHouve.isNotEmpty) {
      recursosHouve = recHouve;
    }
    if (recDecisao.isNotEmpty) {
      decisaoRecursos = recDecisao;
    }
    if (recLinks.isNotEmpty) {
      linksRecursos = recLinks;
    }

    // 8) OBSERVAÇÕES (seção própria, espelha edObservacoesCtrl)
    final obsSec = s[EditalSections.observacoes] ?? const {};
    final observacoesSec = (obsSec['observacoes'] ?? '').toString();
    final observacoes = observacoesSec.isNotEmpty ? observacoesSec : observacoesDiv;

    return EditalData(
      numero: numero,
      modalidade: modalidade,
      criterio: criterio,
      idPncp: idPncp,
      linkPncp: linkPncp,
      linkSei: linkSei,
      linksPublicacoes: linksPublicacoes,
      dataPublicacao: dataPublicacao,
      prazoImpugnacao: prazoImpugnacao,
      prazoPropostas: prazoPropostas,
      observacoes: observacoes,
      dataSessao: dataSessao,
      horaSessao: horaSessao,
      responsavel: responsavel,
      localPlataforma: localPlataforma,
      propostasItems: propostasItems,
      lancesItems: lancesItems,
      parecer: parecer,
      criterioAplicado: criterioAplicado,
      linkAta: linkAta,
      recursosHouve: recursosHouve,
      decisaoRecursos: decisaoRecursos,
      linksRecursos: linksRecursos,
      vencedor: vencedor,
      vencedorCnpj: vencedorCnpj,
      valorVencedor: valorVencedor,
      dataResultado: dataResultado,
      adjudicacaoData: adjudicacaoData,
      adjudicacaoLink: adjudicacaoLink,
      homologacaoData: homologacaoData,
      homologacaoLink: homologacaoLink,
      highlightWinner: highlightWinner,
      habilitarSomenteVencedor: habilitarSomenteVencedor,
    );
  }

  // ---------------------------------------------------------------------------
  // toSectionsMap — mesma estrutura do toSectionMaps() antigo
  // ---------------------------------------------------------------------------
  Map<String, Map<String, dynamic>> toSectionsMap() {
    return {
      EditalSections.divulgacao: {
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
      EditalSections.sessao: {
        'dataSessao': dataSessao,
        'horaSessao': horaSessao,
        'responsavel': responsavel,
        'localPlataforma': localPlataforma,
      },
      EditalSections.propostas: {
        'items': propostasItems,
      },
      EditalSections.lances: {
        'items': lancesItems,
      },
      EditalSections.julgamento: {
        'parecer': parecer,
        'criterioAplicado': criterioAplicado,
        'linkAta': linkAta,
        'recursosHouve': recursosHouve,
        'decisaoRecursos': decisaoRecursos,
        'linksRecursos': linksRecursos,
      },
      EditalSections.resultado: {
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
      EditalSections.recursos: {
        'houve': recursosHouve,
        'decisao': decisaoRecursos,
        'links': linksRecursos,
      },
      EditalSections.observacoes: {
        'observacoes': observacoes,
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
    );
  }

  @override
  List<Object?> get props => [
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
  ];
}
