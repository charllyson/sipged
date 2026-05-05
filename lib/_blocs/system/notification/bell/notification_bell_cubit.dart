// lib/_blocs/system/notification/bell/notification_bell_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:sipged/_blocs/system/notification/notification_data.dart';
import 'package:sipged/_blocs/system/notification/remote/notification_remote_repository.dart';

import 'notification_bell_state.dart';

class NotificationBellCubit extends Cubit<NotificationBellState> {
  NotificationBellCubit({
    required NotificationRemoteRepository repository,
  })  : _repository = repository,
        super(const NotificationBellState());

  final NotificationRemoteRepository _repository;

  StreamSubscription<List<NotificationData>>? _systemSub;
  StreamSubscription<List<NotificationData>>? _userBellSub;
  StreamSubscription<List<NotificationData>>? _unreadUserSub;

  String? _watchingUserId;

  void watchBellNotifications({
    required String userId,
    int systemLimit = 30,
    int userBellLimit = 50,
    int unreadUserLimit = 50,
  }) {
    watchSystemNotifications(limit: systemLimit);

    final cleanUserId = userId.trim();

    if (_watchingUserId == cleanUserId) return;

    _watchingUserId = cleanUserId;

    _userBellSub?.cancel();
    _userBellSub = null;

    _unreadUserSub?.cancel();
    _unreadUserSub = null;

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          userBellNotifications: const <NotificationData>[],
          unreadUserNotifications: const <NotificationData>[],
          loading: false,
          clearError: true,
        ),
      );

      return;
    }

    watchUserBellNotifications(
      userId: cleanUserId,
      limit: userBellLimit,
    );

    watchUnreadUserNotifications(
      userId: cleanUserId,
      limit: unreadUserLimit,
    );
  }

  void watchSystemNotifications({
    int limit = 30,
  }) {
    _systemSub?.cancel();

    emit(
      state.copyWith(
        loading: true,
        clearError: true,
      ),
    );

    _systemSub = _repository.watchSystemNotifications(limit: limit).listen(
          (items) {
        emit(
          state.copyWith(
            systemNotifications: items,
            loading: false,
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Erro ao observar notificações do sistema: $e',
          ),
        );
      },
    );
  }

  void watchUserBellNotifications({
    required String userId,
    int limit = 50,
  }) {
    final cleanUserId = userId.trim();

    _userBellSub?.cancel();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          userBellNotifications: const <NotificationData>[],
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

    _userBellSub = _repository
        .watchUserNotifications(
      userId: cleanUserId,
      limit: limit,
    )
        .listen(
          (items) {
        emit(
          state.copyWith(
            userBellNotifications: items,
            loading: false,
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Erro ao observar notificações do usuário: $e',
          ),
        );
      },
    );
  }

  void watchUnreadUserNotifications({
    required String userId,
    int limit = 50,
  }) {
    final cleanUserId = userId.trim();

    _unreadUserSub?.cancel();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          unreadUserNotifications: const <NotificationData>[],
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

    _unreadUserSub = _repository
        .watchUnreadUserNotifications(
      userId: cleanUserId,
      limit: limit,
    )
        .listen(
          (items) {
        emit(
          state.copyWith(
            unreadUserNotifications: items,
            loading: false,
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Erro ao observar notificações não vistas: $e',
          ),
        );
      },
    );
  }

  Future<void> markAsSeen({
    required String userId,
    required String notificationId,
  }) async {
    final cleanUserId = userId.trim();
    final cleanNotificationId = notificationId.trim();

    if (cleanUserId.isEmpty || cleanNotificationId.isEmpty) return;

    try {
      await _repository.markAsSeen(
        userId: cleanUserId,
        notificationId: cleanNotificationId,
      );

      final unread = state.unreadUserNotifications
          .where((item) => item.id != cleanNotificationId)
          .toList();

      final userBell = state.userBellNotifications.map((item) {
        if (item.id == cleanNotificationId) {
          return item.copyWith(seen: true);
        }

        return item;
      }).toList();

      emit(
        state.copyWith(
          userBellNotifications: userBell,
          unreadUserNotifications: unread,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Erro ao marcar notificação como vista: $e',
        ),
      );
    }
  }

  Future<void> markAllAsSeen({
    required String userId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    try {
      await _repository.markAllAsSeen(userId: cleanUserId);

      final userBell = state.userBellNotifications.map((item) {
        return item.copyWith(seen: true);
      }).toList();

      emit(
        state.copyWith(
          userBellNotifications: userBell,
          unreadUserNotifications: const <NotificationData>[],
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Erro ao marcar todas as notificações como vistas: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _systemSub?.cancel();
    _userBellSub?.cancel();
    _unreadUserSub?.cancel();

    return super.close();
  }
}