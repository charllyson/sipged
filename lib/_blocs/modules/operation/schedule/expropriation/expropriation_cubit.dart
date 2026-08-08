import 'package:flutter_bloc/flutter_bloc.dart';

import 'expropriation_data.dart';
import 'expropriation_repository.dart';
import 'expropriation_state.dart';

class ExpropriationCubit extends Cubit<ExpropriationState> {
  ExpropriationCubit({
    required this._repository,
  })  : super(ExpropriationState.initial());

  final ExpropriationRepository _repository;

  Future<void> initialize({
    required String contractId,
    String? propertyId,
  }) async {
    final cleanContractId = _normalizeRequiredId(
      contractId,
      fieldName: 'contractId',
    );

    final normalizedPropertyId = _normalizeId(propertyId);

    emit(
      state.copyWith(
        initialized: false,
        loading: true,
        saving: false,
        deleting: false,
        contractId: cleanContractId,
        propertyId: normalizedPropertyId,
        draft: ExpropriationData.empty(
          contractId: cleanContractId,
          id: normalizedPropertyId,
        ),
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      final items = await _repository.fetchAll(cleanContractId);

      ExpropriationData draft = ExpropriationData.empty(
        contractId: cleanContractId,
        id: normalizedPropertyId,
      );

      if (normalizedPropertyId != null) {
        final loaded = await _repository.fetchById(
          contractId: cleanContractId,
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
          contractId: cleanContractId,
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

  void updateDraft(ExpropriationData value) {
    emit(
      state.copyWith(
        draft: value.copyWith(
          contractId: state.contractId,
          id: _normalizeId(value.id) ?? state.propertyId,
        ),
        propertyId: _normalizeId(value.id) ?? state.propertyId,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );
  }

  Future<void> save({String? userId}) async {
    final contractId = _normalizeId(state.contractId);

    if (contractId == null) {
      emit(
        state.copyWith(
          error: 'Contrato inválido para salvar o imóvel.',
          clearSuccessMessage: true,
        ),
      );
      return;
    }

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
          contractId: contractId,
          createdBy: state.draft.createdBy ?? userId,
          updatedBy: userId,
        ),
      );

      final updatedItems = _upsertItem(state.items, saved);

      emit(
        state.copyWith(
          saving: false,
          contractId: contractId,
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
    final contractId = _normalizeId(state.contractId);
    final propertyId = _normalizeId(state.propertyId);

    if (contractId == null || propertyId == null || state.deleting || state.saving) {
      return;
    }

    emit(
      state.copyWith(
        deleting: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await _repository.delete(
        contractId: contractId,
        propertyId: propertyId,
      );

      final updatedItems = state.items
          .where((item) => item.id != propertyId)
          .toList(growable: false);

      emit(
        state.copyWith(
          deleting: false,
          contractId: contractId,
          propertyId: null,
          items: updatedItems,
          draft: ExpropriationData.empty(contractId: contractId),
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
    final contractId = _normalizeId(state.contractId);
    final normalizedPropertyId = _normalizeId(propertyId);

    if (contractId == null ||
        normalizedPropertyId == null ||
        state.loading ||
        state.saving ||
        state.deleting) {
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
        contractId: contractId,
        propertyId: normalizedPropertyId,
      );

      emit(
        state.copyWith(
          loading: false,
          contractId: contractId,
          propertyId: normalizedPropertyId,
          draft: data ??
              ExpropriationData.empty(
                contractId: contractId,
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

  List<ExpropriationData> _upsertItem(
      List<ExpropriationData> items,
      ExpropriationData saved,
      ) {
    final index = items.indexWhere((item) => item.id == saved.id);

    if (index == -1) {
      return [...items, saved];
    }

    final updated = List<ExpropriationData>.from(items);
    updated[index] = saved;

    return updated;
  }

  String _normalizeRequiredId(
      String value, {
        required String fieldName,
      }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      throw ArgumentError('$fieldName é obrigatório.');
    }

    return trimmed;
  }

  String? _normalizeId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}