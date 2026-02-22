// lib/_blocs/modules/planning/geo/productive_units/energy_plants/energy_plants_state.dart
import 'package:latlong2/latlong.dart';

class EnergyPlantMarkerData {
  final String docId;
  final String uf;
  final String name;
  final String? code;
  final String? owner;
  final LatLng point;

  const EnergyPlantMarkerData({
    required this.docId,
    required this.uf,
    required this.name,
    required this.point,
    this.code,
    this.owner,
  });
}

class EnergyPlantsState {
  final bool isLoading;
  final String? errorMessage;
  final List<EnergyPlantMarkerData> markers;

  const EnergyPlantsState({
    this.isLoading = false,
    this.errorMessage,
    this.markers = const [],
  });

  EnergyPlantsState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<EnergyPlantMarkerData>? markers,
  }) {
    return EnergyPlantsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      markers: markers ?? this.markers,
    );
  }
}
