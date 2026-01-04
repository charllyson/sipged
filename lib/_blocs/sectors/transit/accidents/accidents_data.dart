import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

double? _parseIntToDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  final normalized = s.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(normalized);
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  final normalized = s.replaceAll(RegExp(r'[^0-9-]'), '');
  return int.tryParse(normalized);
}

LatLng? _parseLatLng(dynamic value) {
  if (value == null) return null;

  if (value is GeoPoint) {
    return LatLng(value.latitude, value.longitude);
  }

  if (value is Map) {
    final la = value['latitude'] ?? value['lat'];
    final lo = value['longitude'] ?? value['lng'];
    if (la is num && lo is num) {
      return LatLng(la.toDouble(), lo.toDouble());
    }
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.tryParse(value) ?? _stringToDate(value);
    } catch (_) {
      return _stringToDate(value);
    }
  }
  return null;
}

DateTime? _stringToDate(String input) {
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

class AccidentsData extends Equatable {
  // Metadados
  final String? id;
  final int? order;
  final String? recordPath;

  // Dados principais
  final DateTime? date;
  final String? referencePoint; // 📍
  final int? death;
  final String? highway;
  final String? description;

  final String? location;
  final int? scoresVictims;
  final String? transportInvolved;
  final String? typeOfAccident;

  // NOVOS CAMPOS
  final String? victimSex; // ⚥
  final int? victimAge; // 🎂

  // Localização detalhada
  final LatLng? latLng;
  final Placemark? placemark; // não mapeado no Firestore (runtime only)
  final String? city;
  final String? street;
  final String? subLocality;
  final String? locality;
  final String? administrativeArea;
  final String? postalCode;
  final String? country;
  final String? isoCountryCode;
  final String? subAdministrativeArea;
  final String? thoroughfare;
  final String? subThoroughfare;
  final String? nameArea;

  // Auditoria
  final DateTime? createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final String? updatedBy;
  final DateTime? deletedAt;
  final String? deletedBy;

  // Denormalizações
  final int? year;
  final int? month;
  final String? yearDocId;
  final String? cityNormalized;

  String? get yearMonthKey => (year != null && month != null)
      ? '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}'
      : null;

  const AccidentsData({
    this.id,
    this.order,
    this.recordPath,
    this.date,
    this.referencePoint,
    this.death,
    this.highway,
    this.description,
    this.location,
    this.scoresVictims,
    this.transportInvolved,
    this.typeOfAccident,
    this.victimSex,
    this.victimAge,
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
    this.createdAt,
    this.createdBy,
    this.updatedAt,
    this.updatedBy,
    this.deletedAt,
    this.deletedBy,
    this.year,
    this.month,
    this.yearDocId,
    this.cityNormalized,
  });

  /// Construtor vazio, útil pra inicializar formulário
  const AccidentsData.empty()
      : id = null,
        order = null,
        recordPath = null,
        date = null,
        referencePoint = '',
        death = null,
        highway = '',
        description = '',
        location = '',
        scoresVictims = null,
        transportInvolved = '',
        typeOfAccident = '',
        victimSex = null,
        victimAge = null,
        latLng = null,
        placemark = null,
        city = '',
        street = '',
        subLocality = '',
        locality = '',
        administrativeArea = '',
        postalCode = '',
        country = '',
        isoCountryCode = '',
        subAdministrativeArea = '',
        thoroughfare = '',
        subThoroughfare = '',
        nameArea = '',
        createdAt = null,
        createdBy = null,
        updatedAt = null,
        updatedBy = null,
        deletedAt = null,
        deletedBy = null,
        year = null,
        month = null,
        yearDocId = null,
        cityNormalized = null;

  // ---------------------------------------------------------------------------
  // Helpers de string / tipo / ícones / cores
  // ---------------------------------------------------------------------------

  static String normalizeString(String? nome) {
    if (nome == null) return '';
    final noAccent = removeDiacritics(nome);
    final noMultipleSpace = noAccent.replaceAll(RegExp(r'\s+'), ' ');
    return noMultipleSpace.trim().toUpperCase();
  }

  static String canonicalType(String? raw) {
    if (raw == null) return 'OUTROS';
    final t = raw.toUpperCase().trim();
    if (t.contains('ANIMAL')) return 'COLISÃO COM ANIMAL';
    if (t.contains('FRONTAL')) return 'COLISÃO FRONTAL';
    if (t.contains('TRASEIRA')) return 'COLISÃO TRASEIRA';
    if (t.contains('LONGITUDINAL')) return 'COLISÃO LONGITUDINAL';
    if (t.contains('TRANSVERSAL')) return 'COLISÃO TRANSVERSAL';
    if (t.contains('OBJETO FIXO')) return 'COLISÃO COM OBJETO FIXO';
    if (t.contains('MOTOCICLETA') || t.contains('MOTO')) {
      return 'COLISÃO COM MOTOCICLETA';
    }
    if (t.contains('CAPOTAMENTO')) return 'CAPOTAMENTO';
    if (t.contains('TOMBAMENTO')) return 'TOMBAMENTO';
    if (t.contains('ATROPELAMENTO')) return 'ATROPELAMENTO';
    if (t.contains('SAÍDA DE PISTA')) return 'SAÍDA DE PISTA';
    if (t.contains('ENGAVETAMENTO')) return 'ENGAVETAMENTO';
    if (t.contains('QUEDA DE CICLISTA')) return 'QUEDA DE CICLISTA';
    if (t.contains('QUEDA')) return 'QUEDA';
    if (t.contains('CHOQUE')) return 'CHOQUE';
    return 'OUTROS';
  }

  static String displayTitle(String canonical) =>
      getTitleByAccidentType(canonical);

  static IconData iconFor(String canonical) => iconAccidentType(canonical);

  /// Conta acidentes por cidade (normalizada)
  static Map<String, int> countByCity(List<AccidentsData> accidentsData) {
    final cityOfAccident = <String, int>{};
    for (final acc in accidentsData) {
      final cityKey = normalizeString(acc.city);
      if (cityKey.isEmpty) continue;
      cityOfAccident[cityKey] = (cityOfAccident[cityKey] ?? 0) + 1;
    }
    return cityOfAccident;
  }

  /// Gera mapa de cidade → cor, baseado na intensidade relativa
  static Map<String, Color> calculateColorsFilteredCity(
      List<AccidentsData> filteredAccidentsData,
      ) {
    final count = countByCity(filteredAccidentsData);
    if (count.isEmpty) return {};

    final max = count.values.fold<int>(1, (a, b) => math.max(a, b));
    return {
      for (final entry in count.entries)
        entry.key: interpolateColorsAccidentsFactor(
          (entry.value / max).clamp(0.05, 1.0),
        ),
    };
  }

  static Color interpolateColorsAccidentsFactor(double accidentsFactor) {
    final list = AccidentsData.statusColorsAccidentType;
    if (list.length < 2) return Colors.grey;

    final scaled = accidentsFactor * (list.length - 1);
    final index =
    scaled.floor().clamp(0, list.length - 2); // index base
    final t = scaled - index; // fração entre index e index+1

    return Color.lerp(
      list[index],
      list[index + 1],
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

  static const List<String> sexOptions = [
    'MASCULINO',
    'FEMININO',
    'IGNORADO',
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
      case 'COLISÃO TRASEIRA':
      case 'COLISÃO LONGITUDINAL':
      case 'COLISÃO TRANSVERSAL':
        return Icons.car_crash;
      case 'COLISÃO COM OBJETO FIXO':
        return Icons.minor_crash;
      case 'COLISÃO COM MOTOCICLETA':
      case 'QUEDA DE MOTOCICLETA':
        return Icons.motorcycle;
      case 'CAPOTAMENTO':
      case 'TOMBAMENTO':
      case 'ENGAVETAMENTO':
        return Icons.minor_crash;
      case 'ATROPELAMENTO':
      case 'QUEDA':
        return Icons.directions_walk;
      case 'SAÍDA DE PISTA':
        return Icons.highlight;
      case 'QUEDA DE CICLISTA':
        return Icons.bike_scooter;
      case 'CHOQUE':
        return Icons.warning;
      default:
        return Icons.not_listed_location;
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

  // ---------------------------------------------------------------------------
  // Firestore — Map "flat" (padrão DfdData)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> toMap() {
    final y = year ?? date?.toLocal().year;
    final m = month ?? date?.toLocal().month;
    final cityNorm =
        cityNormalized ?? (city != null ? normalizeString(city) : null);

    return {
      // Metadados
      'id': id,
      'order': order,
      'recordPath': recordPath,

      // Dados principais
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'referencePoint': referencePoint,
      'death': death,
      'highway': highway,
      'description': description,
      'location': location,
      'scoresVictims': scoresVictims,
      'transportInvolved': transportInvolved,
      'typeOfAccident': typeOfAccident,

      // Vítima
      'victimSex': victimSex,
      'victimAge': victimAge,

      // Localização detalhada
      'latLng': latLng != null
          ? {
        'latitude': latLng!.latitude,
        'longitude': latLng!.longitude,
      }
          : null,
      'city': city,
      'cityNormalized': cityNorm,
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

      // Auditoria
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy,

      // Denormalizações
      'year': y,
      'month': m,
      'yearDocId': yearDocId,
      'yearMonthKey': (y != null && m != null)
          ? '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}'
          : null,
    };
  }

  /// Alias compatível com o código antigo
  Map<String, dynamic> toFirestore() => toMap();

  factory AccidentsData.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const AccidentsData.empty();

    final dt = _parseDate(map['date']);
    final yr = (map['year'] is int) ? map['year'] as int : dt?.toLocal().year;
    final mo =
    (map['month'] is int) ? map['month'] as int : dt?.toLocal().month;

    final latLng = _parseLatLng(map['latLng']);

    final city = map['city']?.toString();
    final cityNormRaw = map['cityNormalized']?.toString();
    final cityNorm =
    cityNormRaw?.isNotEmpty == true ? cityNormRaw : (city != null ? normalizeString(city) : null);

    return AccidentsData(
      id: map['id']?.toString(),
      order: _parseInt(map['order']),
      recordPath: map['recordPath']?.toString(),
      date: dt,
      referencePoint: map['referencePoint']?.toString(),
      death: _parseInt(map['death']),
      highway: map['highway']?.toString(),
      description: map['description']?.toString(),
      location: map['location']?.toString(),
      scoresVictims: _parseInt(map['scoresVictims']),
      transportInvolved: map['transportInvolved']?.toString(),
      typeOfAccident: map['typeOfAccident']?.toString(),
      victimSex: map['victimSex']?.toString(),
      victimAge: _parseInt(map['victimAge']),
      latLng: latLng,
      // placemark não vem do Firestore
      city: city,
      street: map['street']?.toString(),
      subLocality: map['subLocality']?.toString(),
      locality: map['locality']?.toString(),
      administrativeArea: map['administrativeArea']?.toString(),
      postalCode: map['postalCode']?.toString(),
      country: map['country']?.toString(),
      isoCountryCode: map['isoCountryCode']?.toString(),
      subAdministrativeArea: map['subAdministrativeArea']?.toString(),
      thoroughfare: map['thoroughfare']?.toString(),
      subThoroughfare: map['subThoroughfare']?.toString(),
      nameArea: map['nameArea']?.toString(),
      createdAt: _parseDate(map['createdAt']),
      createdBy: map['createdBy']?.toString(),
      updatedAt: _parseDate(map['updatedAt']),
      updatedBy: map['updatedBy']?.toString(),
      deletedAt: _parseDate(map['deletedAt']),
      deletedBy: map['deletedBy']?.toString(),
      year: yr,
      month: mo,
      yearDocId: map['yearDocId']?.toString(),
      cityNormalized: cityNorm,
    );
  }

  /// Conveniência para DocumentSnapshot (mantendo o mesmo padrão de DfdData)
  factory AccidentsData.fromDocument(DocumentSnapshot snapshot) {
    final raw = snapshot.data() as Map<String, dynamic>?;
    final map = <String, dynamic>{
      if (raw != null) ...raw,
      'id': snapshot.id,
      'recordPath': snapshot.reference.path,
    };
    return AccidentsData.fromMap(map);
  }

  /// Converte lista de mapas em lista de AccidentsData
  static List<AccidentsData> fromListOfMaps(
      List<Map<String, dynamic>> dados,
      ) {
    return dados.map(AccidentsData.fromMap).toList();
  }

  // ---------------------------------------------------------------------------
  // copyWith (padrão DfdData)
  // ---------------------------------------------------------------------------

  AccidentsData copyWith({
    String? id,
    int? order,
    String? recordPath,
    DateTime? date,
    String? referencePoint,
    int? death,
    String? highway,
    String? description,
    String? location,
    int? scoresVictims,
    String? transportInvolved,
    String? typeOfAccident,
    String? victimSex,
    int? victimAge,
    LatLng? latLng,
    Placemark? placemark,
    String? city,
    String? street,
    String? subLocality,
    String? locality,
    String? administrativeArea,
    String? postalCode,
    String? country,
    String? isoCountryCode,
    String? subAdministrativeArea,
    String? thoroughfare,
    String? subThoroughfare,
    String? nameArea,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    String? updatedBy,
    DateTime? deletedAt,
    String? deletedBy,
    int? year,
    int? month,
    String? yearDocId,
    String? cityNormalized,
  }) {
    return AccidentsData(
      id: id ?? this.id,
      order: order ?? this.order,
      recordPath: recordPath ?? this.recordPath,
      date: date ?? this.date,
      referencePoint: referencePoint ?? this.referencePoint,
      death: death ?? this.death,
      highway: highway ?? this.highway,
      description: description ?? this.description,
      location: location ?? this.location,
      scoresVictims: scoresVictims ?? this.scoresVictims,
      transportInvolved: transportInvolved ?? this.transportInvolved,
      typeOfAccident: typeOfAccident ?? this.typeOfAccident,
      victimSex: victimSex ?? this.victimSex,
      victimAge: victimAge ?? this.victimAge,
      latLng: latLng ?? this.latLng,
      placemark: placemark ?? this.placemark,
      city: city ?? this.city,
      street: street ?? this.street,
      subLocality: subLocality ?? this.subLocality,
      locality: locality ?? this.locality,
      administrativeArea: administrativeArea ?? this.administrativeArea,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      isoCountryCode: isoCountryCode ?? this.isoCountryCode,
      subAdministrativeArea:
      subAdministrativeArea ?? this.subAdministrativeArea,
      thoroughfare: thoroughfare ?? this.thoroughfare,
      subThoroughfare: subThoroughfare ?? this.subThoroughfare,
      nameArea: nameArea ?? this.nameArea,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      deletedBy: deletedBy ?? this.deletedBy,
      year: year ?? this.year,
      month: month ?? this.month,
      yearDocId: yearDocId ?? this.yearDocId,
      cityNormalized: cityNormalized ?? this.cityNormalized,
    );
  }

  @override
  List<Object?> get props => [
    id,
    order,
    recordPath,
    date,
    referencePoint,
    death,
    highway,
    description,
    location,
    scoresVictims,
    transportInvolved,
    typeOfAccident,
    victimSex,
    victimAge,
    latLng,
    city,
    street,
    subLocality,
    locality,
    administrativeArea,
    postalCode,
    country,
    isoCountryCode,
    subAdministrativeArea,
    thoroughfare,
    subThoroughfare,
    nameArea,
    createdAt,
    createdBy,
    updatedAt,
    updatedBy,
    deletedAt,
    deletedBy,
    year,
    month,
    yearDocId,
    cityNormalized,
  ];
}
