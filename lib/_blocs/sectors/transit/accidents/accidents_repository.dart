import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:diacritic/diacritic.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'package:siged/_blocs/sectors/transit/accidents/accidents_data.dart';
import 'package:siged/_blocs/sectors/transit/accidents/accidents_state.dart';

class AccidentsRepository {
  AccidentsRepository({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  int _yearFromDateTime(DateTime dt, {bool local = true}) =>
      local ? dt.toLocal().year : dt.toUtc().year;

  Future<DocumentReference<Map<String, dynamic>>?> _getYearRefCompat(int year) async {
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

  Future<DocumentReference<Map<String, dynamic>>> _getOrCreateYearRefCanonical(int year) async {
    final detRef = _db.collection('trafficAccidents').doc(year.toString());
    await detRef.set({'year': year}, SetOptions(merge: true));
    return detRef;
  }

  // ========= CRUD =========
  Future<void> deleteAccident({required String id, required int year}) async {
    final yearRef = await _getYearRefCompat(year);
    if (yearRef == null) return;
    final doc = yearRef.collection('records').doc(id);
    final snap = await doc.get();
    if (snap.exists) await doc.delete();
  }

  Future<void> saveOrUpdateAccident(AccidentsData data) async {
    final user = FirebaseAuth.instance.currentUser;

    if (data.date == null) {
      throw Exception("Campo 'date' é obrigatório em AccidentsData.");
    }

    final year = _yearFromDateTime(data.date!, local: true);
    final month = data.date!.toLocal().month;

    final yearRef = await _getOrCreateYearRefCanonical(year);
    final records = yearRef.collection('records');
    final docRef = (data.id != null && data.id!.isNotEmpty)
        ? records.doc(data.id)
        : records.doc();
    data.id ??= docRef.id;

    data.year = year;
    data.month = month;
    data.yearDocId = yearRef.id;
    data.recordPath = docRef.path;
    data.cityNormalized =
    data.city != null ? AccidentsData.normalizeString(data.city) : '';

    final json = data.toFirestore()
      ..addAll({
        'year': year,
        'month': month,
        'yearDocId': yearRef.id,
        'recordPath': docRef.path,
        'recordId': docRef.id,
        'sourcePath': '${yearRef.path}/records/${docRef.id}',
        'yearMonthKey':
        '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}',
        'updatedAt': FieldValue.serverTimestamp(),
        'updatedBy': user?.uid ?? '',
      });

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

  // ========= Consultas =========
  Future<List<AccidentsData>> getAllAccidents({int? year, int? month, String? city}) async {
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
        final norm = removeDiacritics(city).trim().toUpperCase();
        q = q.where('cityNormalized', isEqualTo: norm);
      }
    } else {
      q = _db.collectionGroup('records').orderBy('date');
      if (month != null) q = q.where('month', isEqualTo: month);
      if (city != null && city.trim().isNotEmpty) {
        final norm = removeDiacritics(city).trim().toUpperCase();
        q = q.where('cityNormalized', isEqualTo: norm);
      }
    }

    final snap = await q.get();
    return snap.docs.map((d) => AccidentsData.fromDocument(snapshot: d)).toList();
  }

  // ========= Agregações =========
  Future<Map<String, double>> getTotaisPorTipoAcidente(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final key = AccidentsData.canonicalType(a.typeOfAccident);
      totais[key] = (totais[key] ?? 0) + 1.0;
    }
    return totais;
  }

  Future<Map<String, double>> getValoresPorCidade(List<AccidentsData> acidentes) async {
    final Map<String, double> totais = {};
    for (final a in acidentes) {
      final cidade = (a.city ?? '').trim();
      final key = cidade.isEmpty ? 'NÃO INFORMADO' : cidade.toUpperCase();
      totais[key] = (totais[key] ?? 0.0) + 1.0;
    }
    return totais;
  }

  // ========= utilitário legado =========
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
        } catch (_) {/* continua */}
      }
    }
  }

  /// Geocodifica um CEP brasileiro (apenas dígitos) e retorna uma sugestão de endereço.
  /// Deve preencher latitude/longitude quando o serviço suportar (ex.: Nominatim + "postalcode").
  Future<AddressSuggestion> geocodeCep(String cep) async {
    final digits = cep.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw Exception('CEP inválido: "$cep"');
    }

    // 1) ViaCEP
    final viaCepUri = Uri.https('viacep.com.br', '/ws/$digits/json/');
    final viaResp = await http.get(viaCepUri, headers: {'Accept': 'application/json'});
    if (viaResp.statusCode != 200) {
      throw Exception('Falha no ViaCEP ($digits): HTTP ${viaResp.statusCode}');
    }

    final via = json.decode(utf8.decode(viaResp.bodyBytes)) as Map<String, dynamic>;
    if (via['erro'] == true) {
      throw Exception('CEP não encontrado no ViaCEP: $digits');
    }

    final logradouro = (via['logradouro'] as String? ?? '').trim();
    final bairro     = (via['bairro'] as String? ?? '').trim();
    final cidade     = (via['localidade'] as String? ?? '').trim();
    final uf         = (via['uf'] as String? ?? '').trim();

    // 2) Nominatim (tentar com filtros fortes primeiro)
    LatLng? pos;
    try {
      // Primeiro: busca por postalcode (param dedica­do) + cidade/UF
      final nomiUri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'format': 'jsonv2',
        'addressdetails': '1',
        'limit': '1',
        'countrycodes': 'br',
        'postalcode': digits,
        if (cidade.isNotEmpty) 'city': cidade,
        if (uf.isNotEmpty) 'state': uf,
        // Dica extra: se tiver logradouro, ajuda:
        if (logradouro.isNotEmpty) 'street': logradouro,
      });

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

      // fallback: busca por string “q”
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

        final nomiUri2 = Uri.https('nominatim.openstreetmap.org', '/search', {
          'format': 'jsonv2',
          'addressdetails': '1',
          'limit': '1',
          'countrycodes': 'br',
          'q': q,
        });

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
    } catch (_) {
      // mantém sem lat/lon — UI ainda se beneficia do endereço
    }

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


  // ===================== LOCALIZAÇÃO (SEM GOOGLE) =====================

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

    final data = json.decode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final addr = (data['address'] is Map) ? (data['address'] as Map).cast<String, dynamic>() : <String, dynamic>{};

    final road        = addr['road'] as String? ?? addr['pedestrian'] as String? ?? addr['path'] as String?;
    final houseNumber = addr['house_number'] as String?;
    final street      = [road, houseNumber].where((e) => e != null && e.toString().trim().isNotEmpty).join(', ');

    final subLocality = _firstNonEmpty([
      addr['suburb'] as String?,
      addr['neighbourhood'] as String?,
      addr['city_district'] as String?,
      addr['quarter'] as String?,
    ]);

    final city        = _firstNonEmpty([
      addr['city'] as String?,
      addr['town'] as String?,
      addr['village'] as String?,
      addr['municipality'] as String?,
      addr['county'] as String?,
    ]);

    final state       = addr['state'] as String? ?? '';
    final postcode    = addr['postcode'] as String? ?? '';
    final country     = addr['country'] as String? ?? '';
    final isoCountry  = (addr['country_code'] as String? ?? '').toUpperCase();

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

  /// Pega posição atual + reverse geocoding (Nominatim).
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

  /// Reverse geocoding a partir de coordenadas já conhecidas (ex.: do mapa).
  Future<AddressSuggestion> reverseGeocode({required double lat, required double lon}) async {
    try {
      return await _reverseGeocodeOSM(lat: lat, lon: lon, acceptLanguage: 'pt-BR');
    } catch (_) {
      return AddressSuggestion(latitude: lat, longitude: lon);
    }
  }
}
