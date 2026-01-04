import 'package:flutter_bloc/flutter_bloc.dart';

import 'ana_pluviometric_series_state.dart';
import 'ana_hidroweb_repository.dart';

class AnaPluviometricSeriesCubit extends Cubit<AnaPluviometricSeriesState> {
  final AnaHidrowebRepository _repo;

  AnaPluviometricSeriesCubit({
    required String codigoEstacao,
    required String stationName,
    AnaHidrowebRepository? repository,
  })  : _repo = repository ?? AnaHidrowebRepository(),
        super(
        AnaPluviometricSeriesState(
          codigoEstacao: codigoEstacao,
          stationName: stationName,
        ),
      );

  /// Agora carrega séries **telemétricas** (HidroinfoanaSerieTelemetricaAdotada)
  /// em vez de HIDROSerieChuva histórica.
  ///
  /// [daysBack] controla o intervalo aproximado (2,7,14,21,30 dias).
  Future<void> loadAllHistoric({int daysBack = 7}) async {
    emit(
      state.copyWith(
        status: AnaPluviometricSeriesStatus.loading,
        error: null,
        series: [],
      ),
    );

    try {
      final list = await _repo.getTelemetricPluviometricSeries(
        codigoEstacao: state.codigoEstacao,
        daysBack: daysBack,
      );

      emit(
        state.copyWith(
          status: AnaPluviometricSeriesStatus.success,
          series: list,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: AnaPluviometricSeriesStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }
}
