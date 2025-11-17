/// Mapa padrão: chave da etapa -> nome da coleção
class HiringStageKey {
  static const dfd          = 'dfd';
  static const etp          = 'etp';
  static const tr           = 'tr';
  static const cotacao      = 'cotacao';
  static const edital       = 'edital';
  static const habilitacao  = 'habilitacao';
  static const dotacao      = 'dotacao';
  static const minuta       = 'minuta';
  static const parecer     = 'parecer';
  static const publicacao   = 'publicacao';
  static const arquivamento = 'arquivamento';

  /// Ordem de desbloqueio (cada próximo depende do anterior estar concluído)
  static const ordered = <String>[
    dfd,
    etp,
    tr,
    cotacao,
    edital,
    habilitacao,
    dotacao,
    minuta,
    parecer,
    publicacao,
    arquivamento,
  ];
}
