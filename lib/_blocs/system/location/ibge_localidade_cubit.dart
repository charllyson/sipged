import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/location/ibge_localidade_data.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_repository.dart';
import 'package:sipged/_blocs/system/location/ibge_localidade_state.dart';

class IBGELocationCubit extends Cubit<IBGELocationState> {
  final IBGELocationRepository _repo;

  IBGELocationCubit({IBGELocationRepository? repository})
      : _repo = repository ?? IBGELocationRepository(),
        super(IBGELocationState.initial());

  // ===========================================================================
  // 1) MODO "ANTIGO" – compatibilidade
  // ===========================================================================
  Future<void> loadInitial({int? initialUfCode}) async {
    await loadInitialAuto(fallbackUfCode: initialUfCode);
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
      if (states.isEmpty) {
        emit(
          state.copyWith(
            isLoading: false,
            states: const [],
            selectedState: null,
            cityPolygons: const [],
            errorMessage: 'Nenhum estado retornado pelo IBGE/Proxy.',
          ),
        );
        return;
      }

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

      // fallback final
      selected ??= states.first;

      emit(
        state.copyWith(
          isLoading: false,
          states: states,
          selectedState: selected,
        ),
      );

      await loadPolygonsForState(selected);
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

    emit(
      state.copyWith(
        isLoading: !hasCache,
        selectedState: stateData,
        clearError: true,
        clearMunicipioDetail: true,
      ),
    );

    try {
      final polys = await _repo.getMunicipioPolygonsByUf(stateData.id);

      emit(
        state.copyWith(
          isLoading: false,
          cityPolygons: polys,
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[IBGELocationCubit] Erro loadPolygonsForState: $e');
      }
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
