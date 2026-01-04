class AnaStationData {
  final String nome;
  final String municipio;
  final String tipoEstacao;
  final String codigoEstacao;
  final String latitude;
  final String longitude;
  final String altitude;
  final String baciaNome;
  final String areaDrenagem;
  final String codigoBacia;
  final String operandoRaw;
  final String uf;

  AnaStationData({
    required this.nome,
    required this.municipio,
    required this.tipoEstacao,
    required this.codigoEstacao,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.baciaNome,
    required this.areaDrenagem,
    required this.codigoBacia,
    required this.operandoRaw,
    required this.uf,
  });

  factory AnaStationData.fromMap(Map<String, dynamic> map) {
    return AnaStationData(
      nome: map['Estacao_Nome']?.toString() ?? '',
      municipio: map['Municipio_Nome']?.toString() ?? '',
      tipoEstacao: map['Tipo_Estacao']?.toString() ?? '',
      codigoEstacao: map['codigoestacao']?.toString() ?? '',
      latitude: map['Latitude']?.toString() ?? '',
      longitude: map['Longitude']?.toString() ?? '',
      altitude: map['Altitude']?.toString() ?? '',
      baciaNome: map['Bacia_Nome']?.toString() ?? '',
      areaDrenagem: map['Area_Drenagem']?.toString() ?? '',
      codigoBacia: map['codigobacia']?.toString() ?? '',
      operandoRaw: map['Operando']?.toString() ?? '',
      uf: map['UF_Estacao']?.toString() ?? '',
    );
  }

  bool get operando => operandoRaw.trim() == '1';

  String get operandoLabel {
    if (operandoRaw.trim() == '1') return 'SIM';
    if (operandoRaw.trim() == '0') return 'NÃO';
    return operandoRaw;
  }
}
