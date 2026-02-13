// lib/_blocs/modules/planning/geo/transportes/railways/railways_state.dart
import 'package:sipged/_widgets/map/polylines/tappable_changed_polyline.dart';

class RailwaysState {
  final bool isLoading;
  final String? errorMessage;
  final List<TappableChangedPolyline> polylines;

  const RailwaysState({
    this.isLoading = false,
    this.errorMessage,
    this.polylines = const [],
  });

  RailwaysState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<TappableChangedPolyline>? polylines,
  }) {
    return RailwaysState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      polylines: polylines ?? this.polylines,
    );
  }
}
