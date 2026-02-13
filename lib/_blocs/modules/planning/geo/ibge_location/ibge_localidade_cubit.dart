// lib/_blocs/ibge/geo/ibge_localidade_cubit.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_data.dart';
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_repository.dart';
import 'package:sipged/_blocs/modules/planning/geo/ibge_location/ibge_localidade_state.dart';

class IBGELocationCubit extends Cubit<IBGELocationState> {
  final IBGELocationRepository _repo;

  IBGELocationCubit({IBGELocationRepository? repository})
      : _repo = repository ?? IBGELocationRepository(),
        super(IBGELocationState.initial());

  // ===========================================================================
  // 1) MODO "ANTIGO" – compatibilidade
  // ===========================================================================
  Future<void> loadInitial({int? initialUfCode}) async {
    await loadInitialAuto(
      fallbackUfCode: initialUfCode,
    );
  }

  // ===========================================================================
  // 2) NOVO MODO – AUTO
  // ===========================================================================
  Future<void> loadInitialAuto({
    List<String>? municipioNames,
    String? ufSiglaHint,
    int? fallbackUfCode,
  }) async {
    try {
      emit(state.copyWith(isLoading: true, clearError: true));

      final states = await _repo.getStates();

      IBGELocationStateData? selected;

      // 1) Tenta pela sigla da UF
      if (ufSiglaHint != null && ufSiglaHint.trim().isNotEmpty) {
        final sigla = ufSiglaHint.trim().toUpperCase();
        selected = states.firstWhere(
              (s) => s.sigla.toUpperCase() == sigla,
          orElse: () => states.first,
        );
      }
      // 2) Tenta pelo código (fallback)
      else if (fallbackUfCode != null) {
        selected = states.firstWhere(
              (s) => s.id == fallbackUfCode,
          orElse: () => states.first,
        );
      }
      // 3) Tenta inferir pela lista de municípios
      else if (municipioNames != null && municipioNames.isNotEmpty) {
        final ufId = await _repo.inferUfFromMunicipios(municipioNames);

        if (ufId != null) {
          selected = states.firstWhere(
                (s) => s.id == ufId,
            orElse: () => states.first,
          );
        }
      }

      emit(
        state.copyWith(
          isLoading: false,
          states: states,
          selectedState: selected,
        ),
      );

      if (selected != null) {
        await loadPolygonsForState(selected);
      } else {
        if (kDebugMode) {

        }
      }
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ===========================================================================
  // 3) Carrega polígonos para um estado selecionado
  // ===========================================================================
  Future<void> loadPolygonsForState(IBGELocationStateData stateData) async {
    final hasCache = _repo.hasCachedPolygons(stateData.id);

    if (!hasCache) {
      emit(
        state.copyWith(
          isLoading: true,
          selectedState: stateData,
          clearError: true,
          clearMunicipioDetail: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedState: stateData,
          clearError: true,
          clearMunicipioDetail: true,
        ),
      );
    }

    try {
      final polys = await _repo.getMunicipioPolygonsByUf(stateData.id);

      emit(
        state.copyWith(
          isLoading: false,
          cityPolygons: polys,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // ===========================================================================
  // 4) Chamado quando usuário muda o estado NO DROPDOWN por ID
  // ===========================================================================
  Future<void> changeSelectedState(int ufId) async {
    if (state.states.isEmpty) return;

    final st = state.states.firstWhere(
          (s) => s.id == ufId,
      orElse: () => state.states.first,
    );
    await loadPolygonsForState(st);
  }

  // ===========================================================================
  // 5) Helper por SIGLA (para telas que só conhecem "AL", "RO"...)
  // ===========================================================================
  Future<void> changeSelectedStateBySigla(String ufSigla) async {
    final sigla = ufSigla.trim().toUpperCase();

    if (state.states.isEmpty) {
      await loadInitialAuto(ufSiglaHint: sigla);
      return;
    }

    final st = state.states.firstWhere(
          (s) => s.sigla.toUpperCase() == sigla,
      orElse: () => state.states.first,
    );

    await loadPolygonsForState(st);
  }

  // ===========================================================================
  // 6) DETALHE DE MUNICÍPIO – para o painel tipo OresDetails
  // ===========================================================================
  Future<void> openMunicipioDetailsById(String idIbge) async {
    // evita reload desnecessário se já estiver no mesmo município
    if (state.selectedMunicipioDetail?.idIbge == idIbge &&
        !state.isLoadingMunicipioDetail) {
      return;
    }

    emit(
      state.copyWith(
        isLoadingMunicipioDetail: true,
        clearError: true,
      ),
    );

    try {
      final detail = await _repo.getMunicipioDetails(idIbge);

      emit(
        state.copyWith(
          isLoadingMunicipioDetail: false,
          selectedMunicipioDetail: detail,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMunicipioDetail: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void closeMunicipioDetails() {
    emit(
      state.copyWith(
        clearMunicipioDetail: true,
      ),
    );
  }
}
