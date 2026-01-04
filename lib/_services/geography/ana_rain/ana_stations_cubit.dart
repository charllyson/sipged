import 'package:flutter_bloc/flutter_bloc.dart';

import 'ana_stations_state.dart';
import 'ana_hidroweb_repository.dart';
import 'ana_station_data.dart';

class AnaStationsCubit extends Cubit<AnaStationsState> {
  final AnaHidrowebRepository _repo;

  AnaStationsCubit({
    required String stationType,
    AnaHidrowebRepository? repository,
    String initialUf = 'AL',
  })  : _repo = repository ?? AnaHidrowebRepository(),
        super(
        AnaStationsState(
          stationType: stationType,
          uf: initialUf,
        ),
      );

  Future<void> loadStations() async {
    emit(
      state.copyWith(
        status: AnaStationsStatus.loading,
        error: null,
        stations: [],
        selectedStation: null,
      ),
    );

    try {
      final list = await _repo.getStationsByUf(
        uf: state.uf,
        stationType: state.stationType,
      );

      emit(
        state.copyWith(
          status: AnaStationsStatus.success,
          stations: list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AnaStationsStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  void changeUf(String uf) {
    emit(state.copyWith(uf: uf));
    loadStations();
  }

  void selectStation(AnaStationData station) {
    emit(state.copyWith(selectedStation: station));
  }
}
