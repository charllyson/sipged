import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class AccidentsData extends ChangeNotifier {
  String? id;
  int? order;
  DateTime? date;
  String? referencePoint;
  int? death;
  String? highway;
  String? description;

  String? location;
  int? scoresVictims;
  String? transportInvolved;
  String? typeOfAccident;

  LatLng? latLng;
  Placemark? placemark;
  String? city;
  String? street;
  String? subLocality;
  String? locality;
  String? administrativeArea;
  String? postalCode;
  String? country;
  String? isoCountryCode;
  String? subAdministrativeArea;
  String? thoroughfare;
  String? subThoroughfare;
  String? nameArea;

  DateTime? createdAt;
  String? createdBy;
  DateTime? updatedAt;
  String? updatedBy;
  DateTime? deletedAt;
  String? deletedBy;

  // ---------- Campos denormalizados p/ performance ----------
  int? year;                 // ano do acidente
  int? month;                // mês do acidente (1..12)
  String? yearDocId;         // id do doc em trafficAccidents correspondente ao ano (opcional)
  String? recordPath;        // path completo do doc em records (ex.: trafficAccidents/XYZ/records/ABC)

  // Chave útil para agrupamento/ordenação local (ex.: "2025-08")
  String? get yearMonthKey => (year != null && month != null)
      ? '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}'
      : null;


  final Map<String, int> cityOfAccident = {};

  String normalizeString(String? nome) {
    if (nome == null) return '';
    final noAccent = removeDiacritics(nome);
    final noMultipleSpace = noAccent.replaceAll(RegExp(r'\s+'), ' ');
    return noMultipleSpace.trim().toUpperCase();
  }

  Future<void> loadAccidentsData(List<AccidentsData> accidentsData) async {
    cityOfAccident.clear();

    for (final acc in accidentsData) {
      final city = normalizeString(acc.city);
      if (city.isEmpty) continue;

      cityOfAccident[city] = (cityOfAccident[city] ?? 0) + 1;
    }
  }

  Map<String, Color> calculateColorsFilteredCity(
      List<AccidentsData> filteredAccidentsData,
      ) {
    final count = <String, int>{};
    for (final accidents in filteredAccidentsData) {
      final city = normalizeString(accidents.city);
      if (city.isEmpty) continue;
      count[city] = (count[city] ?? 0) + 1;
    }
    final max = count.values.fold<int>(1, (a, b) => math.max(a, b));
    return {
      for (final entry in count.entries)
        entry.key: interpolateColorsAccidentsFactor(
          (entry.value / max).clamp(0.05, 1.0),
        ),
    };
  }

  Color interpolateColorsAccidentsFactor(double accidentsFactor) {
    final index = (accidentsFactor *
        (AccidentsData.statusColorsAccidentType.length - 1))
        .floor()
        .clamp(0, AccidentsData.statusColorsAccidentType.length - 2);
    final t =
        accidentsFactor * (AccidentsData.statusColorsAccidentType.length - 1) -
            index;
    return Color.lerp(
      AccidentsData.statusColorsAccidentType[index],
      AccidentsData.statusColorsAccidentType[index + 1],
      t,
    )!;
  }

  static List<String> accidentTypes = [
    'COLISÃO COM ANIMAL',
    'COLISÃO FRONTAL',
    'COLISÃO TRASEIRA',
    'COLISÃO LONGITUDINAL',
    'COLISÃO TRANSVERSAL',
    'COLISÃO COM OBJETO FIXO',
    'COLISÃO COM MOTOCICLETA',
    'CAPOTAMENTO',
    'TOMBAMENTO',
    'ATROPELAMENTO',
    'SAÍDA DE PISTA',
    'ENGAVETAMENTO',
    'QUEDA DE MOTOCICLETA',
    'QUEDA DE CICLISTA',
    'QUEDA',
    'CHOQUE',
    'OUTROS',
  ];

  static List<String> cityState = [
    'ÁGUA BRANCA',
    'ANADIA',
    'ARAPIRACA',
    'ATALAIA',
    'BARRA DE SANTO ANTÔNIO',
    'BARRA DE SÃO MIGUEL',
    'BATALHA',
    'BELÉM',
    'BELO MONTE',
    'BOCA DA MATA',
    'BRANQUINHA',
    'CACIMBINHAS',
    'CAJUEIRO',
    'CAMPESTRE',
    'CAMPO ALEGRE',
    'CANAPI',
    'CAPELA',
    'CARNEIROS',
    'CHÃ PRETA',
    "COITÉ DO NÓIA",
    'COLÔNIA LEOPOLDINA',
    'COQUEIRO SECO',
    'CORURIPE',
    'CRAÍBAS',
    'DELMIRO GOUVEIA',
    'DOIS RIACHOS',
    'ESTRELA DE ALAGOAS',
    'FEIRA GRANDE',
    'FELIZ DESERTO',
    'FLEXEIRAS',
    'GIRAU DO PONCIANO',
    'IBATEGUARA',
    'IGACI',
    'IGREJA NOVA',
    'INHAPI',
    "JACARÉ DOS HOMENS",
    'JACUÍPE',
    'JAPARATINGA',
    'JARAMATAIA',
    'JEQUIÁ DA PRAIA',
    'JOAQUIM GOMES',
    'JUNDIÁ',
    'JUNQUEIRO',
    'LAGOA DA CANOA',
    'LIMOEIRO DE ANADIA',
    'MACEIÓ',
    'MAJOR ISIDORO',
    'MAR VERMELHO',
    'MARAGOGI',
    'MARAVILHA',
    'MARECHAL DEODORO',
    'MARIBONDO',
    'MATA GRANDE',
    'MATRIZ DE CAMARAGIBE',
    'MESSIAS',
    'MINADOR DO NEGRÃO',
    'MONTEIRÓPOLIS',
    'MURICI',
    'NOVO LINO',
    "OLHO D'ÁGUA DAS FLORES",
    "OLHO D'ÁGUA DO CASADO",
    "OLHO D'ÁGUA GRANDE",
    'OLIVENÇA',
    'OURO BRANCO',
    'PALESTINA',
    "PALMEIRA DOS ÍNDIOS",
    'PÃO DE AÇÚCAR',
    'PARICONHA',
    'PARIPUEIRA',
    'PASSO DE CAMARAGIBE',
    'PAULO JACINTO',
    'PENEDO',
    'PIAÇABUÇU',
    'PILAR',
    'PINDOBA',
    'PIRANHAS',
    'POÇO DAS TRINCHEIRAS',
    'PORTO CALVO',
    'PORTO DE PEDRAS',
    'PORTO REAL DO COLÉGIO',
    'QUEBRANGULO',
    'RIO LARGO',
    'ROTEIRO',
    'SANTA LUZIA DO NORTE',
    'SANTANA DO IPANEMA',
    'SANTANA DO MUNDAÚ',
    'SÃO BRÁS',
    'SÃO JOSÉ DA LAJE',
    'SÃO JOSÉ DA TAPERA',
    'SÃO LUÍS DO QUITUNDE',
    'SÃO MIGUEL DOS CAMPOS',
    'SÃO MIGUEL DOS MILAGRES',
    'SÃO SEBASTIÃO',
    'SATUBA',
    'SENADOR RUI PALMEIRA',
    "TANQUE D'ARCA",
    'TAQUARANA',
    'TEOTÔNIO VILELA',
    'TRAIPU',
    'UNIÃO DOS PALMARES',
    'VIÇOSA',
  ];


  static String getTitleByAccidentType(String status) {
    switch (status) {
      case 'COLISÃO COM ANIMAL':
        return 'Colisão com Animal';
      case 'COLISÃO FRONTAL':
        return 'Colisão Frontal';
      case 'COLISÃO TRASEIRA':
        return 'Colisão Traseira';
      case 'COLISÃO LONGITUDINAL':
        return 'Colisão Longitudinal';
      case 'COLISÃO TRANSVERSAL':
        return 'Colisão Transversal';
      case 'COLISÃO COM OBJETO FIXO':
        return 'Colisão com Objeto Fixo';
      case 'COLISÃO COM MOTOCICLETA':
        return 'Colisão com Motocicleta';
      case 'CAPOTAMENTO':
        return 'Capotamento';
      case 'TOMBAMENTO':
        return 'Tombamento';
      case 'ATROPELAMENTO':
        return 'Atropelamento';
      case 'SAÍDA DE PISTA':
        return 'Saída de Pista';
      case 'ENGAVETAMENTO':
        return 'Engavetamento';
      case 'QUEDA DE MOTOCICLETA':
        return 'Queda de Motocicleta';
      case 'QUEDA DE CICLISTA':
        return 'Queda de Ciclista';
      case 'QUEDA':
        return 'Queda';
      case 'CHOQUE':
        return 'Choque';
      default:
        return 'OUTROS';
    }
  }

  static IconData iconAccidentType(String status) {
    switch (status) {
      case 'COLISÃO COM ANIMAL':
        return Icons.pets;
      case 'COLISÃO FRONTAL':
        return Icons.car_crash;
      case 'COLISÃO TRASEIRA':
        return Icons.car_crash;
      case 'COLISÃO LONGITUDINAL':
        return Icons.car_crash;
      case 'COLISÃO TRANSVERSAL':
        return Icons.car_crash;
      case 'COLISÃO COM OBJETO FIXO':
        return Icons.minor_crash;
      case 'COLISÃO COM MOTOCICLETA':
        return Icons.motorcycle;
      case 'CAPOTAMENTO':
        return Icons.minor_crash;
      case 'TOMBAMENTO':
        return Icons.minor_crash;
      case 'ATROPELAMENTO':
        return Icons.directions_walk;
      case 'SAÍDA DE PISTA':
        return Icons.highlight;
      case 'ENGAVETAMENTO':
        return Icons.minor_crash;
      case 'QUEDA DE MOTOCICLETA':
        return Icons.motorcycle_outlined;
      case 'QUEDA DE CICLISTA':
        return Icons.bike_scooter;
      case 'QUEDA':
        return Icons.directions_walk;
      case 'CHOQUE':
        return Icons.directions_walk;
      default:
        return Icons.not_listed_location;
    }
  }

  static Color getColorByAccidentType(String status) {
    switch (status) {
      case 'COLISÃO COM ANIMAL':
        return Colors.yellow.shade700;
      case 'COLISÃO FRONTAL':
        return Colors.blue.shade300;
      case 'COLISÃO TRASEIRA':
        return Colors.green;
      case 'COLISÃO LONGITUDINAL':
        return Colors.orange.shade700;
      case 'COLISÃO TRANSVERSAL':
        return Colors.red.shade700;
      case 'COLISÃO COM OBJETO FIXO':
        return Colors.grey;
      case 'COLISÃO COM MOTOCICLETA':
        return Colors.yellow.shade700;
      case 'CAPOTAMENTO':
        return Colors.blue.shade300;
      case 'TOMBAMENTO':
        return Colors.green;
      case 'ATROPELAMENTO':
        return Colors.orange.shade700;
      case 'SAÍDA DE PISTA':
        return Colors.red.shade700;
      case 'ENGAVETAMENTO':
        return Colors.grey;
      case 'QUEDA DE MOTOCICLETA':
        return Colors.yellow.shade700;
      case 'QUEDA DE CICLISTA':
        return Colors.blue.shade300;
      case 'QUEDA':
        return Colors.green;
      case 'CHOQUE':
        return Colors.orange.shade700;
      default:
        return Colors.black;
    }
  }


  static List<Color> specificColorsAccidentType = [
    Colors.yellow.shade300,
    Colors.yellow.shade700,
    Colors.orange.shade400,
    Colors.orange.shade600,
    Colors.deepOrange.shade400,
    Colors.deepOrange.shade600,
    Colors.red.shade600,
    Colors.red.shade900,
  ];

  static List<Color> statusColorsAccidentType = [
    Colors.yellow.shade700,
    Colors.blue.shade300,
    Colors.green,
    Colors.orange.shade700,
    Colors.red.shade700,
    Colors.grey,
  ];

  static String normalizarTipoAcidente(String tipo) {
    tipo = tipo.toUpperCase().trim();
    if (tipo.contains('COLISÃO COM ANIMAL')) return 'COLISÃO COM ANIMAL';
    if (tipo.contains('COLISÃO FRONTAL')) return 'COLISÃO FRONTAL';
    if (tipo.contains('COLISÃO TRASEIRA')) return 'COLISÃO TRASEIRA';
    if (tipo.contains('COLISÃO LONGITUDINAL')) return 'COLISÃO LONGITUDINAL';
    if (tipo.contains('COLISÃO TRANSVERSAL')) return 'COLISÃO TRANSVERSAL';
    if (tipo.contains('COLISÃO COM OBJETO FIXO')) return 'COLISÃO OBJETO FIXO';
    if (tipo.contains('COLISÃO COM MOTOCICLETA') || tipo.contains('MOTO')) return 'COLISÃO COM MOTO';
    if (tipo.contains('CAPOTAMENTO')) return 'CAPOTAMENTO';
    if (tipo.contains('TOMBAMENTO')) return 'TOMBAMENTO';
    if (tipo.contains('ATROPELAMENTO')) return 'ATROPELAMENTO';
    if (tipo.contains('SAÍDA DE PISTA')) return 'SAÍDA DE PISTA';
    if (tipo.contains('ENGAVETAMENTO')) return 'ENGAVETAMENTO';
    if (tipo.contains('QUEDA DE MOTOCICLETA')) return 'QUEDA DE MOTO';
    if (tipo.contains('QUEDA DE CICLISTA')) return 'QUEDA DE CICLISTA';
    if (tipo.contains('QUEDA')) return 'QUEDA';
    if (tipo.contains('CHOQUE')) return 'CHOQUE';
    if (tipo.contains('OUTROS')) return 'OUTROS';
    return tipo;
  }

  AccidentsData({
    this.id,
    this.order,
    this.date,
    this.death,
    this.highway,
    this.location,
    this.scoresVictims,
    this.transportInvolved,
    this.typeOfAccident,

    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,

    this.latLng,
    this.placemark,
    this.city,
    this.street,
    this.subLocality,
    this.locality,
    this.administrativeArea,
    this.postalCode,
    this.country,
    this.isoCountryCode,
    this.subAdministrativeArea,
    this.thoroughfare,
    this.subThoroughfare,
    this.nameArea,

    this.referencePoint,

    // novos
    this.year,
    this.month,
    this.yearDocId,
    this.recordPath,
  });

  factory AccidentsData.fromDocument({required DocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;

    // Converte date
    final DateTime? dt = (data['date'] is Timestamp)
        ? (data['date'] as Timestamp).toDate()
        : parseDate(data['date']);

    // Lê year/month do banco, se não houver, calcula da date (melhor que nada)
    final int? yr = (data['year'] is int) ? data['year'] as int : dt?.toLocal().year;
    final int? mo = (data['month'] is int) ? data['month'] as int : dt?.toLocal().month;

    return AccidentsData(
      id: snapshot.id,
      city: data['city'],
      date: dt,
      death: data['death'],
      highway: data['highway'],
      location: data['location'],
      referencePoint: data['referencePoint'],
      scoresVictims: data['scoresVictims'],
      transportInvolved: data['transportInvolved'],
      typeOfAccident: data['typeOfAccident'] ?? '',
      order: data['order'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['createdAt'] ?? ''),
      createdBy: data['createdBy'],
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['updatedAt'] ?? ''),
      updatedBy: data['updatedBy'],
      deletedAt: data['deletedAt'] is Timestamp
          ? (data['deletedAt'] as Timestamp).toDate()
          : DateTime.tryParse(data['deletedAt'] ?? ''),
      deletedBy: data['deletedBy'],
      latLng: data['latLng'] != null
          ? LatLng(data['latLng']['latitude'], data['latLng']['longitude'])
          : null,
      street: data['street'],
      subLocality: data['subLocality'],
      locality: data['locality'],
      administrativeArea: data['administrativeArea'],
      postalCode: data['postalCode'],
      country: data['country'],
      isoCountryCode: data['isoCountryCode'],
      subAdministrativeArea: data['subAdministrativeArea'],
      thoroughfare: data['thoroughfare'],
      subThoroughfare: data['subThoroughfare'],
      nameArea: data['nameArea'],

      // novos
      year: yr,
      month: mo,
      yearDocId: data['yearDocId'],
      recordPath: data['recordPath'] ?? snapshot.reference.path, // fallback: path atual
    );
  }

  List<AccidentsData> converterParaAcidentes(List<Map<String, dynamic>> dados) {
    // ... (mantido, pode adicionar year/month se vierem no mapa)
    return dados.map((mapa) {
      return AccidentsData(
        id: mapa['id'],
        city: mapa['city'],
        date: AccidentsData.parseDate(mapa['date']),
        death: mapa['death'],
        highway: mapa['highway'],
        location: mapa['location'],
        referencePoint: mapa['referencePoint'],
        scoresVictims: mapa['scoresVictims'],
        transportInvolved: mapa['transportInvolved'],
        typeOfAccident: mapa['typeOfAccident'],
        order: mapa['order'],
        createdAt: AccidentsData.parseDate(mapa['createdAt']),
        createdBy: mapa['createdBy'],
        updatedAt: AccidentsData.parseDate(mapa['updatedAt']),
        updatedBy: mapa['updatedBy'],
        deletedAt: AccidentsData.parseDate(mapa['deletedAt']),
        deletedBy: mapa['deletedBy'],
        latLng: mapa['latLng'] != null
            ? LatLng(mapa['latLng']['latitude'], mapa['latLng']['longitude'])
            : null,
        street: mapa['street'],
        subLocality: mapa['subLocality'],
        locality: mapa['locality'],
        administrativeArea: mapa['administrativeArea'],
        postalCode: mapa['postalCode'],
        country: mapa['country'],
        isoCountryCode: mapa['isoCountryCode'],
        subAdministrativeArea: mapa['subAdministrativeArea'],
        thoroughfare: mapa['thoroughfare'],
        subThoroughfare: mapa['subThoroughfare'],
        nameArea: mapa['nameArea'],

        year: mapa['year'],
        month: mapa['month'],
        yearDocId: mapa['yearDocId'],
        recordPath: mapa['recordPath'],
      );
    }).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id ?? '',
      'city': city ?? '',
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'death': death ?? 0, // 🔧 melhor manter número
      'highway': highway ?? '',
      'location': location ?? '',
      'scoresVictims': scoresVictims ?? 0,
      'transportInvolved': transportInvolved ?? '',
      'typeOfAccident': typeOfAccident ?? '',
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy ?? '',
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy ?? '',
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy ?? '',
      'order': order ?? 0,
      'latLng': latLng != null
          ? {'latitude': latLng!.latitude, 'longitude': latLng!.longitude}
          : null,
      'street': street ?? '',
      'subLocality': subLocality ?? '',
      'locality': locality ?? '',
      'administrativeArea': administrativeArea ?? '',
      'postalCode': postalCode ?? '',
      'country': country ?? '',
      'isoCountryCode': isoCountryCode ?? '',
      'subAdministrativeArea': subAdministrativeArea ?? '',
      'thoroughfare': thoroughfare ?? '',
      'subThoroughfare': subThoroughfare ?? '',
      'nameArea': nameArea ?? '',

      // novos
      'year': year ?? date?.toLocal().year,          // garante preenchido
      'month': month ?? date?.toLocal().month,       // garante preenchido
      'yearDocId': yearDocId,
      'recordPath': recordPath,
      'yearMonthKey': yearMonthKey,                  // ex.: "2025-08"
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'city': city,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'death': death,
      'highway': highway,
      'location': location,
      'scoresVictims': scoresVictims,
      'transportInvolved': transportInvolved,
      'typeOfAccident': typeOfAccident,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,
      'order': order,
      'latLng': latLng != null
          ? {'latitude': latLng!.latitude, 'longitude': latLng!.longitude}
          : null,
      'street': street,
      'subLocality': subLocality,
      'locality': locality,
      'administrativeArea': administrativeArea,
      'postalCode': postalCode,
      'country': country,
      'isoCountryCode': isoCountryCode,
      'subAdministrativeArea': subAdministrativeArea,
      'thoroughfare': thoroughfare,
      'subThoroughfare': subThoroughfare,
      'nameArea': nameArea,

      // novos
      'year': year ?? date?.toLocal().year,
      'month': month ?? date?.toLocal().month,
      'yearDocId': yearDocId,
      'recordPath': recordPath,
      'yearMonthKey': yearMonthKey,
    };
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.tryParse(value) ?? _stringToDate(value);
      } catch (_) {
        return _stringToDate(value);
      }
    }
    return null;
  }

  static DateTime? _stringToDate(String input) {
    final parts = input.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      if (day != null && month != null && year != null) {
        return DateTime(year, month, day);
      }
    }
    return null;
  }
}
