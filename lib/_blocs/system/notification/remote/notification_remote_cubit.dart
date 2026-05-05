import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../notification_data.dart';
import 'notification_remote_state.dart';
import 'notification_remote_repository.dart';

class NotificationRemoteCubit extends Cubit<NotificationRemoteState> {
  NotificationRemoteCubit({
    NotificationRemoteRepository? repository,
  })  : _repository = repository ?? NotificationRemoteRepository(),
        super(const NotificationRemoteState());

  final NotificationRemoteRepository _repository;

  StreamSubscription<List<NotificationData>>? _historySub;
  StreamSubscription<List<NotificationData>>? _systemSub;
  StreamSubscription<List<NotificationData>>? _userBellSub;
  StreamSubscription<List<NotificationData>>? _unreadUserSub;

  Future<void> registerPushToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    final cleanUserId = userId.trim();
    final cleanToken = token.trim();
    final cleanPlatform = platform.trim();

    if (cleanUserId.isEmpty || cleanToken.isEmpty) return;

    try {
      await _repository.savePushToken(
        userId: cleanUserId,
        token: cleanToken,
        platform: cleanPlatform.isEmpty ? 'unknown' : cleanPlatform,
      );

      emit(
        state.copyWith(
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Erro ao registrar token remoto: $e',
        ),
      );
    }
  }

  Future<void> removeCurrentPushToken({
    required String userId,
    required String token,
    String reason = 'disabled-by-client',
  }) async {
    final cleanUserId = userId.trim();
    final cleanToken = token.trim();

    if (cleanUserId.isEmpty || cleanToken.isEmpty) return;

    try {
      await _repository.disablePushToken(
        userId: cleanUserId,
        token: cleanToken,
        reason: reason,
      );

      emit(
        state.copyWith(
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Erro ao remover token remoto: $e',
        ),
      );
    }
  }

  Future<void> sendToUser({
    required String userId,
    required NotificationData data,
    bool sendPush = false,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    try {
      emit(
        state.copyWith(
          sending: true,
          clearError: true,
        ),
      );

      await _repository.createUserNotification(
        userId: cleanUserId,
        data: data,
        sendPush: sendPush,
      );

      emit(
        state.copyWith(
          sending: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          sending: false,
          error: 'Erro ao enviar notificação remota: $e',
        ),
      );
    }
  }

  Future<void> sendToUsers({
    required Iterable<String> userIds,
    required NotificationData data,
    bool sendPush = false,
  }) async {
    final cleanUserIds = userIds
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList();

    if (cleanUserIds.isEmpty) return;

    try {
      emit(
        state.copyWith(
          sending: true,
          clearError: true,
        ),
      );

      await _repository.createUserNotifications(
        userIds: cleanUserIds,
        data: data,
        sendPush: sendPush,
      );

      emit(
        state.copyWith(
          sending: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          sending: false,
          error: 'Erro ao enviar notificações remotas: $e',
        ),
      );
    }
  }

  Future<void> sendGlobal({
    required NotificationData data,
    bool sendPush = false,
  }) async {
    try {
      emit(
        state.copyWith(
          sending: true,
          clearError: true,
        ),
      );

      await _repository.createGlobalNotification(
        data: data,
        sendPush: sendPush,
      );

      emit(
        state.copyWith(
          sending: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          sending: false,
          error: 'Erro ao enviar notificação global: $e',
        ),
      );
    }
  }

  void watchBellNotifications({
    required String userId,
    int systemLimit = 30,
    int userBellLimit = 30,
    int unreadUserLimit = 30,
  }) {
    watchSystemNotifications(limit: systemLimit);

    final cleanUserId = userId.trim();

    _userBellSub?.cancel();
    _unreadUserSub?.cancel();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          userBellNotifications: const <NotificationData>[],
          unreadUserNotifications: const <NotificationData>[],
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

    _systemSub = _repository.watchSystemNotifications(limit: limit).listen(
          (items) {
        emit(
          state.copyWith(
            systemNotifications: items,
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            error: 'Erro ao observar notificações do sistema: $e',
          ),
        );
      },
    );
  }

  void watchUserBellNotifications({
    required String userId,
    int limit = 30,
  }) {
    final cleanUserId = userId.trim();

    _userBellSub?.cancel();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          userBellNotifications: const <NotificationData>[],
          clearError: true,
        ),
      );
      return;
    }

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
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            error: 'Erro ao observar notificações do usuário: $e',
          ),
        );
      },
    );
  }

  void watchUnreadUserNotifications({
    required String userId,
    int limit = 30,
  }) {
    final cleanUserId = userId.trim();

    _unreadUserSub?.cancel();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          unreadUserNotifications: const <NotificationData>[],
          clearError: true,
        ),
      );
      return;
    }

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
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            error: 'Erro ao observar notificações não vistas: $e',
          ),
        );
      },
    );
  }

  Future<void> loadHistory({
    required String userId,
    int limit = 50,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          history: const <NotificationData>[],
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

      final history = await _repository.getUserNotifications(
        userId: cleanUserId,
        limit: limit,
      );

      emit(
        state.copyWith(
          history: history,
          loading: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loading: false,
          error: 'Erro ao carregar notificações: $e',
        ),
      );
    }
  }

  void watchHistory({
    required String userId,
    int limit = 50,
  }) {
    final cleanUserId = userId.trim();

    _historySub?.cancel();

    if (cleanUserId.isEmpty) {
      emit(
        state.copyWith(
          history: const <NotificationData>[],
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

    _historySub = _repository
        .watchUserNotifications(
      userId: cleanUserId,
      limit: limit,
    )
        .listen(
          (history) {
        emit(
          state.copyWith(
            history: history,
            loading: false,
            clearError: true,
          ),
        );
      },
      onError: (Object e) {
        emit(
          state.copyWith(
            loading: false,
            error: 'Erro ao observar notificações: $e',
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

      final history = state.history.map((item) {
        if (item.id == cleanNotificationId) {
          return item.copyWith(seen: true);
        }

        return item;
      }).toList();

      final userBell = state.userBellNotifications.map((item) {
        if (item.id == cleanNotificationId) {
          return item.copyWith(seen: true);
        }

        return item;
      }).toList();

      final unread = state.unreadUserNotifications
          .where((item) => item.id != cleanNotificationId)
          .toList();

      emit(
        state.copyWith(
          history: history,
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

      final history = state.history.map((item) {
        return item.copyWith(seen: true);
      }).toList();

      final userBell = state.userBellNotifications.map((item) {
        return item.copyWith(seen: true);
      }).toList();

      emit(
        state.copyWith(
          history: history,
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

  Future<void> deleteNotification({
    required String userId,
    required String notificationId,
  }) async {
    final cleanUserId = userId.trim();
    final cleanNotificationId = notificationId.trim();

    if (cleanUserId.isEmpty || cleanNotificationId.isEmpty) return;

    try {
      await _repository.deleteUserNotification(
        userId: cleanUserId,
        notificationId: cleanNotificationId,
      );

      final history = state.history
          .where((item) => item.id != cleanNotificationId)
          .toList();

      final userBell = state.userBellNotifications
          .where((item) => item.id != cleanNotificationId)
          .toList();

      final unread = state.unreadUserNotifications
          .where((item) => item.id != cleanNotificationId)
          .toList();

      emit(
        state.copyWith(
          history: history,
          userBellNotifications: userBell,
          unreadUserNotifications: unread,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Erro ao excluir notificação: $e',
        ),
      );
    }
  }

  Future<void> clearHistory({
    required String userId,
  }) async {
    final cleanUserId = userId.trim();

    if (cleanUserId.isEmpty) return;

    try {
      await _repository.clearUserNotifications(userId: cleanUserId);

      emit(
        state.copyWith(
          history: const <NotificationData>[],
          userBellNotifications: const <NotificationData>[],
          unreadUserNotifications: const <NotificationData>[],
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          error: 'Erro ao limpar notificações: $e',
        ),
      );
    }
  }

  @override
  Future<void> close() {
    _historySub?.cancel();
    _systemSub?.cancel();
    _userBellSub?.cancel();
    _unreadUserSub?.cancel();

    return super.close();
  }
}