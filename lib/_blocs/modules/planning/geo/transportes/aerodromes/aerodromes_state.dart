import 'package:latlong2/latlong.dart';

class AerodromeMarkerData {
  final String docId;
  final String uf;
  final String name;
  final String? code;
  final String? owner;
  final LatLng point;

  const AerodromeMarkerData({
    required this.docId,
    required this.uf,
    required this.name,
    required this.point,
    this.code,
    this.owner,
  });
}

class AerodromesState {
  final bool isLoading;
  final String? errorMessage;
  final List<AerodromeMarkerData> markers;

  const AerodromesState({
    this.isLoading = false,
    this.errorMessage,
    this.markers = const [],
  });

  AerodromesState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<AerodromeMarkerData>? markers,
  }) {
    return AerodromesState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      markers: markers ?? this.markers,
    );
  }
}
