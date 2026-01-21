/// Chaves estáveis (Firestore) das seções do ETP.
/// Devem bater 1:1 com o que o EtpController.toSectionMaps()/fromSectionMaps() usa
/// e com as seções renderizadas na UI.
class EtpSections {
  static const identificacao = 'identificacao';
  static const motivacao     = 'motivacao';
  static const alternativas  = 'alternativas';
  static const mercado       = 'mercado';
  static const cronograma    = 'cronograma';
  static const premissas     = 'premissas';
  static const documentos    = 'documentos';
  static const conclusao     = 'conclusao';

  /// Ordem canônica das seções para criação dos docs e leitura
  static const all = <String>[
    identificacao,
    motivacao,
    alternativas,
    mercado,
    cronograma,
    premissas,
    documentos,
    conclusao,
  ];
}
