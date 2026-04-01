// lib/_blocs/modules/transit/accidents/accidents_repository.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:equatable/equatable.dart';

import 'accidents_data.dart';

class AccidentsRepository {
  AccidentsRepository({
    FirebaseFirestore? firestore,
    String? publicReportBaseUrl,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _publicReportBaseUrl = _resolvePublicReportBaseUrl(publicReportBaseUrl);

  final FirebaseFirestore _db;

  /// Exemplo final: https://deral.sipged.com.br/bo
  /// O link PDF final será: {_publicReportBaseUrl}/{token}.pdf
  final String _publicReportBaseUrl;

  static String _resolvePublicReportBaseUrl(String? provided) {
    final p = (provided ?? '').trim();
    if (p.isNotEmpty) return _normalizeBase(p);

    final env = const String.fromEnvironment(
      'PUBLIC_REPORT_BASE_URL',
      defaultValue: '',
    ).trim();
    if (env.isNotEmpty) return _normalizeBase(env);

    // Runtime web
    final uri = Uri.base;
    final scheme = uri.scheme.toLowerCase();
    if (scheme == 'http' || scheme == 'https') {
      final origin =
          '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
      return _normalizeBase('$origin/bo');
    }

    return '';
  }

  static String _normalizeBase(String base) {
    var b = base.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  int _yearFromDateTime(DateTime dt, {bool local = true}) =>
      local ? dt.toLocal().year : dt.toUtc().year;

  Future<DocumentReference<Map<String, dynamic>>?> _getYearRefCompat(
      int year) async {
    final detRef = _db.collection('trafficAccidents').doc(year.toString());
    final detSnap = await detRef.get();
    if (detSnap.exists) return detRef;

    final q = await _db
        .collection('trafficAccidents')
        .where('year', isEqualTo: year)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return q.docs.first.reference;
    return null;
  }

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateYearRefCanonical(
      int year) async {
    final detRef = _db.collection('trafficAccidents').doc(year.toString());
    await detRef.set({'year': year}, SetOptions(merge: true));
    return detRef;
  }

  // ===========================================================================
  // CRUD
  // ===========================================================================

  Future<void> deleteAccident({
    required String id,
    required int year,
  }) async {
    final yearRef = await _getYearRefCompat(year);
    if (yearRef == null) return;

    final doc = yearRef.collection('records').doc(id);
    final snap = await doc.get();
    if (snap.exists) {
      await doc.delete();
    }
  }

  Future<void> saveOrUpdateAccident(AccidentsData data) async {
    final user = FirebaseAuth.instance.currentUser;

    if (data.date == null) {
      throw Exception("Campo 'date' é obrigatório em AccidentsData.");
    }

    final DateTime dt = data.date!.toLocal();
    final int year = _yearFromDateTime(dt, local: true);
    final int month = dt.month;

    final yearRef = await _getOrCreateYearRefCanonical(year);
    final records = yearRef.collection('records');

    final bool isUpdate = data.id != null && data.id!.isNotEmpty;
    final docRef = isUpdate ? records.doc(data.id) : records.doc();

    final String recordId = docRef.id;
    final String recordPath = docRef.path;

    final base = data.toFirestore();

    final json = <String, dynamic>{
      ...base,
      'id': data.id ?? recordId,
      'year': year,
      'month': month,
      'yearDocId': yearRef.id,
      'recordPath': recordPath,
      'recordId': recordId,
      'sourcePath': '${yearRef.path}/records/$recordId',
      'yearMonthKey':
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}',
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': user?.uid ?? '',
    };

    final snap = await docRef.get();
    final isNew = !snap.exists || (snap.data()?['createdAt'] == null);

    if (isNew) {
      json['createdAt'] = FieldValue.serverTimestamp();
      json['createdBy'] = user?.uid ?? '';
    }

    await _db.runTransaction((tx) async {
      tx.set(yearRef, {'year': year}, SetOptions(merge: true));
      tx.set(docRef, json, SetOptions(merge: true));
    });
  }

  // ===========================================================================
  // CONSULTAS
  // ===========================================================================

  Future<List<AccidentsData>> getAllAccidents({
    int? year,
    int? month,
    String? city,
  }) async {
    Query q;

    if (year != null) {
      final yearRef = await _getYearRefCompat(year);
      if (yearRef == null) return [];

      q = yearRef.collection('records').orderBy('date');

      if (month != null) {
        final start = DateTime(year, month, 1);
        final end = (month == 12)
            ? DateTime(year + 1, 1, 1)
            : DateTime(year, month + 1, 1);

        q = q
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThan: Timestamp.fromDate(end));
      }

      if (city != null && city.trim().isNotEmpty) {
        final norm = AccidentsData.normalizeString(city);
        q = q.where('cityNormalized', isEqualTo: norm);
      }
    } else {
      q = _db.collectionGroup('records').orderBy('date');

      if (month != null) {
        q = q.where('month', isEqualTo: month);
      }
      if (city != null && city.trim().isNotEmpty) {
        final norm = AccidentsData.normalizeString(city);
        q = q.where('cityNormalized', isEqualTo: norm);
      }
    }

    final snap = await q.get();
    return snap.docs.map((d) => AccidentsData.fromDocument(d)).toList();
  }

  // ===========================================================================
  // AGREGAÇÕES
  // ===========================================================================

  Future<Map<String, double>> getTotaisPorTipoAcidente(
      List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final key = AccidentsData.canonicalType(a.typeOfAccident);
      totais[key] = (totais[key] ?? 0) + 1.0;
    }
    return totais;
  }

  Future<Map<String, double>> getValoresPorCidade(
      List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final cidade = (a.city ?? '').trim();
      final key = cidade.isEmpty ? 'NÃO INFORMADO' : cidade.toUpperCase();
      totais[key] = (totais[key] ?? 0.0) + 1.0;
    }
    return totais;
  }

  // ===========================================================================
  // ✅ LINK PÚBLICO (QR) -> PDF
  // ===========================================================================

  CollectionReference<Map<String, dynamic>> get _publicReports =>
      _db.collection('publicAccidentReports');

  String _makeToken({int bytes = 24}) {
    final rnd = Random.secure();
    final data =
    Uint8List.fromList(List<int>.generate(bytes, (_) => rnd.nextInt(256)));
    final sb = StringBuffer();
    for (final b in data) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }

  /// ✅ Agora devolve URL de PDF (direto no browser)
  String buildPublicUrlFromToken(String token) {
    final base = _publicReportBaseUrl.trim();
    if (base.isEmpty) return token; // fallback (não recomendado)
    final t = token.trim();
    return '$base/$t.pdf';
  }

  Future<String> ensurePublicReportLink({
    required AccidentsData accident,
    Duration expiresIn = const Duration(days: 30),
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado (necessário para gerar link).');
    }

    final recordPath = (accident.recordPath ?? '').trim();
    final accidentId = (accident.id ?? '').trim();
    if (recordPath.isEmpty || accidentId.isEmpty) {
      throw Exception('Registro inválido: id/recordPath ausentes.');
    }

    final now = DateTime.now();
    final expiresAt = now.add(expiresIn);

    if (accident.publicReportIsValid) {
      final token = accident.publicReportToken!.trim();
      final publicDoc = _publicReports.doc(token);

      await _db.runTransaction((tx) async {
        tx.set(
          publicDoc,
          {
            'token': token,
            'accidentId': accidentId,
            'recordPath': recordPath,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(accident.publicReportExpiresAt ?? expiresAt),
            'revokedAt': null,
            'enabled': true,
            'publicData': accident.toPublicReportMap(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });

      return buildPublicUrlFromToken(token);
    }

    String token = _makeToken();
    DocumentReference<Map<String, dynamic>> publicDoc = _publicReports.doc(token);

    for (int i = 0; i < 3; i++) {
      final exists = (await publicDoc.get()).exists;
      if (!exists) break;
      token = _makeToken();
      publicDoc = _publicReports.doc(token);
    }

    final accidentDoc = _db.doc(recordPath);

    await _db.runTransaction((tx) async {
      tx.set(
        publicDoc,
        {
          'token': token,
          'accidentId': accidentId,
          'recordPath': recordPath,
          'createdAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'revokedAt': null,
          'enabled': true,
          'publicData': accident.toPublicReportMap(),
          'createdBy': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        },
        SetOptions(merge: true),
      );

      tx.set(
        accidentDoc,
        {
          'publicReport': {
            'enabled': true,
            'token': token,
            'createdAt': FieldValue.serverTimestamp(),
            'expiresAt': Timestamp.fromDate(expiresAt),
            'revokedAt': null,
          },
        },
        SetOptions(merge: true),
      );
    });

    return buildPublicUrlFromToken(token);
  }

  Future<void> revokePublicReportLink({
    required AccidentsData accident,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Usuário não autenticado.');

    final token = (accident.publicReportToken ?? '').trim();
    final recordPath = (accident.recordPath ?? '').trim();
    if (token.isEmpty || recordPath.isEmpty) return;

    final now = DateTime.now();
    final publicDoc = _publicReports.doc(token);
    final accidentDoc = _db.doc(recordPath);

    await _db.runTransaction((tx) async {
      tx.set(
        publicDoc,
        {
          'enabled': false,
          'revokedAt': Timestamp.fromDate(now),
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user.uid,
        },
        SetOptions(merge: true),
      );

      tx.set(
        accidentDoc,
        {
          'publicReport': {
            'enabled': false,
            'revokedAt': Timestamp.fromDate(now),
          },
        },
        SetOptions(merge: true),
      );
    });
  }

  // ===========================================================================
  // UTILITÁRIO LEGADO
  // ===========================================================================

  Future<void> corrigirDatasAcidentesCollectionGroup() async {
    final DateFormat formato = DateFormat('dd/MM/yyyy');
    final snap = await _db.collectionGroup('records').get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final rawDate = data['date'];

      if (rawDate is String) {
        try {
          final parsed = formato.parseStrict(rawDate);
          await doc.reference.update({'date': Timestamp.fromDate(parsed)});
        } catch (_) {}
      }
    }
  }

  // ===========================================================================
  // GEOCODING / LOCALIZAÇÃO (ViaCEP + Nominatim, sem Google)
  // ===========================================================================

  Future<AddressSuggestion> geocodeCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw Exception('CEP inválido: "$cep"');
    }

    final viaCepUri = Uri.https('viacep.com.br', '/ws/$digits/json/');
    final viaResp = await http.get(
      viaCepUri,
      headers: {'Accept': 'application/json'},
    );
    if (viaResp.statusCode != 200) {
      throw Exception('Falha no ViaCEP ($digits): HTTP ${viaResp.statusCode}');
    }

    final via =
    json.decode(utf8.decode(viaResp.bodyBytes)) as Map<String, dynamic>;

    if (via['erro'] == true) {
      throw Exception('CEP não encontrado no ViaCEP: $digits');
    }

    final logradouro = (via['logradouro'] as String? ?? '').trim();
    final bairro = (via['bairro'] as String? ?? '').trim();
    final cidade = (via['localidade'] as String? ?? '').trim();
    final uf = (via['uf'] as String? ?? '').trim();

    LatLng? pos;
    try {
      final nomiUri = Uri.https(
        'nominatim.openstreetmap.org',
        '/search',
        {
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '1',
          'countrycodes': 'br',
          'postalcode': digits,
          if (cidade.isNotEmpty) 'city': cidade,
          if (uf.isNotEmpty) 'state': uf,
          if (logradouro.isNotEmpty) 'street': logradouro,
        },
      );

      final nomiResp = await http.get(
        nomiUri,
        headers: {
          'User-Agent': 'SIGED-Accidents/1.0 (contato@seu-dominio.gov.br)',
          'Accept': 'application/json',
        },
      );

      if (nomiResp.statusCode == 200) {
        final arr = json.decode(utf8.decode(nomiResp.bodyBytes));
        if (arr is List && arr.isNotEmpty) {
          final first = arr.first as Map<String, dynamic>;
          final lat = double.tryParse(first['lat']?.toString() ?? '');
          final lon = double.tryParse(first['lon']?.toString() ?? '');
          if (lat != null && lon != null) {
            pos = LatLng(lat, lon);
          }
        }
      }

      if (pos == null) {
        final qParts = [
          if (logradouro.isNotEmpty) logradouro,
          if (bairro.isNotEmpty) bairro,
          if (cidade.isNotEmpty) cidade,
          if (uf.isNotEmpty) uf,
          'Brasil',
          digits,
        ];
        final q = qParts.where((e) => e.trim().isNotEmpty).join(', ');

        final nomiUri2 = Uri.https(
          'nominatim.openstreetmap.org',
          '/search',
          {
            'format': 'jsonv2',
            'addressdetails': '1',
            'limit': '1',
            'countrycodes': 'br',
            'q': q,
          },
        );

        final r2 = await http.get(
          nomiUri2,
          headers: {
            'User-Agent': 'SIGED-Accidents/1.0 (contato@seu-dominio.gov.br)',
            'Accept': 'application/json',
          },
        );

        if (r2.statusCode == 200) {
          final arr = json.decode(utf8.decode(r2.bodyBytes));
          if (arr is List && arr.isNotEmpty) {
            final first = arr.first as Map<String, dynamic>;
            final lat = double.tryParse(first['lat']?.toString() ?? '');
            final lon = double.tryParse(first['lon']?.toString() ?? '');
            if (lat != null && lon != null) {
              pos = LatLng(lat, lon);
            }
          }
        }
      }
    } catch (_) {}

    return AddressSuggestion(
      latitude: pos?.latitude,
      longitude: pos?.longitude,
      street: logradouro,
      subLocality: bairro,
      administrativeArea: uf,
      postalCode: digits,
      country: 'Brasil',
      isoCountryCode: 'BR',
      city: cidade,
    );
  }

  Future<LocationPermission> _ensurePermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationPermission.denied;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission;
  }

  String _firstNonEmpty(List<String?> vals) {
    for (final v in vals) {
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return '';
  }

  Future<AddressSuggestion> _reverseGeocodeOSM({
    required double lat,
    required double lon,
    String acceptLanguage = 'pt-BR',
  }) async {
    final uri = Uri.https(
      'nominatim.openstreetmap.org',
      '/reverse',
      {
        'format': 'jsonv2',
        'lat': lat.toString(),
        'lon': lon.toString(),
        'addressdetails': '1',
        'zoom': '18',
        'accept-language': acceptLanguage,
      },
    );

    final resp = await http.get(
      uri,
      headers: {
        'User-Agent': 'SIGED-Accidents/1.0 (contato@seu-dominio.gov.br)',
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      return AddressSuggestion(latitude: lat, longitude: lon);
    }

    final data =
    json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final addr = (data['address'] is Map)
        ? (data['address'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};

    final road = addr['road'] as String? ??
        addr['pedestrian'] as String? ??
        addr['path'] as String?;
    final houseNumber = addr['house_number'] as String?;
    final street = [road, houseNumber]
        .where((e) => e != null && e.toString().trim().isNotEmpty)
        .join(', ');

    final subLocality = _firstNonEmpty([
      addr['suburb'] as String?,
      addr['neighbourhood'] as String?,
      addr['city_district'] as String?,
      addr['quarter'] as String?,
    ]);

    final city = _firstNonEmpty([
      addr['city'] as String?,
      addr['town'] as String?,
      addr['village'] as String?,
      addr['municipality'] as String?,
      addr['county'] as String?,
    ]);

    final state = addr['state'] as String? ?? '';
    final postcode = addr['postcode'] as String? ?? '';
    final country = addr['country'] as String? ?? '';
    final isoCountry = (addr['country_code'] as String? ?? '').toUpperCase();

    return AddressSuggestion(
      latitude: lat,
      longitude: lon,
      street: street,
      subLocality: subLocality,
      administrativeArea: state,
      postalCode: postcode,
      country: country,
      isoCountryCode: isoCountry,
      city: city,
    );
  }

  Future<AddressSuggestion> resolveCurrentLocation() async {
    final permission = await _ensurePermission();
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente.');
    }
    if (permission == LocationPermission.denied) {
      throw Exception('Permissão de localização negada.');
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
      timeLimit: const Duration(seconds: 15),
    );

    try {
      final suggestion = await _reverseGeocodeOSM(
        lat: pos.latitude,
        lon: pos.longitude,
        acceptLanguage: 'pt-BR',
      );
      return suggestion.latitude != null
          ? suggestion
          : AddressSuggestion(latitude: pos.latitude, longitude: pos.longitude);
    } catch (_) {
      return AddressSuggestion(latitude: pos.latitude, longitude: pos.longitude);
    }
  }

  Future<AddressSuggestion> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    try {
      return await _reverseGeocodeOSM(
        lat: lat,
        lon: lon,
        acceptLanguage: 'pt-BR',
      );
    } catch (_) {
      return AddressSuggestion(latitude: lat, longitude: lon);
    }
  }
}

// ============================================================================
// MODELO AUXILIAR: AddressSuggestion
// ============================================================================

class AddressSuggestion extends Equatable {
  final double? latitude;
  final double? longitude;
  final String street;
  final String subLocality;
  final String administrativeArea;
  final String postalCode;
  final String country;
  final String isoCountryCode;
  final String city;

  const AddressSuggestion({
    this.latitude,
    this.longitude,
    this.street = '',
    this.subLocality = '',
    this.administrativeArea = '',
    this.postalCode = '',
    this.country = '',
    this.isoCountryCode = '',
    this.city = '',
  });

  @override
  List<Object?> get props => [
    latitude,
    longitude,
    street,
    subLocality,
    administrativeArea,
    postalCode,
    country,
    isoCountryCode,
    city,
  ];
}