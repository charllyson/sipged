import 'package:flutter_bloc/flutter_bloc.dart';
import 'land_map_repository.dart';
import 'land_map_state.dart';

class LandMapCubit extends Cubit<LandMapState> {
  LandMapCubit({
    required LandMapRepository repository,
  })  : _repository = repository,
        super(LandMapState.initial());

  final LandMapRepository _repository;

  Future<void> initialize(String contractId) async {
    emit(
      state.copyWith(
        loading: true,
        contractId: contractId,
        clearError: true,
      ),
    );

    try {
      final items = await _repository.fetchAll(contractId);

      emit(
        state.copyWith(
          initialized: true,
          loading: false,
          items: items,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Erro ao carregar mapa: $e',
        ),
      );
    }
  }

  Future<void> refresh() async {
    if (state.contractId.isEmpty) return;
    await initialize(state.contractId);
  }

  void selectProperty(String propertyId) {
    emit(state.copyWith(selectedPropertyId: propertyId));
  }

  void clearSelection() {
    emit(state.copyWith(selectedPropertyId: null));
  }
}