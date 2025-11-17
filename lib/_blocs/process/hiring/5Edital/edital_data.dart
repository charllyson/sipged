// lib/_blocs/process/hiring/5Edital/edital_data.dart
import 'package:equatable/equatable.dart';

import 'edital_sections.dart';

/// Data model do Edital (SEM controller, igual ao DfdData)
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
  final String observacoes;         // edObservacoesCtrl

  // ===== 2) SESSÃO =====
  final String dataSessao;          // sjDataSessaoCtrl
  final String horaSessao;          // sjHoraSessaoCtrl
  final String responsavel;         // sjResponsavelCtrl
  final String localPlataforma;     // sjLocalPlataformaCtrl

  // ===== 3) PROPOSTAS =====
  final List<PropostaLicData> propostas; // items: [...]

  // ===== 4) LANCES =====
  final List<LanceData> lances;         // items: [...]

  // ===== 5) JULGAMENTO / ATAS / RECURSOS =====
  final String parecer;             // sjParecerCtrl
  final String criterioAplicado;    // sjCriterioAplicadoCtrl
  final String linkAta;             // sjLinkAtaCtrl
  final String recursosHouve;       // sjRecursosHouveCtrl
  final String decisaoRecursos;     // sjDecisaoRecursosCtrl
  final String linksRecursos;       // sjLinksRecursosCtrl

  // ===== 6) RESULTADO / ADJUDICAÇÃO / HOMOLOGAÇÃO =====
  final String vencedor;                // sjVencedorCtrl
  final String vencedorCnpj;            // sjVencedorCnpjCtrl
  final String valorVencedor;           // sjValorVencedorCtrl
  final String dataResultado;           // sjDataResultadoCtrl
  final String adjudicacaoData;         // sjAdjudicacaoDataCtrl
  final String adjudicacaoLink;         // sjAdjudicacaoLinkCtrl
  final String homologacaoData;         // sjHomologacaoDataCtrl
  final String homologacaoLink;         // sjHomologacaoLinkCtrl
  final bool highlightWinner;           // highlightWinner
  final bool habilitarSomenteVencedor;  // habilitarSomenteVencedor

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
    this.propostas = const [],

    // 4) LANCES
    this.lances = const [],

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

  /// "Vazio" padrão (idêntico ao construtor default)
  const EditalData.empty() : this();

  // ---------------------------------------------------------------------------
  // Map "flat" (sem seções) — compat direto com Firestore, se precisar
  //  (chaves iguais às do controller antigo onde fizer sentido)
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
    'propostasItems': propostas.map((p) => p.toMap()).toList(),
    'lancesItems': lances.map((l) => l.toMap()).toList(),

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

    final propostasItems = (map['propostasItems'] as List?) ?? const [];
    final lancesItems = (map['lancesItems'] as List?) ?? const [];

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
      propostas: propostasItems
          .map((m) => PropostaLicData.fromMap(
          Map<String, dynamic>.from(m as Map)))
          .toList(),
      lances: lancesItems
          .map((m) =>
          LanceData.fromMap(Map<String, dynamic>.from(m as Map)))
          .toList(),
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
      highlightWinner:
      (map['highlightWinner'] as bool?) ?? false,
      habilitarSomenteVencedor:
      (map['habilitarSomenteVencedor'] as bool?) ?? false,
    );
  }

  // ---------------------------------------------------------------------------
  // fromSectionsMap: MESMA lógica do antigo fromSectionMaps()
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
    final linksPublicacoes =
    (div['linksPublicacoes'] ?? '').toString();
    final dataPublicacao =
    (div['dataPublicacao'] ?? '').toString();
    final prazoImpugnacao =
    (div['prazoImpugnacao'] ?? '').toString();
    final prazoPropostas =
    (div['prazoPropostas'] ?? '').toString();
    final observacoesDiv =
    (div['observacoes'] ?? '').toString();

    // 2) SESSÃO
    final sess = s[EditalSections.sessao] ?? const {};
    final dataSessao = (sess['dataSessao'] ?? '').toString();
    final horaSessao = (sess['horaSessao'] ?? '').toString();
    final responsavel =
    (sess['responsavel'] ?? '').toString();
    final localPlataforma =
    (sess['localPlataforma'] ?? '').toString();

    // 3) PROPOSTAS
    final pro = s[EditalSections.propostas] ?? const {};
    final itemsP = (pro['items'] as List?) ?? const [];
    final propostas = itemsP
        .map((m) => PropostaLicData.fromMap(
        Map<String, dynamic>.from(m as Map)))
        .toList();

    // 4) LANCES
    final la = s[EditalSections.lances] ?? const {};
    final itemsL = (la['items'] as List?) ?? const [];
    final lances = itemsL
        .map((m) =>
        LanceData.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList();

    // 5) JULGAMENTO
    final jul = s[EditalSections.julgamento] ?? const {};
    String parecer = (jul['parecer'] ?? '').toString();
    String criterioAplicado =
    (jul['criterioAplicado'] ?? '').toString();
    String linkAta = (jul['linkAta'] ?? '').toString();
    String recursosHouve =
    (jul['recursosHouve'] ?? '').toString();
    String decisaoRecursos =
    (jul['decisaoRecursos'] ?? '').toString();
    String linksRecursos =
    (jul['linksRecursos'] ?? '').toString();

    // 6) RESULTADO
    final res = s[EditalSections.resultado] ?? const {};
    final vencedor = (res['vencedor'] ?? '').toString();
    final vencedorCnpj =
    (res['vencedorCnpj'] ?? '').toString();
    final valorVencedor =
    (res['valorVencedor'] ?? '').toString();
    final dataResultado =
    (res['dataResultado'] ?? '').toString();
    final adjudicacaoData =
    (res['adjudicacaoData'] ?? '').toString();
    final adjudicacaoLink =
    (res['adjudicacaoLink'] ?? '').toString();
    final homologacaoData =
    (res['homologacaoData'] ?? '').toString();
    final homologacaoLink =
    (res['homologacaoLink'] ?? '').toString();
    final highlightWinner =
        (res['highlightWinner'] as bool?) ?? false;
    final habilitarSomenteVencedor =
        (res['habilitarSomenteVencedor'] as bool?) ?? false;

    // 7) RECURSOS (espelho opcional, igual ao controller)
    final rec = s[EditalSections.recursos] ?? const {};
    final recHouve = (rec['houve'] ?? '').toString();
    final recDecisao = (rec['decisao'] ?? '').toString();
    final recLinks = (rec['links'] ?? '').toString();

    // Replicar lógica de "espelho": se vier algo em recursos, sobrescreve
    if (recHouve.isNotEmpty) {
      recursosHouve = recHouve;
    }
    if (recDecisao.isNotEmpty) {
      decisaoRecursos = recDecisao;
    }
    if (recLinks.isNotEmpty) {
      linksRecursos = recLinks;
    }

    // 8) OBSERVAÇÕES (seção própria; espelha edObservacoesCtrl)
    final obsSec = s[EditalSections.observacoes] ?? const {};
    final observacoesSec =
    (obsSec['observacoes'] ?? '').toString();

    final observacoes =
    observacoesSec.isNotEmpty ? observacoesSec : observacoesDiv;

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
      propostas: propostas,
      lances: lances,
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
    List<PropostaLicData>? propostas,
    List<LanceData>? lances,
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
      linksPublicacoes:
      linksPublicacoes ?? this.linksPublicacoes,
      dataPublicacao: dataPublicacao ?? this.dataPublicacao,
      prazoImpugnacao:
      prazoImpugnacao ?? this.prazoImpugnacao,
      prazoPropostas: prazoPropostas ?? this.prazoPropostas,
      observacoes: observacoes ?? this.observacoes,
      dataSessao: dataSessao ?? this.dataSessao,
      horaSessao: horaSessao ?? this.horaSessao,
      responsavel: responsavel ?? this.responsavel,
      localPlataforma:
      localPlataforma ?? this.localPlataforma,
      propostas: propostas ?? this.propostas,
      lances: lances ?? this.lances,
      parecer: parecer ?? this.parecer,
      criterioAplicado:
      criterioAplicado ?? this.criterioAplicado,
      linkAta: linkAta ?? this.linkAta,
      recursosHouve: recursosHouve ?? this.recursosHouve,
      decisaoRecursos:
      decisaoRecursos ?? this.decisaoRecursos,
      linksRecursos: linksRecursos ?? this.linksRecursos,
      vencedor: vencedor ?? this.vencedor,
      vencedorCnpj: vencedorCnpj ?? this.vencedorCnpj,
      valorVencedor: valorVencedor ?? this.valorVencedor,
      dataResultado: dataResultado ?? this.dataResultado,
      adjudicacaoData:
      adjudicacaoData ?? this.adjudicacaoData,
      adjudicacaoLink:
      adjudicacaoLink ?? this.adjudicacaoLink,
      homologacaoData:
      homologacaoData ?? this.homologacaoData,
      homologacaoLink:
      homologacaoLink ?? this.homologacaoLink,
      highlightWinner:
      highlightWinner ?? this.highlightWinner,
      habilitarSomenteVencedor:
      habilitarSomenteVencedor ??
          this.habilitarSomenteVencedor,
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
    propostas,
    lances,
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

// -----------------------------------------------------------------------------
// Mapeamento p/ estrutura em seções (MESMA usada no Firestore antigo)
// -----------------------------------------------------------------------------
extension EditalDataSections on EditalData {
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
        'items': propostas.map((p) => p.toMap()).toList(),
      },
      EditalSections.lances: {
        'items': lances.map((l) => l.toMap()).toList(),
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
}
