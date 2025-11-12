import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'edital_sections.dart';

class PropostaLic {
  final TextEditingController licitanteCtrl = TextEditingController();
  final TextEditingController cnpjCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();
  final TextEditingController statusCtrl = TextEditingController(); // classificada/desclassificada
  final TextEditingController motivoDesclassCtrl = TextEditingController();
  final TextEditingController linkCtrl = TextEditingController();

  Map<String, dynamic> toMap() => {
    'licitante': licitanteCtrl.text,
    'cnpj': cnpjCtrl.text,
    'valor': valorCtrl.text,
    'status': statusCtrl.text,
    'motivoDesclass': motivoDesclassCtrl.text,
    'link': linkCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    licitanteCtrl.text = m['licitante'] ?? '';
    cnpjCtrl.text = m['cnpj'] ?? '';
    valorCtrl.text = m['valor'] ?? '';
    statusCtrl.text = m['status'] ?? '';
    motivoDesclassCtrl.text = m['motivoDesclass'] ?? '';
    linkCtrl.text = m['link'] ?? '';
  }

  void dispose() {
    licitanteCtrl.dispose();
    cnpjCtrl.dispose();
    valorCtrl.dispose();
    statusCtrl.dispose();
    motivoDesclassCtrl.dispose();
    linkCtrl.dispose();
  }
}

class Lance {
  final TextEditingController licitanteCtrl = TextEditingController();
  final TextEditingController valorCtrl = TextEditingController();
  final TextEditingController dataHoraCtrl = TextEditingController();

  Map<String, dynamic> toMap() => {
    'licitante': licitanteCtrl.text,
    'valor': valorCtrl.text,
    'dataHora': dataHoraCtrl.text,
  };

  void fromMap(Map<String, dynamic> m) {
    licitanteCtrl.text = m['licitante'] ?? '';
    valorCtrl.text = m['valor'] ?? '';
    dataHoraCtrl.text = m['dataHora'] ?? '';
  }

  void dispose() {
    licitanteCtrl.dispose();
    valorCtrl.dispose();
    dataHoraCtrl.dispose();
  }
}

class EditalJulgamentoController extends ChangeNotifier {
  bool isEditable;

  EditalJulgamentoController({this.isEditable = true});

  // ===== 1) DIVULGAÇÃO / PNCP / PRAZOS =====
  final edNumeroCtrl = TextEditingController();
  final edModalidadeCtrl = TextEditingController();
  final edCriterioCtrl = TextEditingController();
  final edIdPncpCtrl = TextEditingController();
  final edLinkPncpCtrl = TextEditingController();
  final edLinkSeiCtrl = TextEditingController();
  final edLinksPublicacoesCtrl = TextEditingController();
  final edDataPublicacaoCtrl = TextEditingController();
  final edPrazoImpugnacaoCtrl = TextEditingController();
  final edPrazoPropostasCtrl = TextEditingController();
  final edObservacoesCtrl = TextEditingController();

  // ===== 2) SESSÃO =====
  final sjDataSessaoCtrl = TextEditingController();
  final sjHoraSessaoCtrl = TextEditingController();
  final sjResponsavelCtrl = TextEditingController();
  final sjLocalPlataformaCtrl = TextEditingController();

  // ===== 3) PROPOSTAS =====
  final List<PropostaLic> propostas = [];

  // ===== 4) LANCES =====
  final List<Lance> lances = [];

  // ===== 5) JULGAMENTO / ATAS / RECURSOS =====
  final sjParecerCtrl = TextEditingController();
  final sjCriterioAplicadoCtrl = TextEditingController();
  final sjLinkAtaCtrl = TextEditingController();
  final sjRecursosHouveCtrl = TextEditingController();
  final sjDecisaoRecursosCtrl = TextEditingController();
  final sjLinksRecursosCtrl = TextEditingController();

  // ===== 6) RESULTADO / ADJUDICAÇÃO / HOMOLOGAÇÃO =====
  final sjVencedorCtrl = TextEditingController();
  final sjVencedorCnpjCtrl = TextEditingController();
  final sjValorVencedorCtrl = TextEditingController();
  final sjDataResultadoCtrl = TextEditingController();

  final sjAdjudicacaoDataCtrl = TextEditingController();
  final sjAdjudicacaoLinkCtrl = TextEditingController();

  final sjHomologacaoDataCtrl = TextEditingController();
  final sjHomologacaoLinkCtrl = TextEditingController();

  bool highlightWinner = false;
  bool habilitarSomenteVencedor = false;

  // Mutators
  void addProposta() { propostas.add(PropostaLic()); notifyListeners(); }
  void removeProposta(int i) {
    if (i>=0 && i<propostas.length) { final p=propostas.removeAt(i); p.dispose(); notifyListeners(); }
  }
  void addLance() { lances.add(Lance()); notifyListeners(); }
  void removeLance(int i) {
    if (i>=0 && i<lances.length) { final l=lances.removeAt(i); l.dispose(); notifyListeners(); }
  }
  void setWinnerHighlight(bool v) { highlightWinner = v; notifyListeners(); }
  void definirVencedorPorIndice(int i) {
    if (i<0 || i>=propostas.length) return;
    final p = propostas[i];
    sjVencedorCtrl.text      = p.licitanteCtrl.text;
    sjVencedorCnpjCtrl.text  = p.cnpjCtrl.text;
    sjValorVencedorCtrl.text = p.valorCtrl.text;
    highlightWinner = true;
    notifyListeners();
  }

  Map<String, Map<String, dynamic>> toSectionMaps() => {
    EditalSections.divulgacao: {
      'numero': edNumeroCtrl.text,
      'modalidade': edModalidadeCtrl.text,
      'criterio': edCriterioCtrl.text,
      'idPncp': edIdPncpCtrl.text,
      'linkPncp': edLinkPncpCtrl.text,
      'linkSei': edLinkSeiCtrl.text,
      'linksPublicacoes': edLinksPublicacoesCtrl.text,
      'dataPublicacao': edDataPublicacaoCtrl.text,
      'prazoImpugnacao': edPrazoImpugnacaoCtrl.text,
      'prazoPropostas': edPrazoPropostasCtrl.text,
      'observacoes': edObservacoesCtrl.text,
    },
    EditalSections.sessao: {
      'dataSessao': sjDataSessaoCtrl.text,
      'horaSessao': sjHoraSessaoCtrl.text,
      'responsavel': sjResponsavelCtrl.text,
      'localPlataforma': sjLocalPlataformaCtrl.text,
    },
    EditalSections.propostas: {
      'items': propostas.map((p) => p.toMap()).toList(),
    },
    EditalSections.lances: {
      'items': lances.map((l) => l.toMap()).toList(),
    },
    EditalSections.julgamento: {
      'parecer': sjParecerCtrl.text,
      'criterioAplicado': sjCriterioAplicadoCtrl.text,
      'linkAta': sjLinkAtaCtrl.text,
      'recursosHouve': sjRecursosHouveCtrl.text,
      'decisaoRecursos': sjDecisaoRecursosCtrl.text,
      'linksRecursos': sjLinksRecursosCtrl.text,
    },
    EditalSections.resultado: {
      'vencedor': sjVencedorCtrl.text,
      'vencedorCnpj': sjVencedorCnpjCtrl.text,
      'valorVencedor': sjValorVencedorCtrl.text,
      'dataResultado': sjDataResultadoCtrl.text,
      'adjudicacaoData': sjAdjudicacaoDataCtrl.text,
      'adjudicacaoLink': sjAdjudicacaoLinkCtrl.text,
      'homologacaoData': sjHomologacaoDataCtrl.text,
      'homologacaoLink': sjHomologacaoLinkCtrl.text,
      'highlightWinner': highlightWinner,
      'habilitarSomenteVencedor': habilitarSomenteVencedor,
    },
    EditalSections.recursos: {
      'houve': sjRecursosHouveCtrl.text,
      'decisao': sjDecisaoRecursosCtrl.text,
      'links': sjLinksRecursosCtrl.text,
    },
    EditalSections.observacoes: {
      'observacoes': edObservacoesCtrl.text,
    },
  };

  void fromSectionMaps(Map<String, Map<String, dynamic>> s) {
    // 1) DIVULGAÇÃO
    final div = s[EditalSections.divulgacao] ?? const {};
    edNumeroCtrl.text           = div['numero'] ?? '';
    edModalidadeCtrl.text       = div['modalidade'] ?? '';
    edCriterioCtrl.text         = div['criterio'] ?? '';
    edIdPncpCtrl.text           = div['idPncp'] ?? '';
    edLinkPncpCtrl.text         = div['linkPncp'] ?? '';
    edLinkSeiCtrl.text          = div['linkSei'] ?? '';
    edLinksPublicacoesCtrl.text = div['linksPublicacoes'] ?? '';
    edDataPublicacaoCtrl.text   = div['dataPublicacao'] ?? '';
    edPrazoImpugnacaoCtrl.text  = div['prazoImpugnacao'] ?? '';
    edPrazoPropostasCtrl.text   = div['prazoPropostas'] ?? '';
    edObservacoesCtrl.text      = div['observacoes'] ?? '';

    // 2) SESSÃO
    final sess = s[EditalSections.sessao] ?? const {};
    sjDataSessaoCtrl.text       = sess['dataSessao'] ?? '';
    sjHoraSessaoCtrl.text       = sess['horaSessao'] ?? '';
    sjResponsavelCtrl.text      = sess['responsavel'] ?? '';
    sjLocalPlataformaCtrl.text  = sess['localPlataforma'] ?? '';

    // 3) PROPOSTAS
    for (final p in propostas) { p.dispose(); }
    propostas.clear();
    final pro = s[EditalSections.propostas] ?? const {};
    final itemsP = (pro['items'] as List?) ?? const [];
    for (final m in itemsP) {
      final p = PropostaLic(); p.fromMap(Map<String, dynamic>.from(m)); propostas.add(p);
    }

    // 4) LANCES
    for (final l in lances) { l.dispose(); }
    lances.clear();
    final la = s[EditalSections.lances] ?? const {};
    final itemsL = (la['items'] as List?) ?? const [];
    for (final m in itemsL) {
      final l = Lance(); l.fromMap(Map<String, dynamic>.from(m)); lances.add(l);
    }

    // 5) JULGAMENTO
    final jul = s[EditalSections.julgamento] ?? const {};
    sjParecerCtrl.text            = jul['parecer'] ?? '';
    sjCriterioAplicadoCtrl.text   = jul['criterioAplicado'] ?? '';
    sjLinkAtaCtrl.text            = jul['linkAta'] ?? '';
    sjRecursosHouveCtrl.text      = jul['recursosHouve'] ?? '';
    sjDecisaoRecursosCtrl.text    = jul['decisaoRecursos'] ?? '';
    sjLinksRecursosCtrl.text      = jul['linksRecursos'] ?? '';

    // 6) RESULTADO
    final res = s[EditalSections.resultado] ?? const {};
    sjVencedorCtrl.text              = res['vencedor'] ?? '';
    sjVencedorCnpjCtrl.text          = res['vencedorCnpj'] ?? '';
    sjValorVencedorCtrl.text         = res['valorVencedor'] ?? '';
    sjDataResultadoCtrl.text         = res['dataResultado'] ?? '';
    sjAdjudicacaoDataCtrl.text       = res['adjudicacaoData'] ?? '';
    sjAdjudicacaoLinkCtrl.text       = res['adjudicacaoLink'] ?? '';
    sjHomologacaoDataCtrl.text       = res['homologacaoData'] ?? '';
    sjHomologacaoLinkCtrl.text       = res['homologacaoLink'] ?? '';
    highlightWinner                  = (res['highlightWinner'] as bool?) ?? false;
    habilitarSomenteVencedor         = (res['habilitarSomenteVencedor'] as bool?) ?? false;

    // 7) RECURSOS (espelho opcional)
    final rec = s[EditalSections.recursos] ?? const {};
    if ((rec['houve'] ?? '').toString().isNotEmpty) {
      sjRecursosHouveCtrl.text = rec['houve'];
    }
    if ((rec['decisao'] ?? '').toString().isNotEmpty) {
      sjDecisaoRecursosCtrl.text = rec['decisao'];
    }
    if ((rec['links'] ?? '').toString().isNotEmpty) {
      sjLinksRecursosCtrl.text = rec['links'];
    }

    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in [
      edNumeroCtrl, edModalidadeCtrl, edCriterioCtrl, edIdPncpCtrl, edLinkPncpCtrl,
      edLinkSeiCtrl, edLinksPublicacoesCtrl, edDataPublicacaoCtrl, edPrazoImpugnacaoCtrl,
      edPrazoPropostasCtrl, edObservacoesCtrl,
      sjDataSessaoCtrl, sjHoraSessaoCtrl, sjResponsavelCtrl, sjLocalPlataformaCtrl,
      sjParecerCtrl, sjCriterioAplicadoCtrl, sjLinkAtaCtrl, sjRecursosHouveCtrl,
      sjDecisaoRecursosCtrl, sjLinksRecursosCtrl,
      sjVencedorCtrl, sjVencedorCnpjCtrl, sjValorVencedorCtrl, sjDataResultadoCtrl,
      sjAdjudicacaoDataCtrl, sjAdjudicacaoLinkCtrl, sjHomologacaoDataCtrl, sjHomologacaoLinkCtrl,
    ]) { c.dispose(); }
    for (final p in propostas) { p.dispose(); }
    for (final l in lances) { l.dispose(); }
    super.dispose();
  }

  String? quickValidate() {
    if (edNumeroCtrl.text.trim().isEmpty) return 'Informe o número do edital/processo.';
    if (edModalidadeCtrl.text.trim().isEmpty) return 'Selecione a modalidade.';
    if (edCriterioCtrl.text.trim().isEmpty) return 'Selecione o critério de julgamento.';
    return null;
  }
}
