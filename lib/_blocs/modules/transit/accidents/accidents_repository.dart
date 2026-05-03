// lib/_blocs/modules/transit/accidents/accidents_repository.dart

import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import 'accidents_data.dart';

class AccidentsRepository {
  AccidentsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    String? publicReportBaseUrl,

    /// Novo modelo:
    /// tenants/{tenantId}/traffic/accidents/items
    String? tenantId,

    /// Caso queira informar manualmente o caminho completo da coleção de anos.
    ///
    /// Exemplo:
    /// tenants/empresaA/traffic/accidents/items
    ///
    /// Se informado, ele tem prioridade sobre o tenant fixo de teste.
    String? baseCollectionPath,

    /// Mantém leitura compatível com a estrutura antiga:
    /// trafficAccidents/{year}/records
    bool enableLegacyFallback = true,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _tenantId = tenantId,
        _baseCollectionPath = baseCollectionPath,
        _enableLegacyFallback = enableLegacyFallback,
        _publicReportBaseUrl = _resolvePublicReportBaseUrl(publicReportBaseUrl);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  final String? _tenantId;
  final String? _baseCollectionPath;
  final bool _enableLegacyFallback;

  /// ID fixo temporário para teste.
  static const String _manualTenantIdForTest = 'SZQmefRUqdtLB14ahcuh';

  /// Estrutura antiga.
  static const String legacyCollectionPath = 'trafficAccidents';

  /// Exemplo final: https://deral.sipged.com.br/bo
  /// O link PDF final será: {_publicReportBaseUrl}/{token}.pdf
  final String _publicReportBaseUrl;

  /// Estrutura nova temporária para teste:
  ///
  /// tenants/SZQmefRUqdtLB14ahcuh/traffic/accidents/items
  ///
  /// Depois, remova o uso de [_manualTenantIdForTest] e volte para [_tenantId].
  String get collectionPath {
    final explicit = (_baseCollectionPath ?? '').trim();

    if (explicit.isNotEmpty) {
      return explicit;
    }

    final tenant = _manualTenantIdForTest.trim();

    if (tenant.isNotEmpty) {
      return 'tenants/$tenant/traffic/accidents/items';
    }

    final dynamicTenant = (_tenantId ?? '').trim();

    if (dynamicTenant.isNotEmpty) {
      return 'tenants/$dynamicTenant/traffic/accidents/items';
    }

    return 'traffic/accidents/items';
  }

  CollectionReference<Map<String, dynamic>> get _containers {
    return _db.collection(collectionPath);
  }

  CollectionReference<Map<String, dynamic>> get _legacyContainers {
    return _db.collection(legacyCollectionPath);
  }

  static String _resolvePublicReportBaseUrl(String? provided) {
    final p = (provided ?? '').trim();

    if (p.isNotEmpty) {
      return _normalizeBase(p);
    }

    final env = const String.fromEnvironment(
      'PUBLIC_REPORT_BASE_URL',
      defaultValue: '',
    ).trim();

    if (env.isNotEmpty) {
      return _normalizeBase(env);
    }

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

  LocationSettings _buildLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.best,
    Duration? timeLimit,
  }) {
    if (kIsWeb) {
      return WebSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
        distanceFilter: 0,
        forceLocationManager: false,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
      );
    }

    return LocationSettings(
      accuracy: accuracy,
      timeLimit: timeLimit,
    );
  }

  int _yearFromDateTime(DateTime dt, {bool local = true}) {
    return local ? dt.toLocal().year : dt.toUtc().year;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getYearRefFrom(
      CollectionReference<Map<String, dynamic>> collection,
      int year,
      ) async {
    final deterministicRef = collection.doc(year.toString());
    final deterministicSnap = await deterministicRef.get();

    if (deterministicSnap.exists) {
      return deterministicRef;
    }

    final q = await collection.where('year', isEqualTo: year).limit(1).get();

    if (q.docs.isNotEmpty) {
      return q.docs.first.reference;
    }

    return null;
  }

  Future<DocumentReference<Map<String, dynamic>>?> _getYearRefCompat(
      int year,
      ) async {
    final currentRef = await _getYearRefFrom(_containers, year);

    if (currentRef != null) {
      return currentRef;
    }

    if (!_enableLegacyFallback) {
      return null;
    }

    return _getYearRefFrom(_legacyContainers, year);
  }

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateYearRefCanonical(
      int year,
      ) async {
    final existing = await _getYearRefFrom(_containers, year);

    if (existing != null) {
      await existing.set(
        {
          'year': year,
          'module': 'traffic',
          'type': 'accidents',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': _auth.currentUser?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      return existing;
    }

    final ref = _containers.doc(year.toString());

    await ref.set(
      {
        'year': year,
        'module': 'traffic',
        'type': 'accidents',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': _auth.currentUser?.uid ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': _auth.currentUser?.uid ?? '',
      },
      SetOptions(merge: true),
    );

    return ref;
  }

  Future<List<DocumentReference<Map<String, dynamic>>>> _listYearRefsFrom(
      CollectionReference<Map<String, dynamic>> collection,
      ) async {
    final snap = await collection.get();

    final refs = snap.docs.where((doc) {
      final data = doc.data();
      final year = (data['year'] as num?)?.toInt();

      if (year != null && year > 0) {
        return true;
      }

      return int.tryParse(doc.id) != null;
    }).map((doc) {
      return doc.reference;
    }).toList();

    refs.sort((a, b) {
      final ay = int.tryParse(a.id) ?? 0;
      final by = int.tryParse(b.id) ?? 0;

      return by.compareTo(ay);
    });

    return refs;
  }

  Future<List<DocumentReference<Map<String, dynamic>>>>
  _listYearRefsCompat() async {
    final current = await _listYearRefsFrom(_containers);

    if (current.isNotEmpty || !_enableLegacyFallback) {
      return current;
    }

    return _listYearRefsFrom(_legacyContainers);
  }

  Future<List<int>> listAvailableYears() async {
    final refs = await _listYearRefsCompat();

    final years = <int>{};

    for (final ref in refs) {
      final snap = await ref.get();
      final data = snap.data();

      final yearFromField = (data?['year'] as num?)?.toInt();
      final yearFromId = int.tryParse(ref.id);

      final year = yearFromField ?? yearFromId;

      if (year != null && year > 0) {
        years.add(year);
      }
    }

    final list = years.toList()..sort((a, b) => b.compareTo(a));

    return list;
  }

  Future<void> deleteAccident({
    required String id,
    required int year,
  }) async {
    final yearRef = await _getYearRefCompat(year);

    if (yearRef == null) {
      return;
    }

    final doc = yearRef.collection('records').doc(id);
    final snap = await doc.get();

    if (snap.exists) {
      await doc.delete();
    }
  }

  Future<void> saveOrUpdateAccident(AccidentsData data) async {
    final user = _auth.currentUser;

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
      'sourcePath': recordPath,
      'module': 'traffic',
      'type': 'accidents',
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
    } else {
      json.remove('createdAt');
      json.remove('createdBy');
    }

    await _db.runTransaction((tx) async {
      tx.set(
        yearRef,
        {
          'year': year,
          'module': 'traffic',
          'type': 'accidents',
          'updatedAt': FieldValue.serverTimestamp(),
          'updatedBy': user?.uid ?? '',
        },
        SetOptions(merge: true),
      );

      tx.set(
        docRef,
        json,
        SetOptions(merge: true),
      );
    });
  }

  Future<List<AccidentsData>> getAllAccidents({
    int? year,
    int? month,
    String? city,
  }) async {
    final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
    <QueryDocumentSnapshot<Map<String, dynamic>>>[];

    if (year != null) {
      final yearRef = await _getYearRefCompat(year);

      if (yearRef == null) {
        return <AccidentsData>[];
      }

      Query<Map<String, dynamic>> q = yearRef.collection('records');

      if (month != null) {
        final start = DateTime(year, month, 1);
        final end = month == 12
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

      final snap = await q.orderBy('date').get();
      docs.addAll(snap.docs);
    } else {
      final yearRefs = await _listYearRefsCompat();

      for (final yearRef in yearRefs) {
        Query<Map<String, dynamic>> q = yearRef.collection('records');

        if (month != null) {
          q = q.where('month', isEqualTo: month);
        }

        if (city != null && city.trim().isNotEmpty) {
          final norm = AccidentsData.normalizeString(city);
          q = q.where('cityNormalized', isEqualTo: norm);
        }

        final snap = await q.get();
        docs.addAll(snap.docs);
      }

      docs.sort((a, b) {
        final ad = a.data()['date'];
        final bd = b.data()['date'];

        final aDate = ad is Timestamp
            ? ad.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);

        final bDate = bd is Timestamp
            ? bd.toDate()
            : DateTime.fromMillisecondsSinceEpoch(0);

        return aDate.compareTo(bDate);
      });
    }

    return docs.map((d) => AccidentsData.fromDocument(d)).toList();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> pageRecordsByYear({
    required int year,
    DocumentSnapshot? lastDoc,
    int limit = 200,
  }) async {
    final yearRef = await _getYearRefCompat(year);

    if (yearRef == null) {
      return _containers.doc('__empty__').collection('records').limit(0).get();
    }

    Query<Map<String, dynamic>> query =
    yearRef.collection('records').orderBy('date');

    if (lastDoc != null) {
      query = query.startAfterDocument(lastDoc);
    }

    return query.limit(limit.clamp(1, 500)).get();
  }

  Future<int> countByYear(int year) async {
    final yearRef = await _getYearRefCompat(year);

    if (yearRef == null) {
      return 0;
    }

    final snap = await yearRef.collection('records').get();

    return snap.docs.length;
  }

  Future<Map<String, double>> getTotaisPorTipoAcidente(
      List<AccidentsData> acidentes,
      ) async {
    final Map<String, double> totais = <String, double>{};

    for (final a in acidentes) {
      final key = AccidentsData.canonicalType(a.typeOfAccident);
      totais[key] = (totais[key] ?? 0) + 1.0;
    }

    return totais;
  }

  Future<Map<String, double>> getValoresPorCidade(
      List<AccidentsData> acidentes,
      ) async {
    final Map<String, double> totais = <String, double>{};

    for (final a in acidentes) {
      final cidade = (a.city ?? '').trim();
      final key = cidade.isEmpty ? 'NÃO INFORMADO' : cidade.toUpperCase();

      totais[key] = (totais[key] ?? 0.0) + 1.0;
    }

    return totais;
  }

  CollectionReference<Map<String, dynamic>> get _publicReports {
    return _db.collection('publicAccidentReports');
  }

  String _makeToken({int bytes = 24}) {
    final rnd = Random.secure();

    final data = Uint8List.fromList(
      List<int>.generate(bytes, (_) => rnd.nextInt(256)),
    );

    final sb = StringBuffer();

    for (final b in data) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }

    return sb.toString();
  }

  String buildPublicUrlFromToken(String token) {
    final base = _publicReportBaseUrl.trim();

    if (base.isEmpty) {
      return token;
    }

    final t = token.trim();

    return '$base/$t.pdf';
  }

  Future<String> ensurePublicReportLink({
    required AccidentsData accident,
    Duration expiresIn = const Duration(days: 30),
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado (necessário para gerar link).');
    }

    final recordPath = (accident.recordPath ?? '').trim();
    final accidentId = (accident.id ?? '').trim();

    if (recordPath.isEmpty || accidentId.isEmpty) {
      throw Exception('Registro inválido: id/recordPath ausentes.');
    }

    final expiresAt = DateTime.now().add(expiresIn);

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
            'expiresAt': Timestamp.fromDate(
              accident.publicReportExpiresAt ?? expiresAt,
            ),
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
    DocumentReference<Map<String, dynamic>> publicDoc =
    _publicReports.doc(token);

    for (int i = 0; i < 3; i++) {
      final exists = (await publicDoc.get()).exists;

      if (!exists) {
        break;
      }

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
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('Usuário não autenticado.');
    }

    final token = (accident.publicReportToken ?? '').trim();
    final recordPath = (accident.recordPath ?? '').trim();

    if (token.isEmpty || recordPath.isEmpty) {
      return;
    }

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

  /// Corrige datas apenas dentro do módulo de acidentes.
  ///
  /// Não usa collectionGroup('records') aberto para não misturar acidentes,
  /// infrações e outros módulos que também usam subcoleção chamada "records".
  Future<void> corrigirDatasAcidentesCollectionGroup() async {
    final DateFormat formato = DateFormat('dd/MM/yyyy');
    final yearRefs = await _listYearRefsCompat();

    for (final yearRef in yearRefs) {
      final snap = await yearRef.collection('records').get();

      for (final doc in snap.docs) {
        final data = doc.data();
        final rawDate = data['date'];

        if (rawDate is String) {
          try {
            final parsed = formato.parseStrict(rawDate);

            await doc.reference.update({
              'date': Timestamp.fromDate(parsed),
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': _auth.currentUser?.uid ?? '',
            });
          } catch (_) {}
        }
      }
    }
  }

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

    final via = json.decode(
      utf8.decode(viaResp.bodyBytes),
    ) as Map<String, dynamic>;

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
          'User-Agent': 'SIPGED-Accidents/1.0',
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
            'User-Agent': 'SIPGED-Accidents/1.0',
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

    if (!serviceEnabled) {
      return LocationPermission.denied;
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return permission;
  }

  String _firstNonEmpty(List<String?> vals) {
    for (final v in vals) {
      if (v != null && v.trim().isNotEmpty) {
        return v.trim();
      }
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
        'User-Agent': 'SIPGED-Accidents/1.0',
        'Accept': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      return AddressSuggestion(latitude: lat, longitude: lon);
    }

    final data = json.decode(
      utf8.decode(resp.bodyBytes),
    ) as Map<String, dynamic>;

    final addr = data['address'] is Map
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
      locationSettings: _buildLocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 15),
      ),
    );

    try {
      final suggestion = await _reverseGeocodeOSM(
        lat: pos.latitude,
        lon: pos.longitude,
        acceptLanguage: 'pt-BR',
      );

      return suggestion.latitude != null
          ? suggestion
          : AddressSuggestion(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {
      return AddressSuggestion(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
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
      return AddressSuggestion(
        latitude: lat,
        longitude: lon,
      );
    }
  }
}

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