import 'package:flutter_bloc/flutter_bloc.dart';
import 'land_notification_data.dart';
import 'land_notification_repository.dart';
import 'land_notification_state.dart';

class LandNotificationCubit extends Cubit<LandNotificationState> {
  LandNotificationCubit({
    required LandNotificationRepository repository,
  })  : _repository = repository,
        super(LandNotificationState.initial());

  final LandNotificationRepository _repository;

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
        contractId: contractId,
        propertyId: normalizedPropertyId,
        draft: LandNotificationData.empty(
          contractId: contractId,
          id: normalizedPropertyId,
        ),
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      if (normalizedPropertyId == null) {
        emit(
          state.copyWith(
            initialized: true,
            loading: false,
            propertyId: null,
            draft: LandNotificationData.empty(contractId: contractId),
          ),
        );
        return;
      }

      final data = await _repository.fetchById(
        contractId: contractId,
        propertyId: normalizedPropertyId,
      );

      emit(
        state.copyWith(
          initialized: true,
          loading: false,
          propertyId: normalizedPropertyId,
          draft: data ??
              LandNotificationData.empty(
                contractId: contractId,
                id: normalizedPropertyId,
              ),
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          initialized: true,
          loading: false,
          error: 'Erro ao carregar notificação: $e',
        ),
      );
    }
  }

  void updateDraft(LandNotificationData value) {
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
    final propertyId = _normalizeId(state.propertyId);

    if (propertyId == null) {
      emit(
        state.copyWith(
          error: 'Selecione ou salve um imóvel antes de salvar a notificação.',
          clearSuccessMessage: true,
        ),
      );
      return;
    }

    if (state.saving) return;

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
          id: propertyId,
          contractId: state.contractId,
          createdBy: state.draft.createdBy ?? userId,
          updatedBy: userId,
        ),
      );

      emit(
        state.copyWith(
          saving: false,
          propertyId: propertyId,
          draft: saved,
          successMessage: 'Notificação salva com sucesso.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: 'Erro ao salvar notificação: $e',
        ),
      );
    }
  }

  Future<void> delete() async {
    final propertyId = _normalizeId(state.propertyId);
    if (propertyId == null || state.saving) return;

    emit(
      state.copyWith(
        saving: true,
        clearError: true,
        clearSuccessMessage: true,
      ),
    );

    try {
      await _repository.delete(
        contractId: state.contractId,
        propertyId: propertyId,
      );

      emit(
        state.copyWith(
          saving: false,
          propertyId: propertyId,
          draft: LandNotificationData.empty(
            contractId: state.contractId,
            id: propertyId,
          ),
          successMessage: 'Notificação removida com sucesso.',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: 'Erro ao excluir notificação: $e',
        ),
      );
    }
  }

  String? _normalizeId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}