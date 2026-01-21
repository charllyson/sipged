/// Chaves estáveis (Firestore) das seções da Cotação.
/// Devem bater 1:1 com o que o CotacaoController.toSectionMaps()/fromSectionMaps() usa
/// e com as seções exibidas na UI.
class CotacaoSections {
  static const metadados            = 'metadados';
  static const objetoItens          = 'objetoItens';
  static const conviteDivulgacao    = 'conviteDivulgacao';
  static const respostasFornecedores= 'respostasFornecedores';
  static const vencedora            = 'vencedora';
  static const consolidacaoResultado= 'consolidacaoResultado';
  static const anexosEvidencias     = 'anexosEvidencias';

  /// Ordem canônica das seções
  static const all = <String>[
    metadados,
    objetoItens,
    conviteDivulgacao,
    respostasFornecedores,
    vencedora,
    consolidacaoResultado,
    anexosEvidencias,
  ];
}
