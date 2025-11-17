// lib/_blocs/process/hiring/5Edital/edital_sections.dart

/// Chaves estáveis para as seções do Edital (subcoleções do doc raiz)
class EditalSections {
  static const divulgacao   = 'divulgacao';   // publicação, PNCP, prazos
  static const sessao       = 'sessao';       // abertura / sessão
  static const propostas    = 'propostas';    // propostas recebidas (lista)
  static const lances       = 'lances';       // lances/negociação (lista)
  static const julgamento   = 'julgamento';   // parecer/critério aplicado/links
  static const resultado    = 'resultado';    // vencedor/adjudicação/homologação
  static const recursos     = 'recursos';     // houve recursos? decisão, links
  static const observacoes  = 'observacoes';  // observações gerais
  static const documentos   = 'documentos';   // anexos/links extras (opcional)

  static const all = <String>[
    divulgacao,
    sessao,
    propostas,
    lances,
    julgamento,
    resultado,
    recursos,
    observacoes,
    documentos,
  ];
}
