// lib/_services/map/map_box/service/nominatim_state.dart

import 'package:equatable/equatable.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import 'nominatim_data.dart';

class NominatimState extends Equatable {
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;

  final LatLng? currentLocation;
  final LatLng? selectedCoordinates;
  final Placemark? placemark;
  final int buildNumber;

  final List<NominatimData> suggestions;

  const NominatimState({
    this.isLoading = false,
    this.isSearching = false,
    this.errorMessage,
    this.currentLocation,
    this.selectedCoordinates,
    this.placemark,
    this.buildNumber = 0,
    this.suggestions = const <NominatimData>[],
  });

  factory NominatimState.initial() {
    return const NominatimState();
  }

  NominatimState copyWith({
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    bool clearErrorMessage = false,
    LatLng? currentLocation,
    bool clearCurrentLocation = false,
    LatLng? selectedCoordinates,
    bool clearSelectedCoordinates = false,
    Placemark? placemark,
    bool clearPlacemark = false,
    int? buildNumber,
    List<NominatimData>? suggestions,
  }) {
    return NominatimState(
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage:
      clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      currentLocation: clearCurrentLocation
          ? null
          : currentLocation ?? this.currentLocation,
      selectedCoordinates: clearSelectedCoordinates
          ? null
          : selectedCoordinates ?? this.selectedCoordinates,
      placemark: clearPlacemark ? null : placemark ?? this.placemark,
      buildNumber: buildNumber ?? this.buildNumber,
      suggestions: suggestions ?? this.suggestions,
    );
  }

  @override
  List<Object?> get props {
    return [
      isLoading,
      isSearching,
      errorMessage,
      currentLocation,
      selectedCoordinates,
      placemark,
      buildNumber,
      suggestions,
    ];
  }
}