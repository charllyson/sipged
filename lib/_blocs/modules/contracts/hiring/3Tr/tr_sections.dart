/// Chaves estáveis (Firestore) das seções do TR.
/// Devem bater 1:1 com o que o TrController.toSectionMaps()/fromSectionMaps() usa
/// e com as seções renderizadas na UI.
class TrSections {
  static const objetoFundamentacao = 'objetoFundamentacao';
  static const escopoRequisitos = 'escopoRequisitos';
  static const localPrazosCronograma = 'localPrazosCronograma';
  static const medicaoAceiteIndicadores = 'medicaoAceiteIndicadores';
  static const obrigacoesEquipeGestao = 'obrigacoesEquipeGestao';
  static const licenciamentoSegurancaSustentabilidade = 'licenciamentoSegurancaSustentabilidade';
  static const precosPagamentoReajuste = 'precosPagamentoReajuste';
  static const riscosPenalidadesCondicoes = 'riscosPenalidadesCondicoes';
  static const documentosReferencias = 'documentosReferencias';

  /// Ordem canônica das seções
  static const all = <String>[
    objetoFundamentacao,
    escopoRequisitos,
    localPrazosCronograma,
    medicaoAceiteIndicadores,
    obrigacoesEquipeGestao,
    licenciamentoSegurancaSustentabilidade,
    precosPagamentoReajuste,
    riscosPenalidadesCondicoes,
    documentosReferencias,
  ];
}
