part of 'map_overlay_cubit.dart';

class MapOverlayState extends Equatable {
  final List<List<LatLng>> dxfPolylines;

  const MapOverlayState({this.dxfPolylines = const []});

  MapOverlayState copyWith({
    List<List<LatLng>>? dxfPolylines,
  }) => MapOverlayState(
    dxfPolylines: dxfPolylines ?? this.dxfPolylines,
  );

  @override
  List<Object?> get props => [dxfPolylines];
}
