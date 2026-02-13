import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class RoadsStateState {
  final bool isLoading;
  final String? errorMessage;
  final List<TappableChangedPolyline> polylines;

  const RoadsStateState({
    this.isLoading = false,
    this.errorMessage,
    this.polylines = const [],
  });

  RoadsStateState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TappableChangedPolyline>? polylines,
  }) {
    return RoadsStateState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      polylines: polylines ?? this.polylines,
    );
  }
}
