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
  String? referencePoint;        // 📍 já existia, manter
  int? death;
  String? highway;
  String? description;

  String? location;
  int? scoresVictims;
  String? transportInvolved;
  String? typeOfAccident;

  // NOVOS CAMPOS
  String? victimSex;             // ⚥ NOVO
  int?    victimAge;             // 🎂 NOVO

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

  // ---------- Denormalizações ----------
  int? year;
  int? month;
  String? yearDocId;
  String? recordPath;
  String? cityNormalized;

  String? get yearMonthKey => (year != null && month != null)
      ? '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}'
      : null;

  final Map<String, int> cityOfAccident = {};

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
    this.victimSex,              // ⚥
    this.victimAge,              // 🎂

    this.year,
    this.month,
    this.yearDocId,
    this.recordPath,
    this.cityNormalized,
  });

  // =================== Helpers ===================

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
    if (t.contains('MOTOCICLETA') || t.contains('MOTO')) return 'COLISÃO COM MOTOCICLETA';
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

  static String displayTitle(String canonical) => getTitleByAccidentType(canonical);
  static IconData iconFor(String canonical) => iconAccidentType(canonical);

  Future<void> loadAccidentsData(List<AccidentsData> accidentsData) async {
    cityOfAccident.clear();
    for (final acc in accidentsData) {
      final cityKey = normalizeString(acc.city);
      if (cityKey.isEmpty) continue;
      cityOfAccident[cityKey] = (cityOfAccident[cityKey] ?? 0) + 1;
    }
  }

  Map<String, Color> calculateColorsFilteredCity(List<AccidentsData> filteredAccidentsData) {
    final count = <String, int>{};
    for (final accidents in filteredAccidentsData) {
      final cityKey = normalizeString(accidents.city);
      if (cityKey.isEmpty) continue;
      count[cityKey] = (count[cityKey] ?? 0) + 1;
    }
    final max = count.values.fold<int>(1, (a, b) => math.max(a, b));
    return {
      for (final entry in count.entries)
        entry.key: interpolateColorsAccidentsFactor((entry.value / max).clamp(0.05, 1.0)),
    };
  }

  Color interpolateColorsAccidentsFactor(double accidentsFactor) {
    final index = (accidentsFactor *
        (AccidentsData.statusColorsAccidentType.length - 1))
        .floor()
        .clamp(0, AccidentsData.statusColorsAccidentType.length - 2);
    final t = accidentsFactor * (AccidentsData.statusColorsAccidentType.length - 1) - index;
    return Color.lerp(
      AccidentsData.statusColorsAccidentType[index],
      AccidentsData.statusColorsAccidentType[index + 1],
      t,
    )!;
  }

  static List<String> accidentTypes = [
    'COLISÃO COM ANIMAL','COLISÃO FRONTAL','COLISÃO TRASEIRA','COLISÃO LONGITUDINAL','COLISÃO TRANSVERSAL',
    'COLISÃO COM OBJETO FIXO','COLISÃO COM MOTOCICLETA','CAPOTAMENTO','TOMBAMENTO','ATROPELAMENTO','SAÍDA DE PISTA',
    'ENGAVETAMENTO','QUEDA DE MOTOCICLETA','QUEDA DE CICLISTA','QUEDA','CHOQUE','OUTROS',
  ];

  static const List<String> sexOptions = ['MASCULINO','FEMININO','IGNORADO'];

  static String getTitleByAccidentType(String status) {
    switch (status) {
      case 'COLISÃO COM ANIMAL': return 'Colisão com Animal';
      case 'COLISÃO FRONTAL': return 'Colisão Frontal';
      case 'COLISÃO TRASEIRA': return 'Colisão Traseira';
      case 'COLISÃO LONGITUDINAL': return 'Colisão Longitudinal';
      case 'COLISÃO TRANSVERSAL': return 'Colisão Transversal';
      case 'COLISÃO COM OBJETO FIXO': return 'Colisão com Objeto Fixo';
      case 'COLISÃO COM MOTOCICLETA': return 'Colisão com Motocicleta';
      case 'CAPOTAMENTO': return 'Capotamento';
      case 'TOMBAMENTO': return 'Tombamento';
      case 'ATROPELAMENTO': return 'Atropelamento';
      case 'SAÍDA DE PISTA': return 'Saída de Pista';
      case 'ENGAVETAMENTO': return 'Engavetamento';
      case 'QUEDA DE MOTOCICLETA': return 'Queda de Motocicleta';
      case 'QUEDA DE CICLISTA': return 'Queda de Ciclista';
      case 'QUEDA': return 'Queda';
      case 'CHOQUE': return 'Choque';
      default: return 'OUTROS';
    }
  }

  static IconData iconAccidentType(String status) {
    switch (status) {
      case 'COLISÃO COM ANIMAL': return Icons.pets;
      case 'COLISÃO FRONTAL': return Icons.car_crash;
      case 'COLISÃO TRASEIRA': return Icons.car_crash;
      case 'COLISÃO LONGITUDINAL': return Icons.car_crash;
      case 'COLISÃO TRANSVERSAL': return Icons.car_crash;
      case 'COLISÃO COM OBJETO FIXO': return Icons.minor_crash;
      case 'COLISÃO COM MOTOCICLETA': return Icons.motorcycle;
      case 'CAPOTAMENTO': return Icons.minor_crash;
      case 'TOMBAMENTO': return Icons.minor_crash;
      case 'ATROPELAMENTO': return Icons.directions_walk;
      case 'SAÍDA DE PISTA': return Icons.highlight;
      case 'ENGAVETAMENTO': return Icons.minor_crash;
      case 'QUEDA DE MOTOCICLETA': return Icons.motorcycle_outlined;
      case 'QUEDA DE CICLISTA': return Icons.bike_scooter;
      case 'QUEDA': return Icons.directions_walk;
      case 'CHOQUE': return Icons.warning;
      default: return Icons.not_listed_location;
    }
  }

  static List<Color> specificColorsAccidentType = [
    Colors.yellow.shade300, Colors.yellow.shade700, Colors.orange.shade400,
    Colors.orange.shade600, Colors.deepOrange.shade400, Colors.deepOrange.shade600,
    Colors.red.shade600, Colors.red.shade900,
  ];

  static List<Color> statusColorsAccidentType = [
    Colors.yellow.shade700, Colors.blue.shade300, Colors.green,
    Colors.orange.shade700, Colors.red.shade700, Colors.grey,
  ];

  static Color getColorByAccidentType(String status) {
    switch (status) {
      case 'COLISÃO COM ANIMAL': return Colors.yellow.shade700;
      case 'COLISÃO FRONTAL': return Colors.blue.shade300;
      case 'COLISÃO TRASEIRA': return Colors.green;
      case 'COLISÃO LONGITUDINAL': return Colors.orange.shade700;
      case 'COLISÃO TRANSVERSAL': return Colors.red.shade700;
      case 'COLISÃO COM OBJETO FIXO': return Colors.grey;
      case 'COLISÃO COM MOTOCICLETA': return Colors.yellow.shade700;
      case 'CAPOTAMENTO': return Colors.blue.shade300;
      case 'TOMBAMENTO': return Colors.green;
      case 'ATROPELAMENTO': return Colors.orange.shade700;
      case 'SAÍDA DE PISTA': return Colors.red.shade700;
      case 'ENGAVETAMENTO': return Colors.grey;
      case 'QUEDA DE MOTOCICLETA': return Colors.yellow.shade700;
      case 'QUEDA DE CICLISTA': return Colors.blue.shade300;
      case 'QUEDA': return Colors.green;
      case 'CHOQUE': return Colors.orange.shade700;
      default: return Colors.black;
    }
  }

  // =================== Firestore ===================

  factory AccidentsData.fromDocument({required DocumentSnapshot snapshot}) {
    final data = snapshot.data() as Map<String, dynamic>;

    final DateTime? dt = (data['date'] is Timestamp)
        ? (data['date'] as Timestamp).toDate()
        : parseDate(data['date']);

    final int? yr = (data['year'] is int) ? data['year'] as int : dt?.toLocal().year;
    final int? mo = (data['month'] is int) ? data['month'] as int : dt?.toLocal().month;

    LatLng? latLng;
    final lg = data['latLng'];
    if (lg is GeoPoint) {
      latLng = LatLng(lg.latitude, lg.longitude);
    } else if (lg is Map) {
      final la = lg['latitude'] ?? lg['lat'];
      final lo = lg['longitude'] ?? lg['lng'];
      if (la is num && lo is num) {
        latLng = LatLng(la.toDouble(), lo.toDouble());
      }
    }

    return AccidentsData(
      id: snapshot.id,
      city: data['city'],
      cityNormalized: data['cityNormalized'],
      date: dt,
      death: (data['death'] is int) ? data['death'] : (data['death'] is num ? (data['death'] as num).toInt() : null),
      highway: data['highway'],
      location: data['location'],
      referencePoint: data['referencePoint'],
      scoresVictims: (data['scoresVictims'] is int) ? data['scoresVictims'] : (data['scoresVictims'] is num ? (data['scoresVictims'] as num).toInt() : null),
      transportInvolved: data['transportInvolved'],
      typeOfAccident: data['typeOfAccident'] ?? '',
      order: data['order'] is int ? data['order'] : null,
      createdAt: data['createdAt'] is Timestamp ? (data['createdAt'] as Timestamp).toDate() : DateTime.tryParse('${data['createdAt'] ?? ''}'),
      createdBy: data['createdBy'],
      updatedAt: data['updatedAt'] is Timestamp ? (data['updatedAt'] as Timestamp).toDate() : DateTime.tryParse('${data['updatedAt'] ?? ''}'),
      updatedBy: data['updatedBy'],
      deletedAt: data['deletedAt'] is Timestamp ? (data['deletedAt'] as Timestamp).toDate() : DateTime.tryParse('${data['deletedAt'] ?? ''}'),
      deletedBy: data['deletedBy'],
      latLng: latLng,
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
      victimSex: data['victimSex'],
      victimAge: (data['victimAge'] is int) ? data['victimAge'] : (data['victimAge'] is num ? (data['victimAge'] as num).toInt() : null),

      year: yr,
      month: mo,
      yearDocId: data['yearDocId'],
      recordPath: data['recordPath'] ?? snapshot.reference.path,
    );
  }

  List<AccidentsData> converterParaAcidentes(List<Map<String, dynamic>> dados) {
    return dados.map((mapa) {
      return AccidentsData(
        id: mapa['id'],
        city: mapa['city'],
        cityNormalized: mapa['city'] != null ? normalizeString(mapa['city']) : null,
        date: AccidentsData.parseDate(mapa['date']),
        death: mapa['death'] is num ? (mapa['death'] as num).toInt() : null,
        highway: mapa['highway'],
        location: mapa['location'],
        referencePoint: mapa['referencePoint'],
        scoresVictims: mapa['scoresVictims'] is num ? (mapa['scoresVictims'] as num).toInt() : null,
        transportInvolved: mapa['transportInvolved'],
        typeOfAccident: mapa['typeOfAccident'],
        order: mapa['order'] is num ? (mapa['order'] as num).toInt() : null,
        createdAt: AccidentsData.parseDate(mapa['createdAt']),
        createdBy: mapa['createdBy'],
        updatedAt: AccidentsData.parseDate(mapa['updatedAt']),
        updatedBy: mapa['updatedBy'],
        deletedAt: AccidentsData.parseDate(mapa['deletedAt']),
        deletedBy: mapa['deletedBy'],
        latLng: (mapa['latLng'] is Map &&
            mapa['latLng']['latitude'] != null &&
            mapa['latLng']['longitude'] != null)
            ? LatLng(
          (mapa['latLng']['latitude'] as num).toDouble(),
          (mapa['latLng']['longitude'] as num).toDouble(),
        )
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

        victimSex: mapa['victimSex'],
        victimAge: mapa['victimAge'] is num ? (mapa['victimAge'] as num).toInt() : null,

        year: mapa['year'] is int ? mapa['year'] : null,
        month: mapa['month'] is int ? mapa['month'] : null,
        yearDocId: mapa['yearDocId'],
        recordPath: mapa['recordPath'],
      );
    }).toList();
  }

  Map<String, dynamic> toFirestore() {
    final y = year ?? date?.toLocal().year;
    final m = month ?? date?.toLocal().month;
    final cityNorm = city != null ? normalizeString(city) : '';

    return {
      'city': city ?? '',
      'cityNormalized': cityNorm,
      'date': date != null ? Timestamp.fromDate(date!) : null,
      'death': death,
      'highway': highway ?? '',
      'location': location ?? '',
      'scoresVictims': scoresVictims,
      'transportInvolved': transportInvolved ?? '',
      'typeOfAccident': typeOfAccident ?? '',
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'createdBy': createdBy ?? '',
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'updatedBy': updatedBy ?? '',
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'deletedBy': deletedBy ?? '',
      'order': order,
      'latLng': latLng != null ? {'latitude': latLng!.latitude, 'longitude': latLng!.longitude} : null,
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
      'referencePoint': referencePoint ?? '',     // ✅ gravar ponto de referência
      'victimSex': victimSex ?? '',               // ✅ gravar sexo
      'victimAge': victimAge,                     // ✅ gravar idade

      'year': y,
      'month': m,
      'yearDocId': yearDocId,
      'recordPath': recordPath,
      'yearMonthKey': (y != null && m != null)
          ? '${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}'
          : null,
    };
  }

  // =================== Datas ===================

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
