import 'dart:convert';
import 'package:http/http.dart' as http;

import 'ana_hidroweb_service.dart';
import 'ana_station_data.dart';
import 'ana_pluviometric_series_data.dart';

class AnaHidrowebRepository {
  // ---------------------------------------------------------------------------
  // INVENTÁRIO (estações telemétricas por UF)
  // ---------------------------------------------------------------------------
  Future<List<AnaStationData>> getStationsByUf({
    required String uf,
    required String stationType,
  }) async {
    final url = stationType.toUpperCase().startsWith('PLUVI')
        ? AnaHidrowebService.inventoryPluviometric(uf)
        : AnaHidrowebService.inventoryFluviometric(uf);

    final resp = await http.get(Uri.parse(url));

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao buscar inventário ANA: ${resp.statusCode} - ${resp.body}',
      );
    }

    final decoded = jsonDecode(resp.body);

    final List<dynamic> items;
    if (decoded is List) {
      items = decoded;
    } else if (decoded is Map && decoded['items'] is List) {
      items = decoded['items'] as List<dynamic>;
    } else {
      items = const [];
    }

    return items
        .whereType<Map>()
        .map(
          (m) => AnaStationData.fromMap(
        Map<String, dynamic>.from(m),
      ),
    )
        .toList();
  }

  // ---------------------------------------------------------------------------
  // SÉRIE PLUVIOMÉTRICA TELEMÉTRICA (HidroinfoanaSerieTelemetricaAdotada)
  // ---------------------------------------------------------------------------
  ///
  /// Busca dados telemétricos adotados (chuva/cota/vazão) para uma estação
  /// específica, usando a Cloud Function:
  ///   /telemetricStationSeries?codigoEstacao=...&tipoEstacao=PLUVIOMETRICA&daysBack=...
  ///
  /// [daysBack] é limitado pela própria ANA (RangeIntervaloDeBusca: DIAS_2,7,14,21,30).
  Future<List<AnaPluviometricSeriesData>> getTelemetricPluviometricSeries({
    required String codigoEstacao,
    int daysBack = 7,
  }) async {
    final url = AnaHidrowebService.telemetricSeries(
      codigoEstacao: codigoEstacao,
      tipoEstacao: 'PLUVIOMETRICA',
      daysBack: daysBack,
    );

    final resp = await http.get(Uri.parse(url));

    if (resp.statusCode != 200) {
      throw Exception(
        'Erro ao buscar série telemétrica ANA: ${resp.statusCode} - ${resp.body}',
      );
    }

    final decoded = jsonDecode(resp.body);
    final List<dynamic> items = decoded is List ? decoded : const [];

    final list = items
        .whereType<Map>()
        .map(
          (m) => AnaPluviometricSeriesData.fromMap(
        Map<String, dynamic>.from(m),
      ),
    )
        .toList();

    // Ordena por data da medição (crescente)
    list.sort((a, b) {
      final da = a.date;
      final db = b.date;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    return list;
  }
}
