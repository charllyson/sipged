// lib/_services/map/map_box/service/nominatim_repository.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'nominatim_data.dart';
import 'nominatim_service.dart';

class NominatimRepository {
  NominatimRepository({
    required NominatimService service,
    required String userAgent,
    FirebaseFirestore? firestore,
    String systemDocId = 'info',
    String reverseBaseUrl = 'https://nominatim.openstreetmap.org',
  })  : _service = service,
        _userAgent = userAgent,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _systemDocId = systemDocId,
        _reverseBaseUrl = reverseBaseUrl;

  final NominatimService _service;
  final String _userAgent;
  final FirebaseFirestore _firestore;
  final String _systemDocId;
  final String _reverseBaseUrl;

  LocationSettings _locationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration? timeLimit,
  }) {
    if (kIsWeb) {
      return WebSettings(
        accuracy: accuracy,
        timeLimit: timeLimit,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
          distanceFilter: 0,
          forceLocationManager: false,
        );

      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return AppleSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
        );

      default:
        return LocationSettings(
          accuracy: accuracy,
          timeLimit: timeLimit,
        );
    }
  }

  Future<Placemark?> getPlaceMarkAdapted(LatLng coords) async {
    if (kIsWeb) {
      final uri = Uri.parse('$_reverseBaseUrl/reverse').replace(
        queryParameters: {
          'lat': coords.latitude.toString(),
          'lon': coords.longitude.toString(),
          'format': 'jsonv2',
          'addressdetails': '1',
          'accept-language': 'pt-BR',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'User-Agent': _userAgent,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) return null;

      final decoded = jsonDecode(response.body);

      if (decoded is! Map) return null;

      final address = decoded['address'];

      if (address is! Map) return null;

      return Placemark(
        street: address['road']?.toString() ?? '',
        subLocality: address['suburb']?.toString() ??
            address['neighbourhood']?.toString() ??
            '',
        locality: address['city']?.toString() ??
            address['town']?.toString() ??
            address['village']?.toString() ??
            '',
        postalCode: address['postcode']?.toString() ?? '',
        administrativeArea: address['state']?.toString() ?? '',
        country: address['country']?.toString() ?? '',
        isoCountryCode:
        (address['country_code']?.toString() ?? '').toUpperCase(),
        subAdministrativeArea: address['county']?.toString() ?? '',
        thoroughfare: address['neighbourhood']?.toString() ?? '',
        subThoroughfare: '',
        name: decoded['name']?.toString() ??
            decoded['display_name']?.toString() ??
            '',
      );
    }

    final placeMarks = await placemarkFromCoordinates(
      coords.latitude,
      coords.longitude,
    );

    return placeMarks.isNotEmpty ? placeMarks.first : null;
  }

  Future<LatLng?> getCoordinates(String address) {
    return _service.geocode(address);
  }

  Future<List<NominatimData>> search(
      String query, {
        int limit = 6,
      }) {
    return _service.search(
      query,
      limit: limit,
    );
  }

  Future<LatLng?> getUserCurrentLocation() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    return LatLng(
      position.latitude,
      position.longitude,
    );
  }

  Future<int> getBuildNumber() async {
    final docSnapshot = await _firestore
        .collection('system')
        .doc(_systemDocId)
        .get();

    return (docSnapshot.data()?['buildNumber'] as num?)?.toInt() ?? 0;
  }
}