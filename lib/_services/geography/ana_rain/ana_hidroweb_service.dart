class AnaHidrowebService {
  static const String _cloudBase =
      'https://us-central1-sisgeoderal.cloudfunctions.net';

  // Inventário (estações telemétricas por UF)
  static String inventoryPluviometric(String uf) =>
      '$_cloudBase/telemetricPluviometricStations?uf=$uf';

  static String inventoryFluviometric(String uf) =>
      '$_cloudBase/telemetricFluviometricStations?uf=$uf';

  // Série telemétrica (quase tempo real) – nossa Function:
  // /telemetricStationSeries?codigoEstacao=...&tipoEstacao=PLUVIOMETRICA&daysBack=...
  static String telemetricSeries({
    required String codigoEstacao,
    required String tipoEstacao,
    required int daysBack,
  }) =>
      '$_cloudBase/telemetricStationSeries'
          '?codigoEstacao=$codigoEstacao'
          '&tipoEstacao=$tipoEstacao'
          '&daysBack=$daysBack';

  // Série pluviométrica histórica (HidroSerieChuva/v1 via nossa Function)
  // -> deixei aqui, caso queira usar no futuro para séries convencionais.
  static String historicPluviometricSeries({
    required String codigoEstacao,
    required String dataInicial,
    required String dataFinal,
  }) =>
      '$_cloudBase/pluviometricStationSeries'
          '?codigoEstacao=$codigoEstacao'
          '&dataInicial=$dataInicial'
          '&dataFinal=$dataFinal';
}
