import 'package:flutter_bloc/flutter_bloc.dart';
import 'land_property_data.dart';
import 'land_property_repository.dart';
import 'land_property_state.dart';

class LandPropertyCubit extends Cubit<LandPropertyState> {
  LandPropertyCubit({
    required LandPropertyRepository repository,
  })  : _repository = repository,
        super(LandPropertyState.initial());

  final LandPropertyRepository _repository;

  Future<void> initialize({
    required String contractId,
    String? propertyId,
  }) async {
    final normalizedPropertyId = _normalizeId(propertyId);

    emit(
      state.copyWith(
        initialized: false,
        loading: true,
        saving: false,
        deleting: false,
        contractId: contractId,
        propertyId: normalizedPropertyId,
        draft: LandPropertyData.empty(
          contractId: contractId,
          id: normalizedPropertyId,
        ),
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final items = await _repository.fetchAll(contractId);

      LandPropertyData draft = LandPropertyData.empty(
        contractId: contractId,
        id: normalizedPropertyId,
      );

      if (normalizedPropertyId != null) {
        final loaded = await _repository.fetchById(
          contractId: contractId,
          propertyId: normalizedPropertyId,
        );
        if (loaded != null) {
          draft = loaded;
        }
      }

      emit(
        state.copyWith(
          initialized: true,
          loading: false,
          items: items,
          draft: draft,
          propertyId: draft.id,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          initialized: true,
          loading: false,
          error: 'Erro ao carregar imóvel: $e',
        ),
      );
    }
  }

  void updateDraft(LandPropertyData value) {
    emit(
      state.copyWith(
        draft: value,
        propertyId: _normalizeId(value.id) ?? state.propertyId,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
  }

  Future<void> save({String? userId}) async {
    if (state.saving || state.deleting) return;

    emit(
      state.copyWith(
        saving: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final saved = await _repository.save(
        state.draft.copyWith(
          contractId: state.contractId,
          createdBy: state.draft.createdBy ?? userId,
          updatedBy: userId,
        ),
      );

      final updatedItems = _upsertItem(state.items, saved);

      emit(
        state.copyWith(
          saving: false,
          propertyId: saved.id,
          items: updatedItems,
          draft: saved,
          successMessage: 'Imóvel salvo com sucesso.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: 'Erro ao salvar imóvel: $e',
        ),
      );
    }
  }

  Future<void> delete() async {
    final propertyId = _normalizeId(state.propertyId);
    if (propertyId == null || state.deleting || state.saving) return;

    emit(
      state.copyWith(
        deleting: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await _repository.delete(
        contractId: state.contractId,
        propertyId: propertyId,
      );

      final updatedItems =
      state.items.where((item) => item.id != propertyId).toList(growable: false);

      emit(
        state.copyWith(
          deleting: false,
          propertyId: null,
          items: updatedItems,
          draft: LandPropertyData.empty(contractId: state.contractId),
          successMessage: 'Imóvel removido com sucesso.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          deleting: false,
          error: 'Erro ao excluir imóvel: $e',
        ),
      );
    }
  }

  Future<void> selectProperty(String propertyId) async {
    final normalizedPropertyId = _normalizeId(propertyId);
    if (normalizedPropertyId == null || state.loading || state.saving || state.deleting) {
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final data = await _repository.fetchById(
        contractId: state.contractId,
        propertyId: normalizedPropertyId,
      );

      emit(
        state.copyWith(
          loading: false,
          propertyId: normalizedPropertyId,
          draft: data ??
              LandPropertyData.empty(
                contractId: state.contractId,
                id: normalizedPropertyId,
              ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Erro ao selecionar imóvel: $e',
        ),
      );
    }
  }

  void clearMessages() {
    emit(
      state.copyWith(
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
  }

  List<LandPropertyData> _upsertItem(
      List<LandPropertyData> items,
      LandPropertyData saved,
      ) {
    final index = items.indexWhere((item) => item.id == saved.id);
    if (index == -1) {
      return [...items, saved];
    }

    final updated = List<LandPropertyData>.from(items);
    updated[index] = saved;
    return updated;
  }

  String? _normalizeId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}