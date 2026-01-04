import 'package:intl/intl.dart';

class AnaPluviometricSeriesData {
  /// Data/hora da medição (campo Data_Hora_Medicao da ANA).
  final DateTime? date;

  /// Mapa completo retornado pela API (telemetria adotada).
  final Map<String, dynamic> raw;

  AnaPluviometricSeriesData({
    required this.date,
    required this.raw,
  });

  factory AnaPluviometricSeriesData.fromMap(Map<String, dynamic> map) {
    // Tenta primeiro Data_Hora_Medicao (telemétrica), depois Data_Hora_Dado
    final rawDataHora = map['Data_Hora_Medicao'] ?? map['Data_Hora_Dado'];
    return AnaPluviometricSeriesData(
      date: _parseDataHora(rawDataHora),
      raw: map,
    );
  }

  static DateTime? _parseDataHora(dynamic raw) {
    if (raw == null) return null;
    final s = raw.toString().trim();
    if (s.isEmpty) return null;

    // 1) Tenta ISO direto (2024-01-01 23:00:00.0 ou 2024-01-01T23:00:00)
    try {
      // Substitui espaço por 'T' se necessário
      final normalized = s.contains(' ') && !s.contains('T')
          ? s.replaceFirst(' ', 'T')
          : s;
      return DateTime.parse(normalized);
    } catch (_) {}

    // 2) dd/MM/yyyy ou dd/MM/yyyy HH:mm
    try {
      if (s.length <= 10) {
        return DateFormat('dd/MM/yyyy').parse(s);
      } else {
        return DateFormat('dd/MM/yyyy HH:mm').parse(s);
      }
    } catch (_) {}

    return null;
  }

  String get dataHoraLabel =>
      raw['Data_Hora_Medicao']?.toString() ??
          raw['Data_Hora_Dado']?.toString() ??
          '';

  // Helpers opcionais – podem ser úteis na UI
  String get chuvaAdotada =>
      raw['Chuva_Adotada']?.toString() ?? '';

  String get chuvaStatus =>
      raw['Chuva_Adotada_Status']?.toString() ?? '';

  String get cotaAdotada =>
      raw['Cota_Adotada']?.toString() ?? '';

  String get cotaStatus =>
      raw['Cota_Adotada_Status']?.toString() ?? '';

  String get vazaoAdotada =>
      raw['Vazao_Adotada']?.toString() ?? '';

  String get vazaoStatus =>
      raw['Vazao_Adotada_Status']?.toString() ?? '';
}
