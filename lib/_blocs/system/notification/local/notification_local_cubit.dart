import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../notification_data.dart';
import 'notification_local_state.dart';

class NotificationLocalCubit extends Cubit<NotificationLocalState> {
  NotificationLocalCubit({
    int maxVisible = 4,
  }) : super(NotificationLocalState(maxVisible: maxVisible));

  final Map<String, Timer> _timers = <String, Timer>{};

  int _localCounter = 0;

  String _nextLocalId() {
    _localCounter++;
    return 'local_notification_$_localCounter';
  }

  void show(NotificationData data) {
    final notification = data.copyWith(
      id: data.id ?? _nextLocalId(),
      createdAt: data.createdAt ?? DateTime.now(),
      persistInFirebase: false,
      sendPush: false,
    );

    _showLocal(notification);
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

  @override
  Future<void> close() {
    for (final timer in _timers.values) {
      timer.cancel();
    }

    _timers.clear();

    return super.close();
  }
}