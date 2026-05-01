import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'notification_data.dart';
import 'notification_repository.dart';
import 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit({
    NotificationRepository? repository,
    int maxVisible = 4,
  })  : _repository = repository ?? NotificationRepository(),
        super(NotificationState(maxVisible: maxVisible));

  final NotificationRepository _repository;

  final Map<String, Timer> _timers = <String, Timer>{};

  StreamSubscription<List<NotificationData>>? _historySub;
  StreamSubscription<List<NotificationData>>? _systemSub;
  StreamSubscription<List<NotificationData>>? _unreadUserSub;

  int _localCounter = 0;

  String _nextLocalId() {
    _localCounter++;
    return 'local_notification_$_localCounter';
  }

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
          error: 'Erro ao registrar token remote: $e',
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
          error: 'Erro ao remover token remote: $e',
        ),
      );
    }
  }

  Future<void> show(
      NotificationData data, {
        String? userId,
        bool saveInFirebase = false,
        bool sendPush = false,
      }) async {
    final resolvedId = data.id ?? _nextLocalId();

    final notification = data.copyWith(
      id: resolvedId,
      createdAt: data.createdAt ?? DateTime.now(),
      sendPush: sendPush || data.sendPush,
    );

    if (saveInFirebase || notification.persistInFirebase) {
      final cleanUserId = userId?.trim();

      if (cleanUserId != null && cleanUserId.isNotEmpty) {
        await _repository.createUserNotification(
          userId: cleanUserId,
          data: notification,
          sendPush: sendPush || notification.sendPush,
        );
      } else {
        await _repository.createGlobalNotification(
          data: notification,
        );
      }
    }

    _showLocal(notification);
  }

  Future<void> showToUsers(
      NotificationData data, {
        required Iterable<String> userIds,
        bool alsoShowLocalToast = true,
        bool sendPush = false,
      }) async {
    final cleanUserIds = userIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    if (cleanUserIds.isEmpty) {
      if (alsoShowLocalToast) {
        final localNotification = data.copyWith(
          id: data.id ?? _nextLocalId(),
          createdAt: data.createdAt ?? DateTime.now(),
          sendPush: false,
        );

        _showLocal(localNotification);
      }

      return;
    }

    final resolvedId = data.id ?? _nextLocalId();

    final notification = data.copyWith(
      id: resolvedId,
      createdAt: data.createdAt ?? DateTime.now(),
      persistInFirebase: true,
      sendPush: sendPush || data.sendPush,
    );

    await _repository.createUserNotifications(
      userIds: cleanUserIds,
      data: notification,
      sendPush: sendPush || notification.sendPush,
    );

    if (alsoShowLocalToast) {
      _showLocal(notification);
    }
  }

  void _showLocal(NotificationData notification) {
    final visible = List<NotificationData>.from(state.visible);
    final pending = List<NotificationData>.from(state.pending);

    if (visible.length >= state.maxVisible) {
      pending.add(notification);

      emit(
        state.copyWith(
          pending: pending,
          clearError: true,
        ),
      );

      return;
    }

    visible.insert(0, notification);

    emit(
      state.copyWith(
        visible: visible,
        clearError: true,
      ),
    );

    HapticFeedback.selectionClick();

    _startTimer(notification);
  }

  void _startTimer(NotificationData notification) {
    final id = notification.id;
    if (id == null || id.trim().isEmpty) return;

    _timers[id]?.cancel();

    _timers[id] = Timer(notification.duration, () {
      dismissById(id);
    });
  }

  void dismiss(NotificationData notification) {
    final id = notification.id;
    if (id == null || id.trim().isEmpty) return;

    dismissById(id);
  }

  void dismissById(String id) {
    final cleanId = id.trim();
    if (cleanId.isEmpty) return;

    final visible = List<NotificationData>.from(state.visible);
    final pending = List<NotificationData>.from(state.pending);

    final visibleIndex = visible.indexWhere((item) => item.id == cleanId);

    if (visibleIndex >= 0) {
      _timers[cleanId]?.cancel();
      _timers.remove(cleanId);

      visible.removeAt(visibleIndex);

      if (pending.isNotEmpty) {
        final next = pending.removeAt(0);
        visible.insert(0, next);
        _startTimer(next);
      }

      emit(
        state.copyWith(
          visible: visible,
          pending: pending,
          clearError: true,
        ),
      );

      return;
    }

    final pendingIndex = pending.indexWhere((item) => item.id == cleanId);

    if (pendingIndex >= 0) {
      pending.removeAt(pendingIndex);

      emit(
        state.copyWith(
          pending: pending,
          clearError: true,
        ),
      );
    }
  }

  void clearVisible() {
    for (final notification in state.visible) {
      final id = notification.id;
      if (id != null && id.trim().isNotEmpty) {
        _timers[id]?.cancel();
        _timers.remove(id);
      }
    }

    emit(
      state.copyWith(
        visible: const <NotificationData>[],
        pending: const <NotificationData>[],
        clearError: true,
      ),
    );
  }

  void watchBellNotifications({
    required String userId,
    int systemLimit = 30,
    int unreadUserLimit = 30,
  }) {
    watchSystemNotifications(limit: systemLimit);

    final cleanUserId = userId.trim();

    if (cleanUserId.isNotEmpty) {
      watchUnreadUserNotifications(
        userId: cleanUserId,
        limit: unreadUserLimit,
      );
    } else {
      _unreadUserSub?.cancel();

      emit(
        state.copyWith(
          unreadUserNotifications: const <NotificationData>[],
          clearError: true,
        ),
      );
    }
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

      final unread = state.unreadUserNotifications
          .where((item) => item.id != cleanNotificationId)
          .toList();

      emit(
        state.copyWith(
          history: history,
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

      emit(
        state.copyWith(
          history: history,
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

      final unread = state.unreadUserNotifications
          .where((item) => item.id != cleanNotificationId)
          .toList();

      emit(
        state.copyWith(
          history: history,
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
    for (final timer in _timers.values) {
      timer.cancel();
    }

    _timers.clear();

    _historySub?.cancel();
    _systemSub?.cancel();
    _unreadUserSub?.cancel();

    return super.close();
  }
}