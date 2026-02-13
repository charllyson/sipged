import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class RoadsFederalState {
  final bool isLoading;
  final String? errorMessage;
  final List<TappableChangedPolyline> polylines;

  const RoadsFederalState({
    this.isLoading = false,
    this.errorMessage,
    this.polylines = const [],
  });

  RoadsFederalState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TappableChangedPolyline>? polylines,
  }) {
    return RoadsFederalState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      polylines: polylines ?? this.polylines,
    );
  }
}
