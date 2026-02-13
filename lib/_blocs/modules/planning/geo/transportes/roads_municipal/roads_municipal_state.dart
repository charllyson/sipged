// lib/_blocs/modules/planning/geo/transportes/roads_municipal/roads_municipal_state.dart
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class RoadsMunicipalState {
  final bool isLoading;
  final String? errorMessage;
  final List<TappableChangedPolyline> polylines;

  const RoadsMunicipalState({
    this.isLoading = false,
    this.errorMessage,
    this.polylines = const [],
  });

  RoadsMunicipalState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TappableChangedPolyline>? polylines,
  }) {
    return RoadsMunicipalState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      polylines: polylines ?? this.polylines,
    );
  }
}
