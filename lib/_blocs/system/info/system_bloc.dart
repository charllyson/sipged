import 'dart:convert';

import 'package:bloc_pattern/bloc_pattern.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class SystemBloc extends BlocBase {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> organList = [];
  List<Map<String, dynamic>> directorsList = [];
  List<Map<String, dynamic>> sectorList = [];
  bool isLoading = true;
  final String _docId = 'info'; // ID fixo do documento


  double calcularLarguraDinamica(
      int quantidadeMedicoes, {
        double larguraPorPonto = 60,
        double larguraMinima = 300,
      }) {
    return (quantidadeMedicoes * larguraPorPonto).clamp(
      larguraMinima,
      2000,
    ); // máximo opcional
  }


  Future<Placemark?> getPlaceMarkAdapted(LatLng coords) async {
    try {
      if (kIsWeb) {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?lat=${coords.latitude}&lon=${coords.longitude}&format=json&accept-language=pt-BR',
        );
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final address = data['suggestions'];

          return Placemark(
            street: address['road'] ?? '',
            subLocality: address['suburb'] ?? '',
            locality: address['city'] ?? address['town'] ?? address['village'] ?? '',
            postalCode: address['postcode'] ?? '',
            administrativeArea: address['state'] ?? '',
            country: address['country'] ?? '',
            isoCountryCode: (address['country_code'] ?? '').toUpperCase(),
            subAdministrativeArea: address['county'] ?? '',
            thoroughfare: address['neighbourhood'] ?? '',
            subThoroughfare: '',
            name: data['name'] ?? '',
          );
        } else {
          debugPrint('Erro Nominatim: ${response.statusCode}');
        }
      } else {
        final placeMarks = await placemarkFromCoordinates(
          coords.latitude,
          coords.longitude,
        );
        return placeMarks.isNotEmpty ? placeMarks.first : null;
      }
    } catch (e) {
      debugPrint('Erro ao buscar placemark: $e');
    }

    return null;
  }


  Future<LatLng?> getCoordinates(String address) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.tryParse(data[0]['lat']);
        final lon = double.tryParse(data[0]['lon']);
        if (lat != null && lon != null) {
          return LatLng(lat, lon);
        }
      }
    }

    return null;
  }

  Future<LatLng?> getUserCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Serviço de localização desativado');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Permissão negada');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Permissão permanentemente negada');
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      return null;
    }
  }

  Future<int> getBuildNumber() async {
    final docSnapshot = await _firestore.collection('system').doc(_docId).get();
    return docSnapshot.data()?['buildNumber'] ?? 0;
  }

}
