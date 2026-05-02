// lib/_blocs/system/notification/preferences/notification_preferences_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/notification_channel.dart';
import 'notification_preference_data.dart';
import 'notification_preferences_repository.dart';
import 'notification_preferences_state.dart';

class NotificationPreferencesCubit extends Cubit<NotificationPreferencesState> {
  NotificationPreferencesCubit({
    NotificationPreferencesRepository? repository,
  })  : _repository = repository ?? NotificationPreferencesRepository(),
        super(const NotificationPreferencesState());

  final NotificationPreferencesRepository _repository;

  StreamSubscription<List<NotificationPreferenceData>>? _sub;
  String? _watchingUserId;

  Future<void> initializeDefaults(String userId) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    try {
      await _repository.ensureDefaults(cleanUserId);
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Erro ao inicializar preferências de notificação: $e',
        ),
      );
    }
  }

  Future<void> load(String userId) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          items: const <NotificationPreferenceData>[],
          loading: false,
          clearError: true,
        ),
      );

      return;
    }

    try {
      emit(
        state.copyWith(
          loading: true,
          clearError: true,
        ),
      );

      await _repository.ensureDefaults(cleanUserId);

      final items = await _repository.getPreferences(cleanUserId);

      emit(
        state.copyWith(
          items: items,
          loading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Erro ao carregar preferências de notificação: $e',
        ),
      );
    }
  }

  void watch(String userId) {
    final cleanUserId = userId.trim();

    if (_watchingUserId == cleanUserId) return;

    _watchingUserId = cleanUserId;
    _sub?.cancel();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          items: const <NotificationPreferenceData>[],
          loading: false,
          clearError: true,
        ),
      );

      return;
    }

    emit(
      state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    unawaited(_repository.ensureDefaults(cleanUserId));

    _sub = _repository.watchPreferences(cleanUserId).listen(
          (items) {
        emit(
          state.copyWith(
            items: items,
            loading: false,
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Erro ao observar preferências de notificação: $e',
          ),
        );
      },
    );
  }

  Future<void> setSourceEnabled({
    required String userId,
    required NotificationPreferenceData preference,
    required bool enabled,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    try {
      emit(
        state.copyWith(
          saving: true,
          clearError: true,
        ),
      );

      await _repository.savePreference(
        userId: cleanUserId,
        preference: preference.copyWith(enabled: enabled),
      );

      emit(
        state.copyWith(
          saving: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: 'Erro ao salvar preferência: $e',
        ),
      );
    }
  }

  Future<void> setChannelEnabled({
    required String userId,
    required NotificationPreferenceData preference,
    required NotificationChannel channel,
    required bool enabled,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    try {
      emit(
        state.copyWith(
          saving: true,
          clearError: true,
        ),
      );

      await _repository.savePreference(
        userId: cleanUserId,
        preference: preference.toggleChannel(
          channel: channel,
          value: enabled,
        ),
      );

      emit(
        state.copyWith(
          saving: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          saving: false,
          error: 'Erro ao salvar canal de notificação: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}