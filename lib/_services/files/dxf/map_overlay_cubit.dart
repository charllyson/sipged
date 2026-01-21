import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

part 'map_overlay_state.dart';

class MapOverlayCubit extends Cubit<MapOverlayState> {
  MapOverlayCubit() : super(const MapOverlayState());

  void showDxfPolylines(List<List<LatLng>> lines) {
    emit(state.copyWith(dxfPolylines: lines));
  }

  void clearDxf() {
    emit(state.copyWith(dxfPolylines: const []));
  }
}
